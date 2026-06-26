#!/usr/bin/env bash
# ============================================================
#  platform_serial — Git Hooks Installer (Linux / macOS)
#
#  Idempotent: safe to run multiple times.
#  Sets git core.hooksPath to .githooks/ for this repository.
#
#  Synopsis:
#    .githooks/install.sh [options]
#
#  Options:
#    --dry-run    Print actions without changing anything.
#    --uninstall  Remove the hooksPath configuration.
#    -h, --help   Show this help.
#
#  Examples:
#    .githooks/install.sh           # install hooks
#    .githooks/install.sh --dry-run # preview changes
#    .githooks/install.sh --uninstall
# ============================================================
set -euo pipefail

DRY_RUN=0
UNINSTALL=0

bold='\033[1m'; green='\033[32m'; yellow='\033[33m'; red='\033[31m'; cyan='\033[36m'; reset='\033[0m'
log()  { printf "%b  %s%b\n"    "$cyan"   "$1" "$reset"; }
ok()   { printf "%b✅  %s%b\n"  "$green"  "$1" "$reset"; }
warn() { printf "%b⚠️   %s%b\n" "$yellow" "$1" "$reset"; }
fail() { printf "%b❌  %s%b\n"  "$red"    "$1" "$reset"; exit 1; }
run()  { if [ "$DRY_RUN" -eq 1 ]; then warn "dry-run: $*"; else eval "$@"; fi; }

usage() {
  grep '^#  ' "$0" | sed 's/^#  //'
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)   usage ;;
    *) fail "Unknown option: $1" ;;
  esac
  shift
done

# Locate repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) \
  || fail "Not inside a git repository."

HOOKS_DIR="${REPO_ROOT}/.githooks"
[ -d "${HOOKS_DIR}" ] || fail ".githooks/ directory not found in ${REPO_ROOT}"

printf "%b%s%b\n" "$bold" "🪝 platform_serial git hooks installer" "$reset"
echo ""

# ── Uninstall ─────────────────────────────────────────────────
if [ "$UNINSTALL" -eq 1 ]; then
  CURRENT=$(git -C "${REPO_ROOT}" config --local core.hooksPath 2>/dev/null || echo "")
  if [ -z "$CURRENT" ]; then
    warn "core.hooksPath is not set — nothing to uninstall."
  else
    run "git -C '${REPO_ROOT}' config --local --unset core.hooksPath"
    ok "core.hooksPath removed (was: ${CURRENT})"
  fi
  exit 0
fi

# ── Check current setting ────────────────────────────────────
CURRENT=$(git -C "${REPO_ROOT}" config --local core.hooksPath 2>/dev/null || echo "")
if [ "${CURRENT}" = ".githooks" ]; then
  ok "core.hooksPath already set to .githooks — nothing to do."
else
  log "Setting git config core.hooksPath = .githooks ..."
  run "git -C '${REPO_ROOT}' config --local core.hooksPath .githooks"
  ok "core.hooksPath = .githooks"
fi

# ── Make hook scripts executable ────────────────────────────
log "Making hook scripts executable..."
for hook in "${HOOKS_DIR}"/post-checkout "${HOOKS_DIR}"/pre-commit \
             "${HOOKS_DIR}"/pre-push      "${HOOKS_DIR}"/commit-msg; do
  if [ -f "$hook" ]; then
    run "chmod +x '${hook}'"
    ok "  $(basename "${hook}"): +x"
  fi
done

# ── Verify git version (3.x for hooksPath) ───────────────────
GIT_VERSION=$(git --version | awk '{print $3}')
GIT_MAJOR=$(echo "${GIT_VERSION}" | cut -d. -f1)
if [ "${GIT_MAJOR:-2}" -lt 2 ]; then
  warn "Git ${GIT_VERSION} is old. core.hooksPath requires Git 2.9+."
fi

echo ""
ok "Git hooks installed! 🎉"
echo ""
echo "  Hooks active:"
echo "    post-checkout — quality gate on new branch creation"
echo "    pre-commit    — analyze + test alignment + CHANGELOG check"
echo "    pre-push      — full test suite + coverage gate + push guard"
echo "    commit-msg    — Conventional Commits format validation"
echo ""
echo "  Bypass (emergency): GIT_HOOKS_BYPASS=1 git <command>"
echo "  Uninstall:          .githooks/install.sh --uninstall"
