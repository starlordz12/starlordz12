#!/usr/bin/env bash
# Set up a Cloudflare Tunnel to expose your site publicly.
# Run this AFTER setup-rpi.sh. Nginx must already be running on port 80.
#
# Requirements:
#   - A Cloudflare account (free)
#   - A domain added to Cloudflare (even a cheap one works)
#
# Usage: bash scripts/setup-cloudflare-tunnel.sh

set -euo pipefail

TUNNEL_NAME="portfolio"
TUNNEL_CONF_DIR="/etc/cloudflared"
SERVICE_NAME="cloudflared"

echo "==> Installing cloudflared..."
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
  | sudo tee /usr/share/keyrings/cloudflare-main.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] \
  https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/cloudflared.list > /dev/null

sudo apt update && sudo apt install -y cloudflared

echo ""
echo "==> Logging in to Cloudflare..."
echo "    A browser window will open (or you'll get a link to open on another device)."
echo "    Select the domain you want to use for this tunnel."
echo ""
cloudflared login

echo ""
echo "==> Creating tunnel '$TUNNEL_NAME'..."
cloudflared tunnel create "$TUNNEL_NAME"

# Get the tunnel ID (UUID) that was just created
TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')

if [[ -z "$TUNNEL_ID" ]]; then
  echo "ERROR: Could not find tunnel ID. Did tunnel creation succeed?"
  exit 1
fi

echo "    Tunnel ID: $TUNNEL_ID"

echo ""
echo "==> Writing tunnel config..."
sudo mkdir -p "$TUNNEL_CONF_DIR"

# Copy credentials file to /etc/cloudflared
sudo cp ~/.cloudflared/"$TUNNEL_ID".json "$TUNNEL_CONF_DIR/"

read -rp "Enter your full domain (e.g. yourdomain.com or portfolio.yourdomain.com): " DOMAIN

sudo tee "$TUNNEL_CONF_DIR/config.yml" > /dev/null <<EOF
tunnel: $TUNNEL_ID
credentials-file: $TUNNEL_CONF_DIR/$TUNNEL_ID.json

ingress:
  - hostname: $DOMAIN
    service: http://localhost:80
  - service: http_status:404
EOF

echo ""
echo "==> Routing DNS (this sets a CNAME in Cloudflare automatically)..."
cloudflared tunnel route dns "$TUNNEL_NAME" "$DOMAIN"

echo ""
echo "==> Installing cloudflared as a systemd service..."
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared

echo ""
echo "==> Status:"
sudo systemctl status cloudflared --no-pager

echo ""
echo "Done!"
echo "  Your site should be live at: https://$DOMAIN"
echo "  (DNS may take a minute or two to propagate)"
echo ""
echo "Useful commands:"
echo "  sudo systemctl status cloudflared   # check tunnel status"
echo "  cloudflared tunnel list             # list tunnels"
echo "  sudo journalctl -u cloudflared -f   # live logs"
