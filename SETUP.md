# Portfolio Site — Setup Manual

This guide gets your static portfolio live on Cloudflare Pages in under
10 minutes, for free, with automatic HTTPS and a global CDN.

---

## Table of Contents

1. [What You Need](#1-what-you-need)
2. [Deploy to Cloudflare Pages](#2-deploy-to-cloudflare-pages)
3. [Add a Custom Domain (optional)](#3-add-a-custom-domain-optional)
4. [Updating Your Site](#4-updating-your-site)
5. [Customizing the Site](#5-customizing-the-site)
6. [Appendix: Self-Hosted on Raspberry Pi](#6-appendix-self-hosted-on-raspberry-pi)

---

## 1. What You Need

| Item | Notes |
|---|---|
| GitHub account | Your repo is already at github.com/starlordz12/starlordz12 |
| Cloudflare account | Free at cloudflare.com — no credit card needed |
| Custom domain | Optional — you get a free `*.pages.dev` URL without one |

That's it.

---

## 2. Deploy to Cloudflare Pages

### Step 1 — Create a Cloudflare account
Go to https://dash.cloudflare.com/sign-up and create a free account.

### Step 2 — Create a Pages project

1. In the Cloudflare dashboard, click **Workers & Pages** in the left sidebar
2. Click **Create** → **Pages** → **Connect to Git**
3. Click **Connect GitHub** and authorize Cloudflare
4. Select the `starlordz12/starlordz12` repository
5. Click **Begin setup**

### Step 3 — Configure the build

On the build settings page:

| Setting | Value |
|---|---|
| Project name | `starlordz12` (or whatever you want) |
| Production branch | `main` |
| Build command | *(leave blank)* |
| Build output directory | *(leave blank)* |

Plain HTML/CSS/JS needs no build step — leave both fields empty.

### Step 4 — Deploy

Click **Save and Deploy**. Cloudflare will pull your repo and deploy it.

In about 60 seconds your site is live at:
```
https://starlordz12.pages.dev
```

Every time you push to `main`, Cloudflare automatically redeploys. That's the
whole workflow.

---

## 3. Add a Custom Domain (optional)

If you want `yourdomain.com` instead of `starlordz12.pages.dev`:

### Buy a domain
Cheapest options (no markup, at-cost):
- **Cloudflare Registrar** — buy directly inside Cloudflare, already wired up
- **Porkbun** — very cheap, clean UI
- **Namecheap** — popular alternative

`.com` runs ~$10-12/yr. `.dev` is slightly more.

### Add it to your Pages project

1. Go to your Pages project → **Custom domains** tab
2. Click **Set up a custom domain**
3. Enter your domain (e.g. `starlordz12.com`)
4. Cloudflare will walk you through pointing your DNS at Pages

If you bought through Cloudflare Registrar, DNS is already managed by
Cloudflare and it configures automatically. If you bought elsewhere, you'll
need to update your nameservers to Cloudflare's (shown in the dashboard).

HTTPS is provisioned automatically — no certbot, no configuration needed.

---

## 4. Updating Your Site

### The workflow

```bash
# Edit your files locally (index.html, css/style.css, etc.)
# Then commit and push:
git add .
git commit -m "update site"
git push origin main
```

Cloudflare detects the push and redeploys within ~30 seconds.
You can watch it deploy live in the **Deployments** tab of your Pages project.

### Preview deployments

Every branch you push (not just `main`) gets its own preview URL:
```
https://<branch-name>.starlordz12.pages.dev
```

Useful for testing changes before merging to main.

---

## 5. Customizing the Site

### Change your name / headline
Edit `index.html` — find the `<h1>` tag in the `#hero` section:
```html
<h1>Hey, I'm <span class="accent">starlordz12</span></h1>
```

### Add a project card
Copy one of the `<article class="project-card">` blocks and fill in:
- `card-icon` — any emoji
- `card-lang` — language or tech
- `<h3>` — project name
- `<p>` — short description
- `.tag` spans — relevant tags

Optionally wrap the `<h3>` in a link to GitHub:
```html
<h3><a href="https://github.com/starlordz12/yourrepo">Project Name</a></h3>
```

### Add contact links
In the `#contact` section, copy the GitHub button:
```html
<a href="https://reddit.com/u/yourname" class="contact-btn" target="_blank" rel="noopener">Reddit</a>
```

### Change the color scheme
All colors are CSS variables at the top of `css/style.css`:
```css
:root {
  --bg:      #0d1117;   /* page background */
  --accent:  #58a6ff;   /* blue highlights  */
  --accent2: #3fb950;   /* green (logo, prompts) */
}
```

---

## 6. Appendix: Self-Hosted on Raspberry Pi

If you later want to move to self-hosting on one of your RPi5s instead of
Cloudflare Pages, the scripts in `scripts/` handle the full setup.

### Overview

```
scripts/setup-rpi.sh                 # installs Nginx, deploys site files
scripts/setup-cloudflare-tunnel.sh   # exposes site publicly via Cloudflare Tunnel
scripts/setup-tailscale.sh           # private mesh VPN + optional public Funnel
scripts/deploy.sh <rpi-ip>           # push updates over rsync/SSH
nginx/portfolio.conf                 # Nginx site config
```

### Quick start

```bash
# On a freshly flashed Pi (Raspberry Pi OS Lite 64-bit):
git clone https://github.com/starlordz12/starlordz12.git
cd starlordz12
bash scripts/setup-rpi.sh

# Then pick a public access method:
bash scripts/setup-cloudflare-tunnel.sh   # needs a domain
bash scripts/setup-tailscale.sh           # no domain needed (Funnel)
```

See the git history for the original full self-hosting manual.
