---
name: test-generation-matrix
description: Generate and maintain unit, integration, e2e, good/bad path, and edge-case tests for platform_serial.
---

# Test Generation Matrix

Use this skill to generate tests from acceptance criteria or code changes.

## Coverage matrix

- **Unit tests**: model validation, API contracts, error translation, and stream behavior with mocks.
- **Integration tests**: `SerialManager` + `SerialPort` interaction and lifecycle behavior.
- **E2E tests**: realistic communication flows, recovery, and stability assumptions.
- **Good path**: expected payloads and normal lifecycle transitions.
- **Bad path**: invalid input, unsupported operations, and platform errors.
- **Edge cases**: zero-length reads, timeout boundaries, double-close/open, partial frames.

## Rules

- Prefer deterministic mocks/fakes over hardware dependencies in the default suite.
- Keep tests close to behavior contracts and platform payload schema.
- Reuse existing test patterns in `test/unit`, `test/integration`, and `test/e2e`.
