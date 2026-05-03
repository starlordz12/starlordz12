#!/usr/bin/env bash
# Deploy updated site files to the RPi over SSH.
# Usage: bash scripts/deploy.sh <rpi-ip-or-hostname>
# Example: bash scripts/deploy.sh 192.168.1.42

set -euo pipefail

RPI="${1:-}"
SITE_DIR="/var/www/portfolio"

if [[ -z "$RPI" ]]; then
  echo "Usage: $0 <rpi-ip-or-hostname>"
  exit 1
fi

echo "==> Syncing site files to $RPI:$SITE_DIR ..."
rsync -avz --delete \
  --exclude='.git' \
  --exclude='scripts/' \
  --exclude='nginx/' \
  index.html css/ js/ \
  "$RPI:$SITE_DIR/"

echo "==> Reloading Nginx..."
ssh "$RPI" "sudo systemctl reload nginx"

echo "Done! Site updated at http://$RPI"
