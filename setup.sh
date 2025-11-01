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

# 4️⃣ Install Python dependencies (user-safe, no sudo)
echo "🐍 Installing Python dependencies..."
python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Required project libs
python3 -m pip install python-dotenv cryptography httpx
python3 -m pip install "python-telegram-bot<23,>=22.0"
python3 -m pip install instagrapi
python3 -m pip install playwright
python3 -m pip install playwright-stealth==1.0.6
playwright install
python3 -m pip install aiohttp
# Install Playwright + Chromium browser directly in project (persistent)
echo "🌐 Installing Playwright browsers (Render persistent)..."
export PLAYWRIGHT_BROWSERS_PATH="$APP_DIR/ms-playwright"
python3 -m playwright install chromium

# 6️⃣ Verify
echo "✅ Setup complete!"
echo "LD_LIBRARY_PATH set to: $LIBS_DIR"
python3 --version
python3 -m playwright --version || true
