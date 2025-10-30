#!/usr/bin/env bash
set -eux

echo "=============================="
echo "1️⃣  Prepare folders"
echo "=============================="
mkdir -p ~/.local/bin ~/.local/lib ~/.cache/ms-playwright ~/local-libs
cd ~/local-libs

echo "=============================="
echo "2️⃣  Install Python dependencies"
echo "=============================="
pip install --upgrade pip setuptools wheel
pip install python-dotenv cryptography httpx "python-telegram-bot<23,>=22.0" instagrapi playwright playwright-stealth==1.0.6

echo "=============================="
echo "3️⃣  Install Playwright Chromium"
echo "=============================="
python3 -m playwright install chromium

echo "=============================="
echo "4️⃣  Download required native libraries (Render-safe)"
echo "=============================="
# Base Debian repo for bookworm (Render OS)
BASE_URL="http://deb.debian.org/debian/pool/main"

# You can add/remove URLs here if needed
wget -q ${BASE_URL}/n/nss/libnss3_3.87.1-1+deb12u1_amd64.deb
wget -q ${BASE_URL}/n/nspr/libnspr4_4.35-1_amd64.deb
wget -q ${BASE_URL}/a/atk1.0/libatk1.0-0_2.46.0-5_amd64.deb
wget -q ${BASE_URL}/a/at-spi2-core/libatspi2.0-0_2.46.0-5_amd64.deb
wget -q ${BASE_URL}/a/atk-bridge2.0/libatk-bridge2.0-0_2.46.0-5_amd64.deb
wget -q ${BASE_URL}/x/x11proto-xext/libxext6_1.3.4-1+b1_amd64.deb
wget -q ${BASE_URL}/x/xrandr/libxrandr2_1.5.2-2+b1_amd64.deb
wget -q ${BASE_URL}/x/xkbcommon/libxkbcommon0_1.5.0-1_amd64.deb
wget -q ${BASE_URL}/x/x11proto-xf86vidmode/libxfixes3_6.0.0-2_amd64.deb
wget -q ${BASE_URL}/x/xrender/libxrender1_0.9.10-1.1_amd64.deb
wget -q ${BASE_URL}/x/xi/libxi6_1.8-1+b1_amd64.deb
wget -q ${BASE_URL}/p/pango1.0/libpango-1.0-0_1.50.12+ds-1_amd64.deb
wget -q ${BASE_URL}/g/gbm/libgbm1_22.3.6-1+deb12u1_amd64.deb
wget -q ${BASE_URL}/a/asound/libasound2_1.2.8-1+b1_amd64.deb

echo "=============================="
echo "5️⃣  Extract libraries locally"
echo "=============================="
for f in *.deb; do
  dpkg-deb -x "$f" .
done

echo "=============================="
echo "6️⃣  Export library path"
echo "=============================="
export LD_LIBRARY_PATH=$HOME/local-libs/usr/lib/x86_64-linux-gnu:$HOME/local-libs/usr/lib:$LD_LIBRARY_PATH
export PATH=$HOME/.local/bin:$PATH
echo 'export LD_LIBRARY_PATH=$HOME/local-libs/usr/lib/x86_64-linux-gnu:$HOME/local-libs/usr/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc

echo "=============================="
echo "7️⃣  Verify Playwright"
echo "=============================="
python3 -m playwright --version
python3 - <<'EOF'
from playwright.sync_api import sync_playwright
p = sync_playwright().start()
b = p.chromium.launch(headless=True)
print("✅ Playwright OK with native libs")
b.close()
p.stop()
EOF

echo "=============================="
echo "8️⃣  Start bot"
echo "=============================="
