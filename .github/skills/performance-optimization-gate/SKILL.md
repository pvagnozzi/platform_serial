---
name: performance-optimization-gate
description: Validate performance-sensitive serial I/O paths and avoid regressions across platforms.
---

# Performance Optimization Gate

Use this skill when touching event loops, polling, read/write buffering, or platform bridge code.

## Steps

1. Identify hot paths in `SerialPort` event translation and `lib/src/platform/*_impl.dart`.
2. Minimize allocations in frequent paths (small payload maps, bounded copies, reusable buffers where safe).
3. Keep stream listeners non-blocking and avoid heavy work inside event callbacks.
4. Validate timeout behavior and backpressure handling under bursty or partial serial input.
5. Confirm behavior remains consistent across Windows/macOS/MethodChannel and web when applicable.

## Pitfalls

- Do not trade correctness for throughput.
- Do not introduce busy loops without bounded delays or cancellation.
- Do not change payload contracts (`type`, `data`, `message`, `portName`) in optimization refactors.
