# ============================================================
#  platform_serial — Builder Container
#  Multi-stage: base → web-build
#  Produces Flutter web output + validates pub.dev publish dry-run
# ============================================================
# syntax=docker/dockerfile:1

ARG BASE_IMAGE=platform_serial-base:latest

# ── stage: build ────────────────────────────────────────────
FROM ${BASE_IMAGE} AS build

WORKDIR /workspace
COPY . .

RUN flutter pub get

# ── stage: web-js ────────────────────────────────────────────
FROM build AS web-js
RUN flutter build web --no-tree-shake-icons \
    && echo "✅ Web (JS) build complete"

# ── stage: web-wasm ─────────────────────────────────────────
FROM build AS web-wasm
RUN flutter build web --wasm --no-tree-shake-icons \
    && echo "✅ Web (WASM) build complete"

# ── stage: pubdry ────────────────────────────────────────────
FROM build AS pubdry
RUN flutter pub publish --dry-run \
    && echo "✅ pub.dev dry-run passed"

# ── default output: web-js ───────────────────────────────────
FROM web-js AS final
LABEL org.opencontainers.image.title="platform_serial-builder" \
      org.opencontainers.image.description="Builder stage for platform_serial"
