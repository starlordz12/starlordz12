#!/usr/bin/env bash
# Run this once on a fresh Raspberry Pi to install Nginx and set up the site.
# Usage: bash setup-rpi.sh

set -euo pipefail

SITE_DIR="/var/www/portfolio"
NGINX_CONF="/etc/nginx/sites-available/portfolio"

echo "==> Updating packages..."
sudo apt update && sudo apt upgrade -y

echo "==> Installing Nginx..."
sudo apt install -y nginx

echo "==> Creating site directory..."
sudo mkdir -p "$SITE_DIR"
sudo chown -R "$USER":"$USER" "$SITE_DIR"

echo "==> Copying site files..."
cp -r index.html css js "$SITE_DIR"/

echo "==> Installing Nginx config..."
sudo cp nginx/portfolio.conf "$NGINX_CONF"
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/portfolio
sudo rm -f /etc/nginx/sites-enabled/default

echo "==> Testing Nginx config..."
sudo nginx -t

echo "==> Starting Nginx..."
sudo systemctl enable nginx
sudo systemctl restart nginx

echo ""
echo "Done! Site is live at http://$(hostname -I | awk '{print $1}')"
echo ""
echo "Next steps:"
echo "  1. Edit nginx/portfolio.conf and set your domain in 'server_name'"
echo "  2. For HTTPS with a real domain, run:  sudo apt install certbot python3-certbot-nginx"
echo "     then:  sudo certbot --nginx -d yourdomain.com"
echo "  3. For HTTPS without a domain (Cloudflare Tunnel), see:"
echo "     https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/"
