---
name: dart-cleaner
description: Skill for automatically cleaning up, formatting, and optimizing Dart/Flutter source code. Activates when the user wants to clean up code, fix linter errors, or refactor code.
---

# Dart Cleaner Skill

This skill helps clean up, standardize, and optimize the source code of the user's Flutter/Dart project.

## Execution Process (For Agent)
1. **Analyze:** Run `dart analyze` or `flutter analyze` to detect warnings (linter warnings, unused imports, missing const...).
2. **Format:** Run `dart format .` to automatically format the code according to Dart standards.
3. **Auto-Fix:** Run `dart fix --apply` to automatically fix linter errors that can be auto-fixed.
4. **Manual Refactor (If needed):** Based on analyze results that couldn't be auto-fixed, use code edit tools to fix the remaining issues (e.g., adding the `const` keyword, removing redundant code).
5. **Report:** List the changes made and suggest the user review the source code.
