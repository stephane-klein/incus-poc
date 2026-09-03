#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../"

mkdir -p images/

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

coreos-installer download \
    -s stable \
    -a x86_64 \
    -p metal \
    -f iso \
    -d \
    -C "$tmpdir"

mv "$tmpdir"/* images/fedora-coreos-live-iso.x86_64.iso

export NETBIRD_SETUP_KEY="$(gopass show netbird/setup-keys/incus-auto-group)"
export PASSWORD_HASH="$(gopass show -o homelab/incus-server1.homelab.stephane-klein.info/stephane/password | mkpasswd --method=yescrypt -s)"
export WIFI_PSK="$(gopass show -o homelab/wifi/stephane-klein.info_5G/password)"

INCUS_CLIENT_CERT_PATH="homelab/incus-server1.homelab.stephane-klein.info/incus/client.crt"
if ! gopass show "${INCUS_CLIENT_CERT_PATH}" >/dev/null 2>&1; then
    echo "ERROR: certificat client Incus introuvable dans gopass (${INCUS_CLIENT_CERT_PATH})" >&2
    echo "  gopass insert -m ${INCUS_CLIENT_CERT_PATH} < client.crt" >&2
    exit 1
fi
# Pre-indente chaque ligne du PEM (14 espaces) pour matcher l'indentation du
# bloc `certificate: |` du preseed dans coreos-custom-iso-config.bu.tmpl
export INCUS_CLIENT_CERT="$(gopass show "${INCUS_CLIENT_CERT_PATH}" | sed '1!s/^/              /')"

minijinja-cli -a none --env coreos-custom-iso-config.bu.tmpl > coreos-custom-iso-config.bu
minijinja-cli -a none --env wifi-home.nmconnection.j2 > wifi-home.nmconnection
butane coreos-custom-iso-config.bu > coreos-custom-iso-config.ign

rm -f images/fedora-coreos-for-tuxedo.iso

coreos-installer iso customize \
    --pre-install pre-install/run-wipefs.sh \
    --dest-ignition coreos-custom-iso-config.ign \
    --network-keyfile wifi-home.nmconnection \
    --dest-console ttyS0,115200n8 \
    --dest-console tty0 \
    --dest-device /dev/nvme0n1 \
    --live-karg-append "vconsole.keymap=fr-bepo locale.LANG=fr_FR.UTF-8" \
    -o images/fedora-coreos-for-tuxedo.iso \
    images/fedora-coreos-live-iso.x86_64.iso

cat << 'EOF'
CoreOS custom iso builded in: images/fedora-coreos-for-tuxedo.iso

Execute:

$ mise run write-to-usb

to write ISO image on USB key
EOF