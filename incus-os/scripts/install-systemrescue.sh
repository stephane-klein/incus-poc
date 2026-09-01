#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../"

SYSRESCUE_VERSION="13.02"
SYSRESCUE_ISO="systemrescue-${SYSRESCUE_VERSION}-amd64.iso"
SYSRESCUE_ISO_URL="https://fastly-cdn.system-rescue.org/releases/${SYSRESCUE_VERSION}/${SYSRESCUE_ISO}"
SYSRESCUE_ISO_SHA256_URL="https://www.system-rescue.org/releases/${SYSRESCUE_VERSION}/${SYSRESCUE_ISO}.sha256"

USBWRITER_VERSION="1.1.1"
USBWRITER_APPIMAGE="sysrescueusbwriter-x86_64.AppImage"
USBWRITER_URL="https://fastly-cdn.system-rescue.org/download/usbwriter/${USBWRITER_VERSION}/${USBWRITER_APPIMAGE}"
USBWRITER_SHA256_URL="${USBWRITER_URL}.sha256"

download() {
    local url="$1"
    local dest="$2"

    if [[ ! -f "$dest" ]]; then
        echo "Downloading $dest..."
        curl -fL --retry 3 -o "$dest" "$url"
    else
        echo "$dest already present, skipping download."
    fi
}

verify_sha256() {
    local file="$1"
    local sumfile="$2"

    if [[ ! -f "$sumfile" ]]; then
        echo "Checksum file missing: $sumfile"
        exit 1
    fi

    echo "Verifying checksum of $file..."
    (cd "$(dirname "$file")" && sha256sum -c "$(basename "$sumfile")")
}

# Download and verify SystemRescue ISO.
download "$SYSRESCUE_ISO_URL" "$SYSRESCUE_ISO"
download "$SYSRESCUE_ISO_SHA256_URL" "$SYSRESCUE_ISO.sha256"
verify_sha256 "$SYSRESCUE_ISO" "$SYSRESCUE_ISO.sha256"

# Download and verify SystemRescue USB writer AppImage.
download "$USBWRITER_URL" "$USBWRITER_APPIMAGE"
download "$USBWRITER_SHA256_URL" "$USBWRITER_APPIMAGE.sha256"
verify_sha256 "$USBWRITER_APPIMAGE" "$USBWRITER_APPIMAGE.sha256"
chmod 755 "$USBWRITER_APPIMAGE"

# Detect USB drives.
mapfile -t usb_drives < <(lsblk -d -n -o NAME,TRAN | grep usb | awk '{print "/dev/"$1}')

if [[ ${#usb_drives[@]} -eq 0 ]]; then
    echo "No USB drives found. Please insert one and try again."
    exit 1
fi

echo "Available USB drives:"
i=1
for drive in "${usb_drives[@]}"; do
    info=$(lsblk -n -o SIZE,VENDOR,MODEL "$drive" 2>/dev/null | head -1)
    echo "  $i) $drive ($info)"
    ((i++))
done

echo ""
read -rp "Select drive [1-${#usb_drives[@]}]: " selection

if [[ ! $selection =~ ^[0-9]+$ ]] || [[ $selection -lt 1 ]] || [[ $selection -gt ${#usb_drives[@]} ]]; then
    echo "Invalid selection"
    exit 1
fi

DEVICE="${usb_drives[$((selection-1))]}"

echo ""
read -rp "WARNING: this will erase all data on $DEVICE. Continue? [y/N]: " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Write SystemRescue to the USB stick.
echo "Writing SystemRescue to $DEVICE..."
./"$USBWRITER_APPIMAGE" -c -t "$DEVICE" "$SYSRESCUE_ISO"

# Configure bépo keyboard layout via a persistent YAML file on the boot device.
# The USB writer creates a writable filesystem, so we can drop config files in sysrescue.d/.
mount_point=$(mktemp -d)
trap 'sudo umount "$mount_point" 2>/dev/null || sudo umount -l "$mount_point" 2>/dev/null || true; rmdir "$mount_point" 2>/dev/null || true' EXIT

partition=""
for candidate in "${DEVICE}"*; do
    [[ "$candidate" == "$DEVICE" ]] && continue
    fstype=$(lsblk -n -o FSTYPE "$candidate" 2>/dev/null)
    if [[ "$fstype" == vfat || "$fstype" == fat32 ]]; then
        partition="$candidate"
        break
    fi
done

if [[ -z "$partition" ]]; then
    echo "No writable FAT partition found on $DEVICE, skipping bépo configuration."
    exit 0
fi

echo "Mounting $partition to configure bépo..."
sudo mount -o uid="$(id -u)",gid="$(id -g)",sync "$partition" "$mount_point"

mkdir -p "$mount_point/sysrescue.d"
cat > "$mount_point/sysrescue.d/500-bepo.yaml" <<'EOF'
global:
  setkmap: "fr-bepo"
EOF

sync
if ! sudo umount "$mount_point" 2>/dev/null; then
    echo "Target busy, retrying..."
    sleep 2
    if ! sudo umount "$mount_point" 2>/dev/null; then
        echo "Unmount failed, listing processes holding $partition:"
        sudo lsof +f -- "$partition" 2>/dev/null || sudo fuser -vm "$partition" 2>&1 || true
        sudo umount -l "$mount_point" 2>/dev/null || true
    fi
fi
trap - EXIT
rmdir "$mount_point" 2>/dev/null || true

echo ""
echo "Done! SystemRescue USB drive is ready with bépo keyboard layout."