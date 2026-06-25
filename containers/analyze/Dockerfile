# ============================================================
#  platform_serial — Analyze Container
#  Runs: flutter analyze --fatal-infos --fatal-warnings
#        on root package + examples/flutter_serial_monitor
# ============================================================
# syntax=docker/dockerfile:1

ARG BASE_IMAGE=platform_serial-base:latest

FROM ${BASE_IMAGE} AS analyze

WORKDIR /workspace
COPY . .

RUN flutter pub get \
 && (cd examples/flutter_serial_monitor && flutter pub get)

LABEL org.opencontainers.image.title="platform_serial-analyze" \
      org.opencontainers.image.description="Static analysis stage for platform_serial"

ENTRYPOINT ["/workspace/containers/analyze/entrypoint.sh"]
CMD []
