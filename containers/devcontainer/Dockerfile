# ============================================================
#  platform_serial — DevContainer
#  Full development environment: Flutter, Dart, Git, VS Code
#  server extensions, lcov, trivy, and container tools.
#
#  Usage: open in VS Code with Dev Containers extension,
#  or run: docker build -f containers/devcontainer/Dockerfile .
# ============================================================
# syntax=docker/dockerfile:1

ARG BASE_IMAGE=platform_serial-base:latest
ARG TRIVY_VERSION=0.59.1

# ── copy trivy from the security build stage ─────────────────
FROM debian:bookworm-slim AS trivy-install
ARG TRIVY_VERSION
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates && rm -rf /var/lib/apt/lists/*
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
        | sh -s -- -b /usr/local/bin "v${TRIVY_VERSION}"

# ── devcontainer ─────────────────────────────────────────────
FROM ${BASE_IMAGE} AS devcontainer

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

# General dev tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        openssh-client \
        gnupg2 \
        procps \
        lsof \
        htop \
        make \
        jq \
        zip \
        unzip \
        python3 \
        python3-pip \
        lcov \
    && rm -rf /var/lib/apt/lists/*

# Android SDK tooling dependencies (JDK)
RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-17-jdk-headless \
        libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

# Linux desktop build toolchain (clang, cmake, GTK headers)
RUN apt-get update && apt-get install -y --no-install-recommends \
        clang \
        cmake \
        ninja-build \
        pkg-config \
        libgtk-3-dev \
        liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Docker CLI prerequisites (needed before adding the Docker apt repo)
RUN apt-get update && apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Docker CLI (for sibling container operations inside the devcontainer)
RUN curl -fsSL https://download.docker.com/linux/debian/gpg \
        | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) \
        signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
        https://download.docker.com/linux/debian \
        $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Copy Trivy security scanner
COPY --from=trivy-install /usr/local/bin/trivy /usr/local/bin/trivy

# Create non-root user for VS Code
RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" \
               -m -s /bin/bash "${USERNAME}" \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" \
       >> /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Transfer Flutter SDK ownership to the dev user
RUN chown -R "${USERNAME}:${USERNAME}" /opt/flutter /root/.pub-cache 2>/dev/null || true

USER ${USERNAME}
WORKDIR /workspace

ENV HOME=/home/${USERNAME} \
    PUB_CACHE=/home/${USERNAME}/.pub-cache \
    PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:/home/${USERNAME}/.pub-cache/bin:${PATH}"

CMD ["/bin/bash"]

LABEL org.opencontainers.image.title="platform_serial-devcontainer" \
      org.opencontainers.image.description="Full dev environment for platform_serial"
