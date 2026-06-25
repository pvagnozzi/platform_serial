# ============================================================
#  platform_serial — Shared Base Image
#  Flutter + Dart + common build tooling
#  Used as the FROM layer for all other containers.
# ============================================================
# syntax=docker/dockerfile:1

ARG FLUTTER_VERSION=3.32.0
ARG DART_CHANNEL=stable
ARG DEBIAN_RELEASE=bookworm

# ── stage: flutter-base ─────────────────────────────────────
FROM debian:${DEBIAN_RELEASE}-slim AS flutter-base

ARG FLUTTER_VERSION
ARG DART_CHANNEL

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PUB_CACHE=/root/.pub-cache \
    FLUTTER_HOME=/opt/flutter \
    PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:/root/.pub-cache/bin:${PATH}"

# -- system deps -------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        git \
        unzip \
        xz-utils \
        ca-certificates \
        bash \
        lcov \
        libglu1-mesa \
        wget \
    && rm -rf /var/lib/apt/lists/*

# -- Flutter SDK -------------------------------------------------
RUN git clone --depth 1 \
        --branch ${FLUTTER_VERSION} \
        https://github.com/flutter/flutter.git \
        "${FLUTTER_HOME}" \
    && flutter precache --no-android --no-ios --no-macos \
                        --no-fuchsia --no-windows --no-linux \
                        --web \
    && flutter config --no-analytics \
    && flutter doctor --verbose

# -- pre-warm pub cache ------------------------------------------
WORKDIR /workspace

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get && flutter pub cache repair

# -- final env ---------------------------------------------------
WORKDIR /workspace
LABEL org.opencontainers.image.title="platform_serial-base" \
      org.opencontainers.image.description="Flutter base for platform_serial CI containers" \
      org.opencontainers.image.source="https://github.com/pvagnozzi/platform_serial"
