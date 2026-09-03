#!/usr/bin/env bash
set -euo pipefail

# Deactivate any leftover LVM volume groups from a previous install
if command -v vgchange >/dev/null 2>&1; then
    vgchange -an 2>/dev/null || true
fi

wipefs -a /dev/nvme0n1

# Wipe partition contents (LVM/filesystem signatures survive a raw disk wipe)
for p in /dev/nvme0n1?*; do
    wipefs -a "$p" 2>/dev/null || true
done

sgdisk --zap-all /dev/nvme0n1