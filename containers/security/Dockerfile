# ============================================================
#  platform_serial — Security Container
#  Multi-stage: trivy + osv-scanner + dart pub audit
#  Scans container images, source code, and pub dependencies
# ============================================================
# syntax=docker/dockerfile:1

ARG BASE_IMAGE=platform_serial-base:latest
ARG TRIVY_VERSION=0.59.1
ARG OSV_SCANNER_VERSION=1.9.2

# ── stage: trivy-install ─────────────────────────────────────
FROM debian:bookworm-slim AS trivy-install
ARG TRIVY_VERSION
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
        | sh -s -- -b /usr/local/bin "v${TRIVY_VERSION}"

# ── stage: osv-install ──────────────────────────────────────
FROM debian:bookworm-slim AS osv-install
ARG OSV_SCANNER_VERSION
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN ARCH=$(dpkg --print-architecture) \
    && case "${ARCH}" in \
         amd64) OSV_ARCH="linux-amd64" ;; \
         arm64) OSV_ARCH="linux-arm64" ;; \
         *) echo "Unsupported: ${ARCH}" && exit 1 ;; \
       esac \
    && curl -fsSL \
        "https://github.com/google/osv-scanner/releases/download/v${OSV_SCANNER_VERSION}/osv-scanner_${OSV_ARCH}" \
        -o /usr/local/bin/osv-scanner \
    && chmod +x /usr/local/bin/osv-scanner

# ── stage: security ──────────────────────────────────────────
FROM ${BASE_IMAGE} AS security

# Copy scanner binaries from build stages
COPY --from=trivy-install /usr/local/bin/trivy /usr/local/bin/trivy
COPY --from=osv-install   /usr/local/bin/osv-scanner /usr/local/bin/osv-scanner

# Install additional security tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        jq \
        python3-pip \
        git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY . .
RUN flutter pub get

LABEL org.opencontainers.image.title="platform_serial-security" \
      org.opencontainers.image.description="Security & vulnerability scanning for platform_serial"

ENTRYPOINT ["/workspace/containers/security/entrypoint.sh"]
CMD []
