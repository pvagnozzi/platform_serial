---
name: web-support-wrapper
description: Add and evolve web support using stable wrappers over browser Web Serial capabilities.
---

# Web Support Wrapper

Use this skill when implementing or extending `platform_serial` support for Flutter Web.

## Steps

1. Keep `SerialPlatformInterface` abstract and use conditional factories for IO vs Web builds.
2. Wrap browser Web Serial APIs behind `WebSerialImpl` without leaking JS interop details into public API.
3. Preserve existing event payload format (`type`, `data`, `message`, optional `portName`).
4. Keep unsupported modem-control operations explicit via typed platform errors.
5. Document platform differences and constraints in `README.md`.

## Pitfalls

- Do not import `dart:io` in web-compiled paths.
- Do not bypass typed errors for browser capability checks.
- Do not block the event loop with synchronous conversions in read streams.
