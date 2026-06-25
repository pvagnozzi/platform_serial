#!/usr/bin/env bash
# ============================================================
#  platform_serial — Test Container Entrypoint
#  Runs: flutter test --coverage + coverage gate
# ============================================================
set -euo pipefail

MIN_COVERAGE="${MIN_COVERAGE:-100}"

echo "🧪 Running tests with coverage (min ${MIN_COVERAGE}%)..."
flutter pub get
flutter test --coverage

echo "📊 Enforcing coverage gate (≥${MIN_COVERAGE}% lines)..."
dart run tool/coverage_gate.dart \
    --lcov coverage/lcov.info \
    --min-lines "${MIN_COVERAGE}"

echo "✅ All tests passed and coverage gate satisfied"
