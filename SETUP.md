# Self-Hosted Portfolio — Setup Manual

This guide walks you through hosting your static portfolio site on a Raspberry Pi 5,
from flashing the SD card to having a live public URL.

---

## Table of Contents

1. [What You Need](#1-what-you-need)
2. [Flash and Boot the Pi](#2-flash-and-boot-the-pi)
3. [First Boot & SSH](#3-first-boot--ssh)
4. [Clone the Repo & Run Setup](#4-clone-the-repo--run-setup)
5. [Public Access — Option A: Cloudflare Tunnel](#5-public-access--option-a-cloudflare-tunnel)
6. [Public Access — Option B: Tailscale](#6-public-access--option-b-tailscale)
7. [Comparison: Cloudflare Tunnel vs Tailscale](#7-comparison-cloudflare-tunnel-vs-tailscale)
8. [Updating Your Site](#8-updating-your-site)
9. [Customizing the Site](#9-customizing-the-site)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. What You Need

| Item | Notes |
|---|---|
| Raspberry Pi 5 (8GB) | Any of your four unused ones |
| MicroSD card | 16GB+ recommended (32GB is cheap and fine) |
| Power supply | Official RPi5 27W USB-C recommended |
| Ethernet cable | More reliable than Wi-Fi for a server |
| Another computer | To flash the SD card and SSH in |
| Cloudflare account | Free — only needed for Option A |
| Domain name | Only needed for Option A with a custom domain |
| Tailscale account | Free — only needed for Option B |

---

## 2. Flash and Boot the Pi

### Download Raspberry Pi Imager
Get it from: https://www.raspberrypi.com/software/

### Flash the SD card

1. Open Raspberry Pi Imager
2. **Choose Device** → Raspberry Pi 5
3. **Choose OS** → Raspberry Pi OS (other) → **Raspberry Pi OS Lite (64-bit)**
   - "Lite" = no desktop. Perfect for a server.
4. **Choose Storage** → your SD card
5. Click the **gear icon (⚙)** before writing to pre-configure:
   - Set hostname (e.g. `portfolio`)
   - Enable SSH → Use password authentication
   - Set username and password (remember these)
   - Configure Wi-Fi if you're not using ethernet
6. Click **Write** and wait

Insert the SD card into the Pi and power it on.

---

## 3. First Boot & SSH

Wait about 60 seconds for first boot, then find the Pi's IP address.

**Option 1 — Check your router's admin page** (easiest)
Look for a device named `portfolio` (or whatever hostname you set).

**Option 2 — Scan the network from your computer:**
```bash
# macOS / Linux
ping portfolio.local

# Or scan with nmap
nmap -sn 192.168.1.0/24 | grep -A1 Raspberry
```

**Connect via SSH:**
```bash
ssh pi@192.168.1.x   # use the IP you found, and the username you set
```

> **Tip:** Set up SSH key auth now so you don't need a password every time:
> ```bash
> # On your main machine
> ssh-copy-id pi@192.168.1.x
> ```

---

## 4. Clone the Repo & Run Setup

On the Pi over SSH:

```bash
# Install git if not present
sudo apt install -y git

# Clone your site repo
git clone https://github.com/starlordz12/starlordz12.git
cd starlordz12

# Run the setup script — installs Nginx and deploys the site
bash scripts/setup-rpi.sh
```

When it finishes, visit `http://192.168.1.x` in your browser.
Your site is live on your local network.

Now pick a method to make it public.

---

## 5. Public Access — Option A: Cloudflare Tunnel

**Best for:** Having a real custom domain (`yourdomain.com`) with free HTTPS,
no port forwarding, and no static IP required.

### Prerequisites
- A Cloudflare account: https://dash.cloudflare.com/sign-up
- A domain added to Cloudflare (set Cloudflare as your nameservers)
  - Cheap options: Namecheap, Porkbun, or buy directly through Cloudflare

### How it works
`cloudflared` runs on your Pi and maintains an outbound connection to
Cloudflare's edge. Traffic to your domain hits Cloudflare → travels through
the tunnel → reaches Nginx on your Pi. Your home IP is never exposed.

```
User → cloudflare.com → [encrypted tunnel] → cloudflared on Pi → Nginx → site
```

### Run the setup script

On the Pi, inside the repo directory:

```bash
bash scripts/setup-cloudflare-tunnel.sh
```

The script will:
1. Install `cloudflared`
2. Open a browser login to Cloudflare (or give you a link)
3. Create a named tunnel
4. Ask for your domain and write a config file
5. Automatically set the DNS CNAME in Cloudflare
6. Install `cloudflared` as a systemd service (auto-starts on reboot)

### After setup
Your site will be at `https://yourdomain.com` with a valid TLS certificate.
No certbot needed — Cloudflare handles TLS at the edge.

### Useful commands
```bash
sudo systemctl status cloudflared      # is the tunnel running?
sudo systemctl restart cloudflared     # restart it
cloudflared tunnel list                # show all tunnels
sudo journalctl -u cloudflared -f      # live logs
```

### Updating the tunnel config
The config lives at `/etc/cloudflared/config.yml`.
Edit it, then: `sudo systemctl restart cloudflared`

---

## 6. Public Access — Option B: Tailscale

**Best for:** Private access across all your devices, or a quick public URL
without needing a domain.

Tailscale creates a private mesh VPN between your devices (your Pi, laptop,
phone) so you can reach the Pi by name from anywhere. It's also useful for
managing your other three unused Pis later.

### Two modes

| Mode | Who can access | URL |
|---|---|---|
| **Private (default)** | Only your Tailscale devices | `http://<tailscale-ip>` |
| **Funnel (optional)** | Anyone on the internet | `https://<hostname>.<tailnet>.ts.net` |

### Prerequisites
- A Tailscale account: https://tailscale.com (free for personal use, up to 100 devices)
- For Funnel: enable it at https://login.tailscale.com/admin/dns → Funnel

### Run the setup script

On the Pi, inside the repo directory:

```bash
bash scripts/setup-tailscale.sh
```

The script will:
1. Install Tailscale
2. Run `tailscale up` — give you a URL to authenticate the device in your browser
3. Show your Tailscale IP and MagicDNS hostname
4. Ask if you want to enable Funnel (public access)

### Private access (no Funnel)

Install Tailscale on your other devices (laptop, phone) from https://tailscale.com/download.
Once connected, you can reach the Pi at its MagicDNS name from anywhere:
```
http://portfolio.your-tailnet.ts.net
```

This is great for checking on your homelab remotely without any public exposure.

### Funnel (public access)

Enable Funnel in your Tailscale admin console first, then on the Pi:

```bash
sudo tailscale funnel --bg 80
```

Your site is now publicly accessible at:
```
https://portfolio.your-tailnet.ts.net
```

Tailscale provides valid HTTPS automatically. No domain, no certbot, no port forwarding.

```bash
# Check Funnel status
sudo tailscale funnel status

# Stop Funnel (back to private only)
sudo tailscale funnel --bg off
```

### Useful commands
```bash
tailscale status                    # show all connected devices
tailscale ip                        # show this Pi's IPs
sudo tailscale funnel status        # check Funnel
sudo journalctl -u tailscaled -f    # live logs
```

---

## 7. Comparison: Cloudflare Tunnel vs Tailscale

| | Cloudflare Tunnel | Tailscale |
|---|---|---|
| **Public URL** | Yes, custom domain | Yes (Funnel), but it's `.ts.net` |
| **Custom domain** | Yes (required or optional) | No (unless you add Cloudflare on top) |
| **Private access** | No (it's all public) | Yes — great for homelab |
| **Home IP exposed** | No | No |
| **Port forwarding** | Not needed | Not needed |
| **HTTPS** | Yes (Cloudflare edge) | Yes (Funnel) |
| **Cost** | Free (Cloudflare free tier) | Free (personal, up to 100 devices) |
| **Best for** | A real public website | Private homelab + optional public |
| **Manage multiple Pis** | Harder | Easy — just add each Pi to your tailnet |

**Recommendation:**
- If you want a proper public portfolio site with a real domain → **Cloudflare Tunnel**
- If you mostly want private access + a bonus public URL → **Tailscale Funnel**
- You can run **both** at the same time if you want.

---

## 8. Updating Your Site

### From your main machine (using the deploy script)

```bash
# Make your changes to index.html, css/, js/ locally, then:
bash scripts/deploy.sh 192.168.1.x    # replace with your Pi's IP or hostname
```

This uses `rsync` to push only changed files and reloads Nginx.

### Directly on the Pi

```bash
cd ~/starlordz12
git pull origin main
sudo cp -r index.html css js /var/www/portfolio/
sudo systemctl reload nginx
```

---

## 9. Customizing the Site

### Change your name / headline
Edit `index.html` — look for the `<h1>` tag in the `#hero` section.

### Add a project card
Copy one of the `<article class="project-card">` blocks in `index.html` and edit:
- `card-icon` — any emoji works
- `card-lang` — language or tech used
- `<h3>` — project name
- `<p>` — description
- `.tag` spans — relevant tags
- Add an `<a href="...">` link if you want to link to GitHub

### Add a contact link
In the `#contact` section, copy the GitHub button and change the `href` and text:
```html
<a href="https://reddit.com/u/yourname" class="contact-btn" target="_blank" rel="noopener">Reddit</a>
```

### Change the color scheme
All colors are CSS variables at the top of `css/style.css`:
```css
:root {
  --bg:     #0d1117;   /* page background */
  --accent: #58a6ff;   /* blue highlights */
  --accent2: #3fb950;  /* green (logo, terminal prompts) */
  ...
}
```

---

## 10. Troubleshooting

### Site not loading locally
```bash
# Is Nginx running?
sudo systemctl status nginx

# Any config errors?
sudo nginx -t

# Check the logs
sudo tail -f /var/log/nginx/portfolio_error.log
```

### Cloudflare Tunnel not connecting
```bash
sudo systemctl status cloudflared
sudo journalctl -u cloudflared -f

# Re-authenticate if credentials expired
cloudflared login
```

### Tailscale device not showing up
```bash
tailscale status
# If offline:
sudo systemctl restart tailscaled
sudo tailscale up
```

### Can't SSH into the Pi
- Make sure you're on the same network (or connected via Tailscale)
- Try the IP address instead of the hostname
- Check that SSH is enabled: on the Pi, run `sudo systemctl status ssh`

### Pi loses its IP after reboot
Set a DHCP reservation in your router for the Pi's MAC address,
or configure a static IP on the Pi:
```bash
# Find MAC address
ip link show eth0 | grep ether
```
Then set a reservation in your router's admin page using that MAC.
