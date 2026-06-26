#!/usr/bin/env bash
# ============================================================
#  platform_serial — Builder Container Entrypoint
#
#  Builds the flutter_serial_monitor example app for web
#  (JS or WASM) or validates pub.dev metadata for the plugin.
#
#  Environment variables:
#    BUILD_TARGET   web-js (default) | web-wasm | pubdry
# ============================================================
set -euo pipefail

TARGET="${BUILD_TARGET:-web-js}"

echo "🏗️  Build target: ${TARGET}"

case "${TARGET}" in
pubdry)
	# --- Validate plugin pub.dev metadata from the repo root ---
	echo "📦 Validating pub.dev metadata (pub publish --dry-run)..."
	flutter pub get
	flutter pub publish --dry-run
	echo "✅ pub.dev dry-run passed"
	;;
*)
	# --- Build the flutter_serial_monitor example for web ---
	EXAMPLE_DIR="/workspace/examples/flutter_serial_monitor"

	echo "📦 Resolving example dependencies..."
	(cd "${EXAMPLE_DIR}" && flutter pub get)

	case "${TARGET}" in
	web-wasm)
		echo "🌐 Building Flutter Web (WASM)..."
		(cd "${EXAMPLE_DIR}" && flutter build web --wasm --no-tree-shake-icons)
		;;
	*)
		echo "🌐 Building Flutter Web (JS)..."
		(cd "${EXAMPLE_DIR}" && flutter build web --no-tree-shake-icons)
		;;
	esac

	echo "✅ Build complete — output at ${EXAMPLE_DIR}/build/web"
	;;
esac
