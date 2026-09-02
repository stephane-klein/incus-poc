#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

export NETBIRD_SETUP_KEY="$(gopass show -o netbird/setup-keys/incus-auto-group)"

minijinja-cli -a none --env test5-custom-fedora-image.yaml.j2 > test5-custom-fedora-image.yaml

echo "Generated test5-custom-fedora-image.yaml"
