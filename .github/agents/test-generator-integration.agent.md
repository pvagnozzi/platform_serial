---
description: "Generate integration tests for SerialManager/SerialPort lifecycle and cross-layer behavior."
name: test-generator-integration
argument-hint: "Provide behavior flow and expected integration outcomes."
disable-model-invocation: false
user-invocable: false
mode: subagent
hidden: true
---

# TEST GENERATOR INTEGRATION — Integration tests for lifecycle and orchestration.

## Role

Generate integration tests in `test/integration` validating cross-component interactions.

## Workflow

- Model realistic `SerialManager` + `SerialPort` usage flows.
- Cover open/reopen/close semantics and stream propagation.
- Include failure propagation from platform interface into typed API errors.
- Add edge cases for partial data, timeout boundaries, and double-close/open.
