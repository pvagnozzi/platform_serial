#!/usr/bin/env bash
# ============================================================
#  platform_serial — Analyze Container Entrypoint
#  Runs flutter analyze on root package and example
# ============================================================
set -euo pipefail

ANALYZE_FLAGS="${ANALYZE_FLAGS:---fatal-infos --fatal-warnings}"

echo "🔍 Resolving root dependencies..."
flutter pub get

echo "🔍 Analyzing root package..."
# shellcheck disable=SC2086
flutter analyze ${ANALYZE_FLAGS}

echo "🔍 Resolving example dependencies..."
(cd examples/flutter_serial_monitor && flutter pub get)

echo "🔍 Analyzing flutter_serial_monitor example..."
# shellcheck disable=SC2086
(cd examples/flutter_serial_monitor && flutter analyze ${ANALYZE_FLAGS})

echo "📦 Validating pub.dev metadata..."
flutter pub publish --dry-run

echo "✅ Static analysis complete — no issues found"
