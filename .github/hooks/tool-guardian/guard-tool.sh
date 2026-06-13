#!/bin/bash
set -euo pipefail

if [[ "${SKIP_TOOL_GUARD:-}" == "true" ]]; then
  exit 0
fi

INPUT="$(cat)"
MODE="${GUARD_MODE:-block}"

danger_patterns=(
  "rm -rf /"
  "git reset --hard"
  "git push --force"
  "DROP DATABASE"
  "TRUNCATE "
)

match=""
for p in "${danger_patterns[@]}"; do
  if printf '%s' "$INPUT" | grep -qiE "$p"; then
    match="$p"
    break
  fi
done

if [[ -n "$match" ]]; then
  echo "🛡️ Tool Guardian: pattern bloccato -> $match"
  if [[ "$MODE" == "block" ]]; then
    exit 1
  fi
fi

exit 0
