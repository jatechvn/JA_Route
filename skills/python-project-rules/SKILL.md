---
name: python-project-rules
description: Enforces Senior Python Developer standards, PEP 8, type hints, safe resource handling, and packaged application frozen path safety.
---

# Python Project Engineering Rules

Core architectural guidelines and constraints for Python development.

## Mandatory Constraints

1. **Virtual Environment Discipline**:
   - Always operate within project `.venv`. Never install packages globally.
   - Verify license and active maintenance before adding packages to `requirements.txt`.

2. **Error Handling**:
   - Never use bare `except:`. Always specify concrete exception types.
   - Never swallow exceptions with empty `pass`. Always log or re-raise.

3. **Type Discipline & Clean Code**:
   - Add type hints to public function signatures.
   - No mutable default arguments (`def f(x=None):` instead of `def f(x=[]):`).
   - Widget tree nesting must not exceed 4 levels.

4. **Packaged Binary Path Safety**:
   - Never use `os.getcwd()` to resolve config/logs in production. Resolve base paths via `sys.executable` when `getattr(sys, "frozen", False)` is true.
   - Never hardcode personal paths or secrets into release code.
