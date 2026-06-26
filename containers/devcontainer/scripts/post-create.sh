#!/usr/bin/env bash
# ============================================================
#  platform_serial — DevContainer Post-Create Script
#  Runs once after the container is created.
# ============================================================
set -euo pipefail

echo "🚀 platform_serial devcontainer post-create setup..."

# -- Flutter deps ------------------------------------------------
echo "📦 Resolving root package dependencies..."
flutter pub get

echo "📦 Resolving example dependencies..."
(cd /workspace/examples/flutter_serial_monitor && flutter pub get)

# -- Flutter config ----------------------------------------------
echo "⚙️  Configuring Flutter for web + linux..."
flutter config --enable-web
flutter config --enable-linux-desktop

# -- Git config (if not already set) ----------------------------
if [ -z "$(git config --global user.email 2>/dev/null || true)" ]; then
	echo "ℹ️  Git user not configured — skipping (set via VS Code settings)."
fi

# -- Pre-cache Flutter web engine --------------------------------
echo "🌐 Pre-caching Flutter web engine..."
flutter precache --web

# -- Verify toolchain --------------------------------------------
echo ""
echo "🔍 flutter doctor:"
flutter doctor --verbose

echo ""
echo "✅ DevContainer is ready!"
echo "   Run: flutter analyze && flutter test"
