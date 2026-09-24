---
name: python-cleaner
description: Automatically cleans, formats, and optimizes Python source code via ruff, black, isort, flake8, or mypy. Use when cleaning code, fixing linter errors, or refactoring.
---

# Python Cleaner Skill

Cleans, standardizes, and optimizes Python source code across projects.

## Workflow

1. **Toolchain Detection**: Check `pyproject.toml` / `requirements-dev.txt`:
   - `ruff` present (default) $\rightarrow$ `ruff check --fix .` and `ruff format .`
   - `black` present $\rightarrow$ `black .`
   - `isort` present $\rightarrow$ `isort .`
   - `mypy` present $\rightarrow$ `mypy .`
2. **Analyze**: Identify unused imports, undefined variables, bare `except:`, and mutable default arguments.
3. **Format & Auto-fix**: Apply automatic corrections and format style.
4. **Manual Polish**: Resolve remaining type annotations or exception specificity without blanket `# noqa` suppressions.
5. **Verify**: Ensure zero syntax or runtime import errors.
