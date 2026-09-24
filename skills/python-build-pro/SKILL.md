---
name: python-build-pro
description: Build, bundle, and protect Python Desktop applications (PySide6/PyQt/Tkinter/CLI) into standalone executables via PyInstaller, Nuitka, and Cython.
---

# Python Desktop Build, Packaging & Cython Protection Guide (`python-build-pro`)

Standardized build pipeline for Python Desktop applications on Windows using PyInstaller, Nuitka, or Cython compilation.

## Compiler Comparison

| Feature | PyInstaller | Nuitka |
| :--- | :--- | :--- |
| **Build Speed** | Fast | Slower (Full C++ compilation) |
| **Execution Performance** | Standard CPython | Faster native speed |
| **Reverse Engineering Protection** | Basic (.pyc in archive) | Strong (Compiled native machine code) |
| **C Compiler Requirement** | Not required | Required (MSVC/MinGW64) |
| **Dead Code Elimination** | Manual `--exclude-module` | Automatic tree-shaking |

---

## 5-Step Build & Packaging Pipeline

### 1. Isolated Virtual Environment (.venv)
```cmd
if not exist .venv python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt
```

### 2. Install Compiler
```cmd
.venv\Scripts\python.exe -m pip install pyinstaller nuitka
```

### 3a. Build via PyInstaller
```cmd
.venv\Scripts\python.exe -s -m PyInstaller ^
    --name "<AppName>" --noconfirm --onedir --windowed ^
    --distpath "build_pyinstall" ^
    --icon "assets\icon.ico" ^
    --add-data "assets;assets/" ^
    --exclude-module tkinter --exclude-module matplotlib --exclude-module numpy ^
    main.py
```

### 3b. Build via Nuitka
```cmd
.venv\Scripts\python.exe -m nuitka ^
    --standalone --assume-yes-for-downloads ^
    --output-dir="build_nuitka" ^
    --output-filename="<AppName>.exe" ^
    --windows-console-mode=disable ^
    --windows-icon-from-ico="assets\icon.ico" ^
    --enable-plugin=pyside6 ^
    --include-data-dir=assets=assets ^
    main.py
```

### 4. Copy Assets & Docs
Copy config templates, README, and licenses adjacent to `.exe` output. Never copy personal credentials or hardcoded developer paths into release distributions.

### 5. Cleanup Temporary Artifacts
```cmd
if exist build rmdir /s /q build
if exist <AppName>.spec del /q "<AppName>.spec"
```

---

## Cython Source Code Protection (`.py` -> `.pyd` / `.so`)

1. Copy source to isolated staging directory.
2. Install `cython`, `setuptools`, `wheel`.
3. Create `setup.py` with `Extension` entries for module `.py` files.
4. Execute `python setup.py build_ext --inplace`.
5. Remove intermediate `.c` and `.py` files, retaining `.pyd` binaries.
