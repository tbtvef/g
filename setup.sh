#!/usr/bin/env bash
set -e

echo "=============================="
echo "🚀 Render Setup: Playwright + All Python Deps (No sudo)"
echo "=============================="

# 1️⃣ Prepare folders
mkdir -p ~/.local/bin ~/.local/lib ~/.cache/ms-playwright ~/local-libs
cd ~/local-libs

# 2️⃣ Install all required Python packages (user-local, no root)
echo "📦 Installing Python dependencies..."
python3 -m pip install --user --upgrade pip setuptools wheel
python3 -m pip install --user python-dotenv cryptography httpx
python3 -m pip install --user "python-telegram-bot<23,>=22.0"
python3 -m pip install --user instagrapi
python3 -m pip install --user playwright
python3 -m pip install --user playwright-stealth==1.0.6

# 3️⃣ Install Chromium browser for Playwright
echo "🌐 Installing Playwright Chromium..."
python3 -m playwright install chromium

# 4️⃣ Download native libs (no sudo)
echo "⬇️ Downloading required system libraries..."
apt download \
  libnspr4 libnss3 libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 \
  libxcomposite1 libxdamage1 libxrandr2 libxkbcommon0 libpango-1.0-0 \
  libgbm1 libasound2 libx11-xcb1 libxcb-dri3-0 libxshmfence1 \
  libcups2 libdrm2 libxfixes3 libxrender1 libxext6 libxcursor1 \
  libxi6 libxrandr2 libxss1 libxtst6 || true

# 5️⃣ Extract all downloaded .deb files locally
echo "📦 Extracting libraries..."
for f in *.deb; do
  dpkg-deb -x "$f" .
done

# 6️⃣ Configure environment paths
echo "🔧 Configuring environment..."
export LD_LIBRARY_PATH=$HOME/local-libs/usr/lib/x86_64-linux-gnu:$HOME/local-libs/usr/lib:$LD_LIBRARY_PATH
export PATH=$HOME/.local/bin:$PATH

# Persist for next shells
echo 'export LD_LIBRARY_PATH=$HOME/local-libs/usr/lib/x86_64-linux-gnu:$HOME/local-libs/usr/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc

# 7️⃣ Verify Playwright setup
echo "🧪 Verifying Playwright..."
python3 -m playwright --version

python3 - <<'PYCODE'
from playwright.sync_api import sync_playwright
p = sync_playwright().start()
b = p.chromium.launch(headless=True)
print("✅ Chromium launch OK (Render)")
b.close()
p.stop()
PYCODE

echo "=============================="
echo "✅ Setup Completed Successfully"
echo "=============================="