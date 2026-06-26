#!/usr/bin/env bash
# ============================================================
#  platform_serial — Security Container Entrypoint
#  Runs: trivy fs, trivy config, osv-scanner, dart pub outdated
#
#  Environment variables:
#    REPORTS_DIR   Output directory for JSON reports (default: /workspace/security-reports)
#    FAIL_ON_HIGH  Exit non-zero if HIGH/CRITICAL findings exist (default: true)
# ============================================================
set -euo pipefail

REPORTS_DIR="${REPORTS_DIR:-/workspace/security-reports}"
FAIL_ON_HIGH="${FAIL_ON_HIGH:-true}"
mkdir -p "${REPORTS_DIR}"

# Trivy exit code: 1 when HIGH/CRITICAL are found (only when FAIL_ON_HIGH=true)
TRIVY_TABLE_EXIT_CODE=0
if [ "${FAIL_ON_HIGH}" = "true" ]; then
	TRIVY_TABLE_EXIT_CODE=1
fi

OVERALL_FAILED=0

# ── 1. Trivy filesystem scan ─────────────────────────────────
echo ""
echo "🔍 [1/4] Trivy filesystem vulnerability scan..."
trivy fs \
	--format json \
	--output "${REPORTS_DIR}/trivy-fs.json" \
	--exit-code 0 \
	/workspace 2>&1 | tee "${REPORTS_DIR}/trivy-fs.log"

trivy fs \
	--format table \
	--severity HIGH,CRITICAL \
	--exit-code "${TRIVY_TABLE_EXIT_CODE}" \
	/workspace || OVERALL_FAILED=1

echo "📄 Report: ${REPORTS_DIR}/trivy-fs.json"

# ── 2. Trivy config scan (Dockerfiles, CI YAML) ──────────────
echo ""
echo "🔍 [2/4] Trivy config / IaC scan..."
trivy config \
	--format json \
	--output "${REPORTS_DIR}/trivy-config.json" \
	--exit-code 0 \
	/workspace 2>&1 | tee "${REPORTS_DIR}/trivy-config.log"

trivy config \
	--format table \
	--severity HIGH,CRITICAL \
	--exit-code "${TRIVY_TABLE_EXIT_CODE}" \
	/workspace || OVERALL_FAILED=1

echo "📄 Report: ${REPORTS_DIR}/trivy-config.json"

# ── 3. OSV-Scanner — pub.lock dependency audit ───────────────
echo ""
echo "🔍 [3/4] OSV-Scanner dependency audit (pubspec.lock)..."
if [ -f /workspace/pubspec.lock ]; then
	if osv-scanner \
		--lockfile pubspec.lock:/workspace/pubspec.lock \
		--format json \
		>"${REPORTS_DIR}/osv-scan.json" 2>&1; then
		echo "  ✅ No known vulnerabilities found"
	else
		echo "  ⚠️  OSV-Scanner found issues — see ${REPORTS_DIR}/osv-scan.json"
		if [ "${FAIL_ON_HIGH}" = "true" ]; then
			OVERALL_FAILED=1
		fi
	fi
	python3 -c "
import json, sys
try:
    data = json.load(open('${REPORTS_DIR}/osv-scan.json'))
    vulns = data.get('results', [])
    count = sum(len(r.get('packages', [])) for r in vulns)
    print(f'  OSV findings: {count} affected packages')
    for r in vulns:
        for pkg in r.get('packages', []):
            name = pkg['package']['name']
            ver  = pkg['package'].get('version', '?')
            print(f'  ⚠️  {name}@{ver}')
except Exception as e:
    print(f'  (could not parse OSV output: {e})')
" 2>/dev/null || true
	echo "📄 Report: ${REPORTS_DIR}/osv-scan.json"
else
	echo "  ⚠️  pubspec.lock not found — skipping OSV scan"
fi

# ── 4. Dart pub outdated / dependency audit ──────────────────
echo ""
echo "🔍 [4/4] Dart pub outdated & dependency health..."
flutter pub get
flutter pub outdated --json >"${REPORTS_DIR}/pub-outdated.json" 2>&1 || true
flutter pub outdated

echo ""
echo "──────────────────────────────────────────────────────"
echo "📊 Security scan summary:"
echo "   Trivy FS report  : ${REPORTS_DIR}/trivy-fs.json"
echo "   Trivy config     : ${REPORTS_DIR}/trivy-config.json"
echo "   OSV scan         : ${REPORTS_DIR}/osv-scan.json"
echo "   Pub outdated     : ${REPORTS_DIR}/pub-outdated.json"
echo ""

if [ "${OVERALL_FAILED}" -ne 0 ]; then
	echo "❌ Security scan found HIGH/CRITICAL issues (FAIL_ON_HIGH=${FAIL_ON_HIGH})"
	exit 1
fi

echo "✅ Security scan complete — no HIGH/CRITICAL findings"
