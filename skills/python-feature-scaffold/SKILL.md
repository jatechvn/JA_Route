---
name: python-feature-scaffold
description: Scaffolds new service modules, QThread/QRunnable background workers, and UI tabs for Python PySide6/PyQt desktop tools following the modules/ pattern.
---

# Python Feature Scaffold Skill

Generates modular architecture boilerplate for PySide6/PyQt desktop applications.

## Workflow

1. **Verify Requirements**: Identify module capability (e.g. `file_sync`, `crypto_engine`) and UI requirements (tab vs background service).
2. **Scaffold Service**: Create `modules/<capability_name>.py`:
   - `QThread` / `QRunnable` with progress & completion signals (`Signal(str)`, `Signal(bool, str)`).
   - Clean separation of business logic from GUI widgets.
3. **Wire Logic**: Register service into coordinator `modules/logic.py`.
4. **UI Tab (Optional)**: Add view section in `modules/ui.py` matching existing design tokens.
5. **Summary**: Provide file map and integration points.
