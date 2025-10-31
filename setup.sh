#!/usr/bin/env bash
set -e

echo "=== Playwright + Custom Libs Setup (Render Safe) ==="

# 1️⃣ Paths
APP_DIR="$PWD"
LIBS_DIR="$APP_DIR/libs"

# 2️⃣ Unzip prebuilt libraries
if [ -f "$APP_DIR/libs.zip" ]; then
  echo "📦 Extracting libs.zip..."
  unzip -o "$APP_DIR/libs.zip" -d "$LIBS_DIR" >/dev/null
else
  echo "❌ libs.zip not found in repo root!"
  exit 1
fi

# 3️⃣ Export library path
echo "🔧 Setting LD_LIBRARY_PATH..."
export LD_LIBRARY_PATH="$LIBS_DIR:$LD_LIBRARY_PATH"

# Persist for runtime (Render)
echo "export LD_LIBRARY_PATH=$LIBS_DIR:\$LD_LIBRARY_PATH" >> ~/.bashrc

# 4️⃣ Install Python dependencies (Render-safe, no sudo)
echo "🐍 Installing Python dependencies..."
python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Required project libraries
python3 -m pip install --no-cache-dir python-dotenv cryptography httpx
python3 -m pip install --no-cache-dir "python-telegram-bot<23,>=22.0"
python3 -m pip install --no-cache-dir instagrapi
python3 -m pip install --no-cache-dir playwright
python3 -m pip install --no-cache-dir playwright-stealth==1.0.6

# Skip sudo-based deps
echo "🚫 Skipping 'playwright install-deps' (no root on Render)."
python3 -m playwright install chromium || true

# ==============================
# 🧩 Manual Chromium install (no sudo)
# ==============================
echo "📦 Downloading Chromium for Playwright..."
CACHE_DIR="/opt/render/.cache/ms-playwright/chromium_headless_shell-1187/chrome-linux"
mkdir -p "$CACHE_DIR"
cd "$CACHE_DIR"

curl -L -o chromium-headless.zip \
  https://storage.googleapis.com/chromium-browser-snapshots/Linux_x64/1181205/chrome-linux.zip

unzip -q chromium-headless.zip
mv chrome-linux/* .
rm -rf chrome-linux chromium-headless.zip
chmod +x ./chrome

echo "✅ Chromium installed manually."

# ==============================
# ✅ Final verification
# ==============================
cd "$APP_DIR"
echo "✅ Setup complete!"
echo "LD_LIBRARY_PATH set to: $LIBS_DIR"
python3 --version
python3 -m playwright --version || true
