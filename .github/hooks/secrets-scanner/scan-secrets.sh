#!/bin/bash
set -euo pipefail

if [[ "${SKIP_SECRETS_SCAN:-}" == "true" ]]; then
  exit 0
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

MODE="${SCAN_MODE:-warn}"
FILES="$(git diff --name-only --diff-filter=ACMR HEAD 2>/dev/null || true)"

if [[ -z "${FILES}" ]]; then
  exit 0
fi

patterns=(
  "ghp_[0-9A-Za-z]{36}"
  "AKIA[0-9A-Z]{16}"
  "-----BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----"
  "(secret|token|password|api[_-]?key)[[:space:]]*[:=][[:space:]]*['\"]?[A-Za-z0-9_./+=~-]{8,}"
)

found=0
for f in $FILES; do
  [[ -f "$f" ]] || continue
  for p in "${patterns[@]}"; do
    if grep -qE "$p" "$f"; then
      echo "⚠️ Potential secret in: $f"
      found=1
      break
    fi
  done
done

if [[ $found -eq 1 && "$MODE" == "block" ]]; then
  exit 1
fi

exit 0
