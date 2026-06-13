<!-- Based on: https://github.com/github/awesome-copilot/blob/main/skills/copilot-instructions-blueprint-generator/SKILL.md -->
---
name: copilot-instructions-blueprint-generator
description: 'Blueprint generator for creating comprehensive copilot-instructions.md files aligned with project standards and architecture.'
---

# Copilot Instructions Blueprint Generator

Generate and maintain `.github/copilot-instructions.md` by:

1. Detecting language/framework versions from project files.
2. Identifying architecture boundaries from source layout.
3. Extracting established coding/testing/error-handling patterns.
4. Producing concise, enforceable instructions tailored to the repository.

## Rules

- Never invent stack details not present in the repository.
- Prioritize consistency with existing code over generic best practices.
- Keep instructions actionable and specific to this project.
