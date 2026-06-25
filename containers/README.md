# Containers

Docker containers for CI, local quality gates, security scanning, and development.

---

## Structure

```
containers/
├── base/                   # Shared Flutter base image (used by all others)
│   └── Dockerfile
├── build/                  # Flutter web build (JS + WASM + pub dry-run)
│   ├── Dockerfile
│   └── entrypoint.sh
├── test/                   # flutter test --coverage + coverage gate
│   ├── Dockerfile
│   └── entrypoint.sh
├── analyze/                # flutter analyze + pub.dev dry-run
│   ├── Dockerfile
│   └── entrypoint.sh
├── security/               # Trivy + OSV-Scanner + pub outdated
│   ├── Dockerfile
│   └── entrypoint.sh
├── devcontainer/           # Full dev environment (VS Code Dev Containers)
│   ├── Dockerfile
│   ├── devcontainer.json   → referenced by /.devcontainer/devcontainer.json
│   └── scripts/
│       └── post-create.sh
└── docker-compose.yml      # Orchestrates all services
```

---

## Base image

`containers/base/Dockerfile` is the shared foundation. It installs Flutter,
pre-warms the pub cache, and is used as the `FROM` layer in all other
containers. Build it first:

```bash
docker compose -f containers/docker-compose.yml build base
```

---

## Services

| Service | Image | Purpose |
|---------|-------|---------|
| `base` | `platform_serial-base` | Flutter + Dart base |
| `build` | `platform_serial-build` | Web build (JS / WASM / pubdry) |
| `test` | `platform_serial-test` | Tests + coverage |
| `analyze` | `platform_serial-analyze` | Static analysis |
| `security` | `platform_serial-security` | Trivy + OSV + pub audit |
| `devcontainer` | `platform_serial-devcontainer` | Full dev environment |

---

## Quick start

```bash
# Build the shared base image
docker compose -f containers/docker-compose.yml build base

# Run tests
docker compose -f containers/docker-compose.yml run --rm test

# Run static analysis
docker compose -f containers/docker-compose.yml run --rm analyze

# Run security scan
docker compose -f containers/docker-compose.yml run --rm security

# Build Flutter web (JS)
docker compose -f containers/docker-compose.yml run --rm build

# Build Flutter web (WASM)
BUILD_TARGET=web-wasm docker compose -f containers/docker-compose.yml run --rm build

# Start interactive dev container
docker compose -f containers/docker-compose.yml run --rm --service-ports devcontainer
```

Or use the per-platform scripts in `scripts/<platform>/commands/`.

---

## Multi-stage build design

```
containers/base/Dockerfile       ← Flutter + Dart foundation
        │
        ├── containers/build/Dockerfile
        │       ├── stage: build     (flutter pub get)
        │       ├── stage: web-js    (flutter build web)
        │       ├── stage: web-wasm  (flutter build web --wasm)
        │       └── stage: pubdry    (flutter pub publish --dry-run)
        │
        ├── containers/test/Dockerfile
        │       └── stage: test      (flutter test --coverage)
        │
        ├── containers/analyze/Dockerfile
        │       └── stage: analyze   (flutter analyze + pub dry-run)
        │
        ├── containers/security/Dockerfile
        │       ├── stage: trivy-install   (aquasecurity/trivy)
        │       ├── stage: osv-install     (google/osv-scanner)
        │       └── stage: security        (combined scan runner)
        │
        └── containers/devcontainer/Dockerfile
                ├── stage: trivy-install   (reuses trivy binary)
                └── stage: devcontainer    (full dev environment)
```

---

## Environment variables

| Variable | Service | Default | Description |
|----------|---------|---------|-------------|
| `BUILD_TARGET` | build | `web-js` | `web-js` \| `web-wasm` \| `pubdry` |
| `MIN_COVERAGE` | test | `100` | Minimum line coverage percentage |
| `ANALYZE_FLAGS` | analyze | `--fatal-infos --fatal-warnings` | Flutter analyze flags |
| `FAIL_ON_HIGH` | security | `true` | Exit non-zero on HIGH/CRITICAL findings |
| `REPORTS_DIR` | security | `/workspace/security-reports` | Report output directory |

---

## VS Code Dev Container

The `.devcontainer/devcontainer.json` references `containers/devcontainer/Dockerfile`.
Open the repository in VS Code with the **Dev Containers** extension installed,
then select **Reopen in Container**.

Features included in the devcontainer:

- Flutter + Dart SDK
- Docker CLI (for sibling container operations)
- Trivy vulnerability scanner
- Git, GitHub CLI
- lcov for coverage reports
- Linux desktop build toolchain (clang, cmake, ninja)
