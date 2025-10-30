#!/usr/bin/env bash
set -eux

echo "=============================="
echo "Playwright + Libs (Render Safe)"
echo "=============================="

mkdir -p ~/.local/bin ~/.local/lib ~/.cache/ms-playwright ~/local-libs
cd ~/local-libs

echo "Installing Python deps..."
pip install --upgrade pip setuptools wheel
pip install python-dotenv cryptography httpx "python-telegram-bot<23,>=22.0" instagrapi playwright playwright-stealth==1.0.6

echo "Installing Playwright Chromium..."
python3 -m playwright install chromium

echo "Downloading Debian 12 shared libs (auto-resolved URLs)..."

download_deb() {
  pkg=$1
  echo "→ $pkg"
  url=$(curl -s "https://packages.debian.org/bookworm/amd64/$pkg/download" \
    | grep -Eo 'https?://[^"]+\.deb' | head -n1)
  if [ -z "$url" ]; then
    echo "❌ Failed: $pkg"
  else
    wget -q "$url" -O "$pkg.deb"
  fi
}

# list of essential libs for Playwright Chromium
for pkg in \
  libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 \
  libxcomposite1 libxdamage1 libxrandr2 libxkbcommon0 libpango-1.0-0 \
  libgbm1 libasound2 libx11-xcb1 libxcb-dri3-0 libxshmfence1 \
  libcups2 libdrm2 libxfixes3 libxrender1 libxext6 libxcursor1 \
  libxi6 libxrandr2 libxss1 libxtst6; do
  download_deb "$pkg" || true
done

echo "Extracting .deb files..."
for f in *.deb; do
  dpkg-deb -x "$f" .
done

echo "Setting LD_LIBRARY_PATH..."
export LD_LIBRARY_PATH=$HOME/local-libs/usr/lib/x86_64-linux-gnu:$HOME/local-libs/usr/lib:$LD_LIBRARY_PATH
export PATH=$HOME/.local/bin:$PATH
echo 'export LD_LIBRARY_PATH=$HOME/local-libs/usr/lib/x86_64-linux-gnu:$HOME/local-libs/usr/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc

echo "Verifying Playwright..."
python3 -m playwright --version
python3 - <<'EOF'
from playwright.sync_api import sync_playwright
p = sync_playwright().start()
b = p.chromium.launch(headless=True)
print("✅ Playwright OK with downloaded libs")
b.close()
p.stop()
EOF

echo "Launching igbot5.py..."
cd $HOME
