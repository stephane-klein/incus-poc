#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../"

IMAGE_PATH="IncusOS-custom.img"

if [[ ! -f "$IMAGE_PATH" ]]; then
    echo "Image not found: $IMAGE_PATH"
    echo "Run 'mise run //incus-os/:build-incusos-image' first."
    exit 1
fi

echo "=== IncusOS USB Writer ==="
echo "Image: $IMAGE_PATH"
echo ""

# Detect USB drives.
mapfile -t usb_drives < <(lsblk -d -n -o NAME,TRAN | grep usb | awk '{print "/dev/"$1}')

if [[ ${#usb_drives[@]} -eq 0 ]]; then
    echo "No USB drives found. Please insert one and try again."
    exit 1
fi

# Display options.
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

# Unmount any mounted partitions.
echo "Unmounting partitions..."
sudo umount "${DEVICE}"?* 2>/dev/null || true

# Write image.
echo "Writing image to $DEVICE..."
sudo dd if="$IMAGE_PATH" of="$DEVICE" bs=64M oflag=direct status=progress conv=fsync

echo ""
echo "Done! USB drive is ready."