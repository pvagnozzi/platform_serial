# ============================================================
#  platform_serial — Test Container
#  Runs flutter test --coverage + coverage gate
# ============================================================
# syntax=docker/dockerfile:1

ARG BASE_IMAGE=platform_serial-base:latest

FROM ${BASE_IMAGE} AS test

# lcov is pre-installed in the base image
WORKDIR /workspace
COPY . .

RUN flutter pub get

LABEL org.opencontainers.image.title="platform_serial-test" \
      org.opencontainers.image.description="Test + coverage stage for platform_serial"

ENTRYPOINT ["/workspace/containers/test/entrypoint.sh"]
CMD []
