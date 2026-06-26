#!/usr/bin/env bash
# ============================================================
#  platform_serial — Git Hooks Shared Library
#  Source this file at the top of every hook:
#    source "$(dirname "$0")/_lib.sh"
# ============================================================

# ── Bypass flag ─────────────────────────────────────────────
# Set GIT_HOOKS_BYPASS=1 in the environment to skip all hooks
# (useful for automated tooling or emergency commits).
# Example: GIT_HOOKS_BYPASS=1 git commit -m "..."
HOOK_BYPASS="${GIT_HOOKS_BYPASS:-0}"
if [ "${HOOK_BYPASS}" = "1" ]; then
	exit 0
fi

# ── ANSI colors ──────────────────────────────────────────────
if [ -t 1 ]; then # only when stdout is a terminal
	bold='\033[1m'
	green='\033[32m'
	yellow='\033[33m'
	red='\033[31m'
	cyan='\033[36m'
	reset='\033[0m'
else
	bold=''
	green=''
	yellow=''
	red=''
	cyan=''
	reset=''
fi

# ── Logging helpers ──────────────────────────────────────────
log() { printf "%b  %s%b\n" "$cyan" "$1" "$reset"; }
ok() { printf "%b✅  %s%b\n" "$green" "$1" "$reset"; }
warn() { printf "%b⚠️   %s%b\n" "$yellow" "$1" "$reset"; }
err() { printf "%b❌  %s%b\n" "$red" "$1" "$reset"; }
die() {
	err "$1"
	exit 1
}
hdr() { printf "\n%b%s%b\n" "$bold" "$1" "$reset"; }

# ── Flutter detection ────────────────────────────────────────
FLUTTER_BIN="$(command -v flutter 2>/dev/null || true)"
# DART_BIN not used by hooks directly but may be useful if sourced externally

require_flutter() {
	if [ -z "$FLUTTER_BIN" ]; then
		warn "flutter not found in PATH — skipping Flutter checks."
		warn "Install Flutter: https://docs.flutter.dev/get-started/install"
		return 1
	fi
	return 0
}

# ── Repo root detection ──────────────────────────────────────
# Works regardless of which subdirectory the hook runs from.
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
	die "Not inside a git repository."
fi

# ── Current branch ───────────────────────────────────────────
current_branch() {
	git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD"
}

# ── Protected branch guard ───────────────────────────────────
PROTECTED_BRANCHES="main develop dev"

is_protected_branch() {
	local branch="$1"
	for protected in ${PROTECTED_BRANCHES}; do
		[ "$branch" = "$protected" ] && return 0
	done
	return 1
}

# ── Staged file helpers ──────────────────────────────────────
staged_dart_files() {
	git diff --cached --name-only --diff-filter=ACMR |
		grep '\.dart$' || true
}

staged_lib_files() {
	staged_dart_files | grep '^lib/' || true
}

staged_test_files() {
	staged_dart_files | grep '^test/' || true
}

any_lib_changed() {
	[ -n "$(staged_lib_files)" ]
}

# ── Convention Commits regex ─────────────────────────────────
# shellcheck disable=SC2034  # exported for sourcing scripts
export CC_PATTERN='^(feat|fix|docs|test|chore|refactor|style|ci|build|perf|revert|release)(\([a-z0-9_/-]+\))?(!)?: .{1,100}$'
