#!/usr/bin/env bash
# ============================================================
#  platform_serial — Build Container Entrypoint
# ============================================================
set -euo pipefail

TARGET="${BUILD_TARGET:-web-js}"   # web-js | web-wasm | pubdry

echo "🏗️  Build target: ${TARGET}"
flutter pub get

case "${TARGET}" in
  web-wasm)
    echo "🌐 Building Flutter Web (WASM)..."
    flutter build web --wasm --no-tree-shake-icons
    ;;
  pubdry)
    echo "📦 Validating pub.dev metadata (dry-run)..."
    flutter pub publish --dry-run
    ;;
  *)
    echo "🌐 Building Flutter Web (JS)..."
    flutter build web --no-tree-shake-icons
    ;;
esac

echo "✅ Build complete"
