# ============================================================
#  platform_serial — Builder Container
#
#  TWO usage modes:
#
#  A) docker compose run  (runtime target selection via BUILD_TARGET):
#       docker compose -f containers/docker-compose.yml run --rm builder
#       BUILD_TARGET=web-wasm docker compose ... run --rm builder
#
#  B) docker build --target  (compile-time, artifact baked into image):
#       docker build --target web-js  -f containers/builder/Dockerfile .
#       docker build --target web-wasm -f containers/builder/Dockerfile .
#       docker build --target pubdry  -f containers/builder/Dockerfile .
# ============================================================
# syntax=docker/dockerfile:1

ARG BASE_IMAGE=platform_serial-base:latest

# ── stage: deps ─────────────────────────────────────────────
# Used as the common dependency layer for both runtime and
# compile-time usage modes.
FROM ${BASE_IMAGE} AS deps

WORKDIR /workspace
COPY . .
RUN flutter pub get

# ── runtime mode (Mode A) ────────────────────────────────────
# The entrypoint script reads BUILD_TARGET at container start.
# Use with: docker compose run --rm builder
#           BUILD_TARGET=web-wasm docker compose run --rm builder
FROM deps AS builder

COPY containers/builder/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

LABEL org.opencontainers.image.title="platform_serial-builder" \
      org.opencontainers.image.description="Builder container for platform_serial"

ENTRYPOINT ["/entrypoint.sh"]
CMD []

# ── compile-time stages (Mode B) ────────────────────────────
# These stages bake the build output into the image layer.
# Useful for CI pipelines that cache build artifacts in registry.

FROM deps AS web-js
RUN flutter build web --no-tree-shake-icons \
    && echo "✅ Web (JS) build complete"

FROM deps AS web-wasm
RUN flutter build web --wasm --no-tree-shake-icons \
    && echo "✅ Web (WASM) build complete"

FROM deps AS pubdry
RUN flutter pub publish --dry-run \
    && echo "✅ pub.dev dry-run passed"
