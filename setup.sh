#!/usr/bin/env bash
set -eux

echo "=============================="
echo "Playwright + Full Libs (Render Safe)"
echo "=============================="

mkdir -p ~/.local/bin ~/.local/lib ~/.cache/ms-playwright ~/local-libs
cd ~/local-libs

# ==============================
# Install Python dependencies
# ==============================
pip install --upgrade pip setuptools wheel
pip install python-dotenv cryptography httpx "python-telegram-bot<23,>=22.0" instagrapi playwright playwright-stealth==1.0.6

# ==============================
# Install Playwright Chromium
# ==============================
python3 -m playwright install chromium

# ==============================
# Fetch required native libs safely (no apt)
# ==============================
echo "Downloading Debian packages safely..."

download_pkg() {
  pkg="$1"
  echo "→ Fetching $pkg"
  # This endpoint redirects to the latest .deb automatically
  url="https://deb.debian.org/debian/pool/main/${pkg:0:1}/$pkg"
  # Try all common mirrors for bookworm
  if ! wget -q --spider "$url"; then
    echo "⚠️  Mirror not found, auto-searching..."
    # Use Debian's mirror redirection service
    real_url=$(curl -sL -o /dev/null -w '%{url_effective}' "https://deb.debian.org/debian/pool/main/${pkg:0:1}/")
    wget -q "$real_url" -O "$pkg.deb" || echo "⚠️  Failed $pkg"
  else
    wget -q "$url" -O "$pkg.deb"
  fi
}

# Clean environment before extracting
rm -rf *.deb

# Essential runtime libs for Playwright Chromium
pkgs=(
  libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0
  libxcomposite1 libxdamage1 libxrandr2 libxkbcommon0 libpango-1.0-0
  libgbm1 libasound2 libx11-xcb1 libxcb-dri3-0 libxshmfence1
  libcups2 libdrm2 libxfixes3 libxrender1 libxext6 libxcursor1
  libxi6 libxrandr2 libxss1 libxtst6
)

for pkg in "${pkgs[@]}"; do
  # Instead of guessing path, use Debian’s API that follows mirrors
  curl -fsSL "http://ftp.debian.org/debian/pool/main/${pkg:0:1}/" | \
    grep -Eo "${pkg}_[0-9A-Za-z.+:~_-]+_amd64\.deb" | \
    head -n1 | while read -r file; do
      wget -q "http://ftp.debian.org/debian/pool/main/${pkg:0:1}/$file" -O "$pkg.deb" || true
    done
done

echo "Extracting downloaded packages..."
for f in *.deb; do
  if [ -s "$f" ]; then
    dpkg-deb -x "$f" .
  else
    echo "⚠️  Skipping empty $f"
  fi
done

# ==============================
# Add local lib paths
# ==============================
export LD_LIBRARY_PATH=$HOME/local-libs/usr/lib/x86_64-linux-gnu:$HOME/local-libs/usr/lib:$LD_LIBRARY_PATH
export PATH=$HOME/.local/bin:$PATH
echo 'export LD_LIBRARY_PATH=$HOME/local-libs/usr/lib/x86_64-linux-gnu:$HOME/local-libs/usr/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc

# ==============================
# Verify setup
# ==============================
python3 -m playwright --version
python3 - <<'EOF'
from playwright.sync_api import sync_playwright
p = sync_playwright().start()
b = p.chromium.launch(headless=True)
print("✅ Playwright ready with local libs")
b.close()
p.stop()
EOF

# ==============================
# Run bot
# ==============================
cd $HOME
