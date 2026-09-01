#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

export CERT_NAME="sklein"
export CERT="$(incus remote get-client-certificate)"
export NETBIRD_SETUP_KEY="$(gopass show netbird/setup-keys/incus1.homelab.stephane-klein.info)"

minijinja-cli -a none --env seed/incus.yaml.j2 > seed/incus.yaml
minijinja-cli -a none --env seed/services.yaml.j2 > seed/services.yaml

echo "Generated seed/incus.yaml"
echo "Generated seed/services.yaml"
