#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

bash scripts/render-incus-seed.sh

tar -cf seed/seed.tar -C seed applications.yaml incus.yaml install.yaml network.yaml services.yaml

"$(mise which flasher-tool)" -f img -s seed/seed.tar

for img in IncusOS_*.img; do
    [ "$img" = "IncusOS-custom.img" ] && continue
    mv "$img" "IncusOS-custom.img"
    echo "Generated IncusOS-custom.img"
    break
done