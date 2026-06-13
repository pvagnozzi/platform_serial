<!-- Based on: https://github.com/github/awesome-copilot/blob/main/instructions/dart-n-flutter.instructions.md -->
---
description: 'Instructions for writing Dart and Flutter code following official recommendations.'
applyTo: '**/*.dart'
---

# Dart & Flutter Guidance

- Follow Effective Dart naming and formatting conventions.
- Keep APIs concise, predictable, and type-safe.
- Prefer async/await over raw Future chaining unless a pipeline is clearer.
- Keep widgets and UI glue thin; put logic into dedicated model/service layers.
- Preserve immutable model patterns (`copyWith`, value equality) used in this repository.
- Keep platform-agnostic contracts in `lib/src/contracts` and `lib/src/models`.
- Keep cross-platform behavior consistent by routing through `SerialPlatformInterface`.
