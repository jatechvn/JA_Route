---
name: python-debugger
description: Hypothesis-driven root-cause debugging skill for Python. Use for complex, silent, or persistent Python runtime errors.
---

# Python Debugger Skill (Hypothesis-Driven)

Systematic root-cause diagnosis for Python applications avoiding guesswork edits.

## Workflow

1. **Traceback Analysis**: Read traceback bottom-up. Identify root-cause frame belonging to user code rather than third-party packages.
2. **Formulate Hypotheses**: State at least 2 distinct root-cause hypotheses before modifying files.
3. **Targeted Fix**: Apply minimal diff based on primary hypothesis.
4. **Assume-Wrong Rule**: If user reports fix failure, discard previous approach and pivot immediately to hypothesis #2.
5. **Defensive Hardening**: Guard against `None` values, missing environment configs, and packaged binary path issues (`sys.executable` vs `os.getcwd()`).
