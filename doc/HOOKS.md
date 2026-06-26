# Git Hooks

platform_serial ships with a set of Git hooks in `.githooks/` that enforce
code quality locally — before code reaches CI.

---

## Quick install

```bash
# Linux / macOS
.githooks/install.sh

# Windows (PowerShell)
.githooks\install.ps1
```

Both installers are **idempotent** — safe to run multiple times. They set
`git config core.hooksPath .githooks` for this repository only.

---

## Hooks reference

### `post-checkout` — quality gate on new branch creation

Triggered by `git checkout -b <branch>` or `git switch -c <branch>`.

Detects when a **new** branch is created (previous HEAD == new HEAD) and runs
a quality gate to verify that you're starting from a clean state:

1. `flutter analyze --fatal-infos --fatal-warnings`
2. `flutter test --coverage`
3. `dart run tool/coverage_gate.dart` (100% line coverage)

> This hook **warns** but does not abort the branch creation (post-checkout
> cannot prevent the operation). Fix any issues before adding new code.

```bash
# Example output on clean state:
# 🌿 New branch: feature/my-feature
#    Verifying starting quality state...
#    1/3 — Static analysis...
# ✅  Static analysis passed
#    2/3 — Running test suite...
# ✅  Tests passed
#    3/3 — Coverage gate...
# ✅  Coverage gate passed
# ✅  Branch 'feature/my-feature' starts from a clean state. Happy coding! 🚀
```

---

### `pre-commit` — fast checks before each commit

Runs automatically before `git commit`. Checks:

| # | Check | Blocking? |
|---|-------|-----------|
| 1 | `flutter analyze --fatal-infos --fatal-warnings` | ✅ Yes |
| 2 | Test alignment — every staged `lib/src/*.dart` has a test counterpart | ⚠️ Warning |
| 3 | Public API documentation — new public types have `///` comments | ⚠️ Warning |
| 4 | CHANGELOG.md reminder — staged `lib/` changes without CHANGELOG update | ⚠️ Warning |
| 5 | No `skip:` markers in staged test files | ✅ Yes |

Warnings do **not** block the commit — they remind you to review. Errors do block.

---

### `pre-push` — full test suite before push

Runs automatically before `git push`. Checks:

| # | Check | Blocking? |
|---|-------|-----------|
| 1 | Block direct push to `main / develop / dev` | ✅ Yes |
| 2 | `flutter test --coverage` full suite | ✅ Yes |
| 3 | 100% line coverage gate | ✅ Yes |
| 4 | `flutter pub publish --dry-run` (release/hotfix branches only) | ✅ Yes |

> **Tip:** `pre-push` is the last local gate before CI. All test failures
> detected here would also block the PR on GitHub.

---

### `commit-msg` — Conventional Commits validation

Validates every commit message format before it is saved:

```
<type>(<optional scope>): <description>
```

**Valid types:** `feat` `fix` `docs` `test` `chore` `refactor`
`style` `ci` `build` `perf` `revert`

**Examples:**

```
feat(web): add Web Serial API support
fix: resolve null safety issue in SerialPort
docs: update README web section
test(web): add WebSerialImpl unit tests
chore: bump dependencies
feat!: BREAKING — rename SerialConfig.port to SerialConfig.portName
```

Merge commits (`Merge branch …`) and revert commits (`Revert "…"`) are
automatically allowed without format checking.

---

## Bypassing hooks

Set `GIT_HOOKS_BYPASS=1` in the environment for emergency situations:

```bash
# Linux / macOS
GIT_HOOKS_BYPASS=1 git commit -m "emergency: ..."
GIT_HOOKS_BYPASS=1 git push

# Windows (PowerShell)
$env:GIT_HOOKS_BYPASS = '1'
git commit -m "emergency: ..."
Remove-Item Env:GIT_HOOKS_BYPASS
```

---

## Uninstalling hooks

```bash
# Linux / macOS
.githooks/install.sh --uninstall

# Windows
.githooks\install.ps1 -Uninstall
```

This removes `core.hooksPath` from the local git config. The `.githooks/`
directory and files are not deleted.

---

## CI / GitHub Actions alignment

The same quality gates that run locally in git hooks are mirrored in
`.github/workflows/test-pr.yml`:

| Local hook | CI job |
|------------|--------|
| `post-checkout` (analyze) | `📊 Analyze & Validate` |
| `pre-push` (test + coverage) | `🧪 Tests & Coverage` |
| `pre-push` (pub dry-run) | `📊 Analyze & Validate` |
| `commit-msg` | `📝 Commit Conventions` |
| *(smoke test)* | `🔬 Example Smoke Test` |
| *(Docker validate)* | `🐳 Docker Compose Validation` |

The `✅ PR Status Check` job aggregates all CI jobs. GitHub's branch
protection rules (`.github/rulesets/gitflow-branch-protection.json`)
require this check to pass before merging into `main`, `develop`, or `dev`.

---

## Team onboarding

Add these steps to your setup:

```bash
# 1. Clone the repo
git clone https://github.com/pvagnozzi/platform_serial.git
cd platform_serial

# 2. Install Flutter and dev dependencies
scripts/linux/setup/setup-devenv --yes     # or macos / windows

# 3. Install git hooks
.githooks/install.sh                       # or install.ps1 on Windows

# 4. Verify everything works
flutter pub get
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
```
