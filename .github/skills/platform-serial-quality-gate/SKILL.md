---
name: platform-serial-quality-gate
description: Run the professional quality gate for platform_serial before PRs and releases.
---

# platform_serial Quality Gate

Use this skill when validating a code change, release PR, or automated agent output in this repository.

## Steps

1. Resolve dependencies:
   ```bash
   flutter pub get
   (cd example && flutter pub get)
   ```
2. Analyze with fatal warnings and infos:
   ```bash
   flutter analyze --fatal-infos --fatal-warnings
   (cd example && flutter analyze --fatal-infos --fatal-warnings)
   ```
3. Run tests with coverage:
   ```bash
   flutter test --coverage
   dart run tool/coverage_gate.dart --lcov coverage/lcov.info --min-lines 100
   ```
4. For release-impacting changes, validate pub.dev metadata:
   ```bash
   flutter pub publish --dry-run
   ```
5. Update documentation whenever public API, platform behavior, setup scripts, CI, or release automation changes.

## Pitfalls

- Do not count hardware-only native backends as covered by default unit tests unless the CI runner provisions that platform and device access.
- Do not bypass `SerialError`; public errors should stay typed and cross-platform.
- Do not publish from unprotected branches or before the PR into `main` is merged.
