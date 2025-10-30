#!/usr/bin/env bash
set -e

echo "=== Playwright Setup (Render Safe, Debian/Ubuntu) ==="

# Ensure system tools
apt-get update -y
apt-get install -y wget unzip xz-utils dpkg curl

# 1️⃣ Create temp directory
mkdir -p /tmp/debs && cd /tmp/debs

# 2️⃣ Safe Debian mirror
BASE="http://deb.debian.org/debian/pool/main"

# 3️⃣ Required Playwright native deps
pkgs=(
  libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0
  libxcomposite1 libxdamage1 libxrandr2 libxkbcommon0 libpango-1.0-0
  libgbm1 libasound2 libx11-xcb1 libxcb-dri3-0 libxshmfence1 libcups2
  libdrm2 libxfixes3 libxrender1 libxext6 libxcursor1 libxi6 libxss1 libxtst6
)

download_pkg() {
  pkg=$1
  echo "→ Downloading $pkg ..."
  link=$(curl -fsSL "https://packages.debian.org/bookworm/amd64/${pkg}/download" | grep -Eo 'https?://[^"]+\.deb' | head -n1 || true)
  if [[ -n "$link" ]]; then
    wget -q "$link" -O "${pkg}.deb" || echo "⚠️  Failed: $pkg"
  else
    echo "⚠️  URL not found for $pkg"
  fi
}

for p in "${pkgs[@]}"; do
  download_pkg "$p"
done

echo "Extracting downloaded packages..."
for f in *.deb; do
  [[ -s "$f" ]] && dpkg-deb -x "$f" . || echo "⚠️  Skipping empty $f"
done

# 4️⃣ Make sure LD_LIBRARY_PATH is always defined
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-/tmp/debs/usr/lib/x86_64-linux-gnu}"

# 5️⃣ Install Python libs (no sudo)
python3 -m pip install --upgrade pip
python3 -m pip install python-dotenv cryptography httpx
python3 -m pip install "python-telegram-bot<23,>=22.0"
python3 -m pip install instagrapi
python3 -m pip install playwright playwright-stealth==1.0.6

# 6️⃣ Playwright deps (no root, skip sudo)
npx playwright install chromium --with-deps || true

echo "✅ Playwright environment ready!"