#!/usr/bin/env bash
# Set up Tailscale on the RPi.
# Run this AFTER setup-rpi.sh.
#
# Tailscale gives you two things:
#   1. Private access  — reach your Pi from any of your devices over a VPN mesh.
#   2. Funnel (public) — optionally expose your site to the entire internet via
#                        your Tailscale hostname (no domain needed, free HTTPS).
#
# Usage: bash scripts/setup-tailscale.sh

set -euo pipefail

echo "==> Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo ""
echo "==> Starting Tailscale and authenticating..."
echo "    You'll get a URL — open it on any browser to approve this device."
echo ""
sudo tailscale up

TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "unknown")
TAILSCALE_HOST=$(tailscale status --json 2>/dev/null | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d['Self']['DNSName'].rstrip('.'))" \
  2>/dev/null || echo "unknown")

echo ""
echo "Tailscale is up!"
echo "  Tailscale IP:   $TAILSCALE_IP"
echo "  MagicDNS name:  $TAILSCALE_HOST"
echo ""

# Ask about Funnel
echo "=================================================="
echo " Tailscale Funnel (optional)"
echo "=================================================="
echo " Funnel makes your site publicly accessible at:"
echo "   https://$TAILSCALE_HOST"
echo " No domain needed. Free HTTPS. No port forwarding."
echo " Requires: Tailscale account with Funnel enabled"
echo "   (Enable at: https://login.tailscale.com/admin/dns -> Funnel)"
echo "=================================================="
echo ""
read -rp "Enable Tailscale Funnel now? (y/N): " ENABLE_FUNNEL

if [[ "${ENABLE_FUNNEL,,}" == "y" ]]; then
  echo ""
  echo "==> Enabling Funnel on port 80..."
  sudo tailscale funnel --bg 80
  echo ""
  echo "Funnel is active!"
  echo "  Public URL: https://$TAILSCALE_HOST"
  echo "  (It may take a minute to propagate)"
  echo ""
  echo "To stop Funnel later:  sudo tailscale funnel --bg off"
else
  echo ""
  echo "Skipped Funnel. Your site is accessible privately at:"
  echo "  http://$TAILSCALE_IP   (from your Tailscale devices)"
  echo ""
  echo "To enable Funnel later:  sudo tailscale funnel --bg 80"
fi

echo ""
echo "Useful commands:"
echo "  tailscale status                    # show all connected devices"
echo "  tailscale ip                        # show this device's IPs"
echo "  sudo tailscale funnel status        # check Funnel status"
echo "  sudo journalctl -u tailscaled -f    # live logs"
