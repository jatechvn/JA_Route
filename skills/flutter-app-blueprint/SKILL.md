---
name: flutter-app-blueprint
description: Guidelines and architecture specifications for structuring a modular Flutter desktop application, including FFI native core bridges, version management, license key integration, FVM setup, and setup configs. Single source of truth covering all 4 project variants (key/nokey × fvm/no-fvm) — ask the user which options apply before scaffolding.
---

# Flutter Application Blueprint & Architecture Guide

This document specifies the folder structure, standards, and architecture for a Flutter Desktop project (Windows/macOS/Linux). It serves as the **single source of truth** for every project variant — there are no longer 4 separate template files.

## 🔀 Activation Flow & Variant Selection (For Agent)

Before scaffolding a new project or applying this blueprint, the Agent MUST ask the user the following 2 questions (skip any question the user has already answered clearly in their request):

1. **"Does this project integrate a License Key (JA Key Creator)?"** → If YES, apply the additional content in **[Appendix A — License Key](#-appendix-a--license-key-integration-ja-key-creator)** on top of the baseline below.
2. **"Does this project use FVM (Flutter Version Management) to pin the Flutter version?"** → If YES, apply the additional content in **[Appendix B — FVM](#-appendix-b--fvm-integration-flutter-version-management)** on top of the baseline below.
3. **"Does this project need to build for Android and/or iOS?"** → If YES for Android, apply **[Appendix C — Android](#-appendix-c--target-android)** as well. If YES for iOS, apply **[Appendix D — iOS](#-appendix-d--target-ios)** as well. These two appendices are independent of each other and independent of Appendix A/B — they can be combined freely (e.g., License Key + building for both Android and iOS).

The content from the start of the file through the end of the "📝 Logging Strategy & Configuration" section is the **common baseline** (equivalent to the `nokey` variant + no FVM + Desktop-only for Windows/macOS/Linux), and applies to EVERY project regardless of the choices above. The four appendices at the end of the file describe only the **differences (delta)** to add on top — they do not repeat the entire baseline. Combining the appendices as needed will produce exactly the desired project variant.

## 📂 Project Structure Blueprint (Baseline)

```text
MyProject/
├── lib/
│   ├── main.dart              # Program entry point
│   └── modules/               # Core application modules
│       ├── ui/                # User Interface package
│       │   ├── main_window.dart   # Main application window widget
│       │   ├── styles.dart        # Theme configuration and styling
│       │   └── dialogs.dart       # Optional dialog widgets
│       ├── native/            # Hybrid Engine Core for OS-specific performance
│       │   ├── win_core.dart      # Windows optimization (Calls Win32 API, DLL C++ via FFI)
│       │   ├── mac_core.dart      # macOS optimization (Calls dylib via FFI)
│       │   └── linux_core.dart    # Linux optimization (Calls compiled .so binary via FFI)
│       ├── native_bridge.dart     # Dynamic routing bridge connecting Business Logic and native Core
│       ├── logic.dart             # Core business logic (calls via native_bridge.dart)
│       ├── utils.dart             # Shared utility helper functions
│       ├── constants.dart         # Global constants (appId, appName, appVersion)
│       ├── logger_config.dart     # Centralized logger dispatcher (Debug vs Release)
│       ├── logger_debug.dart      # Verbose logging (7-day retention)
│       └── logger_release.dart    # Basic logging (30-day retention)
│
├── run.bat                    # Rapid startup script on Windows (runs flutter run -d windows)
├── run.sh                     # Rapid startup script on macOS/Linux (runs flutter run)
├── build.bat                  # Release build script on Windows (compiles & creates .Release.lnk shortcut)
├── build.sh                   # Release build script on macOS/Linux (compiles & creates Release symlink)
├── .Release.lnk               # (Auto-generated) Shortcut to the Windows Release folder
├── pubspec.yaml               # Required dependencies list (used with flutter pub get)
├── config.ini                 # Simple configuration file (INI section-based)
├── config.json                # Advanced structured configuration file (JSON format)
├── .gitignore                 # Git ignore file configuration
├── README.md                  # Main documentation in English (Repository landing page)
├── LICENSE                    # Software license agreement (MIT, Apache, etc.)
├── ABOUT.txt                  # Project details card used for GitHub repository description
├── git_push.bat               # Windows batch script to quickly push code to GitHub
│
├── i18n/                      # Internationalization directory (Multi-language READMEs)
│   ├── README.vi.md           # Vietnamese translation (Tiếng Việt)
│   └── README.zh-CN.md       # Chinese translation (简体中文)
│
├── logs/                      # Application operation logs
│   └── yyyy-mm-dd.log         # Daily log file (errors, system info, debug)
│
└── assets/                    # Static application assets
    ├── images/
    ├── sounds/
    ├── fonts/
    ├── models/
    ├── presets/
    ├── data/
    └── temp/
```

## 🧩 Architectural Recommendation: Modular Logic

Do not clutter all business logic in a single huge `logic.dart` file. As the project gains features, divide them into functional modules to ensure testability and prevent bug propagation.

In Dart, there is no `__init__.py` equivalent. Instead, use **barrel exports** — a single file that re-exports public APIs from a directory (e.g., `modules.dart` that exports sub-modules).

Example:

```text
lib/modules/
├── ui/                   # Decoupled UI logic package
│   ├── main_window.dart
│   └── styles.dart
├── build_info.dart       # CLI flags parser, debug mode indicator & timestamp
├── native/               # Native Core Engine for cross-platform optimizations
│   ├── win_core.dart
│   ├── mac_core.dart
│   └── linux_core.dart
├── native_bridge.dart    # OS detection and platform-specific routing bridge
├── logic.dart            # Main coordinator logic
├── file_service.dart     # Disk I/O, file paths, exports/imports
├── api_client.dart       # HTTP requests / API integrations
└── utils.dart            # Shared helper functions
```

Optional barrel export file (`lib/modules/modules.dart`):

```dart
export 'logic.dart';
export 'file_service.dart';
export 'api_client.dart';
export 'utils.dart';
export 'constants.dart';
export 'native_bridge.dart';
```

**Rule:** Keep tasks atomic. A file should have a single responsibility.

## 🌿 Standard Git & .gitignore Configuration

The `.gitignore` file should contain the following basic rules:

```ini
# Flutter/Dart
.dart_tool/
.packages
build/

# Native OS binaries (C++/Rust compiled cores via FFI)
lib/modules/native/*.dll
lib/modules/native/*.so
lib/modules/native/*.dylib

# Platform build outputs
windows/flutter/ephemeral/
macos/Flutter/ephemeral/
linux/flutter/ephemeral/

# Logs and temporary files
logs/
*.log
assets/temp/

# Ignore docs folder contents, EXCEPT docs/screenshots/ (for README images)
docs/*
!docs/
!docs/screenshots/
!docs/screenshots/*

# Local IDE / OS files
.vscode/
.idea/
.DS_Store
Thumbs.db

# Generated files
*.g.dart
*.freezed.dart

# Personal config - uncomment if config contains secrets/tokens/keys
# config.ini
config.json

# Build/packaging output (regenerated by dart-build-pro, not source)
dist/
dist_pack/

# Claude Code project-local tooling (skills, agent config, runtime locks)
.claude/
```

If you manage multiple templates, we suggest using a single `dart-template` repository with dedicated branches:

```bash
git checkout main        # Basic nokey
git checkout nokey-fvm   # Nokey + FVM
git checkout key         # Key/License
git checkout key-fvm     # Key/License + FVM
```

When instantiating a new project:

```bash
git clone <template-url> my-new-project
cd my-new-project
git checkout main
git init
git add .
git commit -m "Initial commit from nokey template"
```

Batch script to automatically initialize and push to GitHub (`git_push.bat`):

```bat
@echo off
cd /d %~dp0

set /p remote_url="Enter GitHub repository URL: "
set /p commit_msg="Enter commit message (default 'Update project'): "
if "%commit_msg%"=="" set commit_msg=Update project

if not exist ".git" (
    git init
    git branch -M main
)

git add .
git commit -m "%commit_msg%"
git remote remove origin 2>nul
git remote add origin "%remote_url%"
git push -u origin main

pause
```

## 🎯 Default Dart/Flutter System

- The system defaults to Flutter 3.x / Dart 3.x for run and build targets.
- On Windows, verify `flutter --version` points to a Flutter 3.x installation in your PATH.
- This sample configuration installs dependencies globally on the system-wide Flutter SDK (no FVM).

## 💡 Windows Taskbar Icon Configuration (AppUserModelID)

Flutter desktop on Windows uses a native C++ runner located at `windows/runner/main.cpp` to bootstrap the application window. Unlike Python/PySide6, there is no need to call `ctypes` or manually set an `AppUserModelID` — Flutter handles the window creation and taskbar identity natively through the Windows runner.

To customize the application icon displayed on the Windows taskbar and title bar:

1. Replace the icon file at `windows/runner/resources/app_icon.ico` with your custom `.ico` file.
2. The `AppUserModelID` can be set in `windows/runner/main.cpp` if needed:

```cpp
// windows/runner/main.cpp (auto-generated by Flutter)
// The AppUserModelID is derived from your application's package name.
// To customize, modify the following line in the Flutter-generated runner:
// ::SetCurrentProcessExplicitAppUserModelID(L"com.example.my_app");
```

3. For most Flutter desktop apps, the default behavior is sufficient. The window title is set programmatically in Dart:

```dart
// In MaterialApp or via the platform window title
MaterialApp(
  title: '$appName  v$appVersion',
  // ...
)
```

## 🪟 Windows Native Theme Backdrop (Acrylic/Mica)

Behind the translucent color layer at the Flutter level (`theme.sidebarBg`/`theme.cardBg` — see also skill `flutter-project-rules` rule 7) there is a **mandatory NATIVE layer** required for the "see-through/blur" effect to actually render: the Win32 window itself (`windows/runner/win32_window.cpp`) must enable the DWM composition attribute. Without this native layer, every `Colors.transparent`/`BackdropFilter` in Flutter will only show the OS's black/default background — the desktop/windows behind it will not show through.

### 1. Separate Theme Files for Win10 and Win11

Windows 10 and Windows 11 use two different DWM mechanisms — they do NOT share a single API:

```text
windows/runner/
├── theme_win10.cpp   # ApplyThemeWin10(hwnd, is_dark)
└── theme_win11.cpp   # ApplyThemeWin11(hwnd, is_dark, is_startup)
```

- **`ApplyThemeWin10`**: uses the undocumented `SetWindowCompositionAttribute` API (loaded via `GetProcAddress` from `user32.dll`) with `ACCENT_ENABLE_BLURBEHIND`, manually sets an ABGR-format tint color + alpha (~`0x66` ≈ 40%) that differs between dark/light, plus `DwmSetWindowAttribute` attribute `19`/`20` to enable the dark titlebar (Win10's "Aero Blur" is weaker than Win11's real Acrylic, so the Flutter-level background opacity needs to be higher to compensate — see section 3).
- **`ApplyThemeWin11`**: simpler — it only needs `DwmSetWindowAttribute` attribute `38` (`DWMWA_SYSTEMBACKDROP_TYPE`) = `3` (`DWMSBT_TRANSIENTWINDOW`, equivalent to real Acrylic), called once at initialization (`is_startup`), plus attribute `20` for the dark titlebar. No undocumented API is required.
- The routing that selects the correct file based on OS lives in `win32_window.cpp::UpdateTheme()`, using `IsWindows11OrGreater()`.

### 2. ⚠️ Native Theme Syncs with the OPERATING SYSTEM, Not Automatically with the In-App Toggle Button

`UpdateTheme()` is only called by the native runner in 2 places: (1) when the window is created, and (2) when Windows sends the `WM_DWMCOLORIZATIONCOLORCHANGED` message — i.e., when the USER changes Dark/Light Mode in **Windows Settings**, not inside the app. This function reads the registry directly (`AppsUseLightTheme`) to decide the tint, completely independent of Dart state.

**Confirmed existing gap (not yet fixed in this blueprint's current baseline)**: the in-app "Toggle Theme" button only changes `_isDark` + calls `notifyListeners()` at the Flutter level — it does NOT call back into native code to re-apply the Acrylic tint. Consequence: if the OS is in Light Mode and the user taps Toggle Theme to switch to Dark inside the app, the Flutter widgets switch to dark colors immediately, but the native blur/tint layer behind the window is still set for Light — producing a tone mismatch/"unusual gray haze" between the content and the background, which is easily mistaken for a UI bug when debugging from screenshots (especially over remote desktop, where Acrylic already renders less reliably than on a physical machine).

- **When scaffolding a new app that has an in-app theme toggle button**: you MUST bridge through a `MethodChannel` to call `ApplyThemeWin10`/`ApplyThemeWin11` again (or re-call `UpdateTheme`) every time `toggleTheme()` runs in Dart, instead of leaving it as a `// TODO: call MethodChannel` comment, as commonly seen in a freshly scaffolded `styles.dart`.
- If there isn't time to build this bridge right away, you MUST explicitly document the limitation "In-app Toggle Theme does not sync the native backdrop" in that app's README/CHANGELOG — to avoid wasted debugging effort when someone (including an Agent in a later session) sees the tone mismatch and mistakes it for a new bug.

### 3. Flutter Color Tokens Must Distinguish Win10/Win11, Not Share a Single Opacity

Because the native mechanisms differ (Win10's "Aero Blur" is less transparent than Win11's real Acrylic), the translucent color tokens at the Flutter level must have opacity tuned separately per OS — here is a real, verified example (`lib/modules/ui/styles_win10.dart` / `styles_win11.dart`):

```dart
// Win10: needs HIGHER opacity to show clearly against the Aero Blur background (weaker than real Acrylic)
Color getWin10SidebarBg(bool isDark) =>
    isDark ? const Color(0xB31E1E1E) : const Color(0xB3F0F0F0); // 70% opacity

// Win11: uses LOWER opacity so the real Acrylic can "bleed through" nicely
Color getWin11SidebarBg(bool isDark) =>
    isDark ? const Color(0x661E1E1E) : const Color(0x66F0F0F0); // 40% opacity
```

`ThemeProvider` routes through the `isWin11` flag (detected by parsing the build number from `Platform.operatingSystemVersion`, where `>= 22000` means Win11) to pick the correct value pair — every new translucent surface added later (sidebar, card, main content, etc.) should have its own separate Win10/Win11 getter pair following this exact pattern, rather than using a single shared alpha constant for both OSes.

## 🔢 Version Management

Every project must declare its version in `lib/modules/constants.dart` so that:
- **JA Auto Git** can auto-detect it and display it in the **Version** column.
- The **Release Manager** can auto-fill the tag name (e.g. `v1.2.0`).
- The application can expose its version at runtime.

### 1. Declare version in `lib/modules/constants.dart`

```dart
// lib/modules/constants.dart

const String appVersion = '1.0.0'; // ← Bump this before every release
```

### 2. Use it in `lib/main.dart`

```dart
import 'package:my_app/modules/constants.dart';

const String appId = 'YOUR_APP_ID';
const String appName = 'Your App Display Name';
// appVersion is imported from constants.dart — no need to redeclare
```

### 3. Display version in the UI (optional)

```dart
// e.g., in AppBar title
AppBar(title: Text('$appName  v$appVersion'))
```

### 4. Version bump workflow (before every push)

Follow **Semantic Versioning** (`MAJOR.MINOR.PATCH`):

| Change type | Action | Example |
|---|---|---|
| Bug fix / tiny tweak | Bump PATCH | `1.0.0` → `1.0.1` |
| New feature (backward-compatible) | Bump MINOR | `1.0.1` → `1.1.0` |
| Breaking change / major rewrite | Bump MAJOR | `1.1.0` → `2.0.0` |

**Before committing + pushing:**

1. Open `lib/modules/constants.dart` and bump `appVersion`.
2. Sync `pubspec.yaml → version: x.y.z` to match (used by Flutter build system).
3. Commit normally via JA Auto Git (auto-changelog will record what changed).
4. Optionally push a GitHub Release via the **🚀 Release** button in JA Auto Git.

### 5. Auto-detection by JA Auto Git

JA Auto Git scans the following files in priority order to detect a project's version:

```
1. pubspec.yaml           →  version: x.y.z
2. package.json           →  "version": "x.y.z"
3. pyproject.toml         →  version = "x.y.z"
4. setup.cfg              →  version = x.y.z
5. setup.py               →  version="x.y.z"
6. *.csproj               →  <Version>x.y.z</Version>
7. constants.dart/version.dart → appVersion = 'x.y.z'
8. constants.py/version.py → APP_VERSION = "x.y.z"
9. ABOUT.txt              →  Version : x.y.z
10. Latest Git tag         →  vx.y.z
```

Keeping `appVersion` in `constants.dart` ensures automatic detection (step 7), and syncing `pubspec.yaml` ensures detection at the highest priority (step 1).

## 📝 Project Information Card (ABOUT.txt)

The `ABOUT.txt` file acts as the project metadata card, which is parsed by `JA Auto Git` to automatically populate the repository's 'About' section on GitHub.

Structure format:

```text
========================================================================
                       PROJECT INFORMATION CARD
========================================================================
Project Name : <Project_Name>
Tech Stack   : Flutter 3.x / Dart 3.x
Managed By   : JA Auto Git
Website      : https://jatechvn.github.io/
------------------------------------------------------------------------
Description  : <A_Concise_About_Description_For_GitHub>
========================================================================
```

Note:
- The line starting with `Description  :` will be automatically extracted by `JA Auto Git` as the repository description.
- If you format the file as a plain-text description, the first non-empty line will be used as a fallback.

## 🧩 Cross-Platform Native Core Bridge (Hybrid Engine)

To support low-level native performance optimizations (C++, assembly, OS-specific APIs) across Windows, macOS, and Linux without cluttering the business logic:

### 1. Dynamic Router (`lib/modules/native_bridge.dart`)

```dart
// lib/modules/native_bridge.dart
import 'dart:io' show Platform;
import 'package:logging/logging.dart';
import 'native/win_core.dart';
import 'native/mac_core.dart';
import 'native/linux_core.dart';

final _logger = Logger('NativeBridge');

abstract class NativeEngine {
  dynamic heavyCompute(dynamic dataInput);
}

class NativeBridge {
  final String osName;
  NativeEngine? engine;

  NativeBridge() : osName = Platform.operatingSystem {
    _initializeEngine();
  }

  /// Dynamically initializes OS-specific optimized engine
  void _initializeEngine() {
    try {
      if (Platform.isWindows) {
        engine = WindowsNativeEngine();
      } else if (Platform.isMacOS) {
        engine = MacNativeEngine();
      } else if (Platform.isLinux) {
        engine = LinuxNativeEngine();
      } else {
        _logger.warning('[BRIDGE] OS $osName is not supported by Hybrid Core. Using fallback.');
      }
    } catch (e) {
      _logger.severe('[BRIDGE] Failed to initialize engine for $osName: $e');
    }
  }

  /// Executes low-level native calls if available
  dynamic executeHeavyTask(dynamic dataInput) {
    if (engine != null) {
      return engine!.heavyCompute(dataInput);
    }
    return _pureDartFallback(dataInput);
  }

  /// Standard Dart fallback logic for maximum compatibility
  dynamic _pureDartFallback(dynamic dataInput) {
    _logger.info('[BRIDGE] Processing using pure Dart algorithm (slower).');
    // Fallback business logic goes here...
    return dataInput;
  }
}

// Singleton instance to be shared across modules
final nativeAgent = NativeBridge();
```

### 2. Windows Optimized Engine (`lib/modules/native/win_core.dart`)

```dart
// lib/modules/native/win_core.dart
import 'dart:ffi';
import 'dart:io';
import '../native_bridge.dart';

class WindowsNativeEngine implements NativeEngine {
  DynamicLibrary? _dll;

  WindowsNativeEngine() {
    _loadNativeLibrary();
  }

  /// Loads C++/Rust compiled DLL for Windows high-performance computation
  void _loadNativeLibrary() {
    final dllPath = '${Directory.current.path}/lib/modules/native/core_x64.dll';
    if (File(dllPath).existsSync()) {
      try {
        _dll = DynamicLibrary.open(dllPath);
      } catch (_) {}
    }
  }

  @override
  dynamic heavyCompute(dynamic dataInput) {
    if (_dll != null) {
      // If high-performance C++ DLL is loaded, delegate execution
      // return _dll!.lookupFunction<...>(...);
    }

    // Windows-specific fallback (e.g., calling platform channels or system commands)
    return 'Windows Optimized Result';
  }
}
```

### 3. macOS Optimized Engine (`lib/modules/native/mac_core.dart`)

```dart
// lib/modules/native/mac_core.dart
import 'dart:ffi';
import 'dart:io';
import '../native_bridge.dart';

class MacNativeEngine implements NativeEngine {
  DynamicLibrary? _dylib;

  MacNativeEngine() {
    _loadNativeLibrary();
  }

  /// Loads C++/Objective-C/Rust compiled dylib for macOS high-performance computation
  void _loadNativeLibrary() {
    final dylibPath = '${Directory.current.path}/lib/modules/native/libcore.dylib';
    if (File(dylibPath).existsSync()) {
      try {
        _dylib = DynamicLibrary.open(dylibPath);
      } catch (_) {}
    }
  }

  @override
  dynamic heavyCompute(dynamic dataInput) {
    if (_dylib != null) {
      // If high-performance C++/Obj-C dylib is loaded, delegate execution
      // return _dylib!.lookupFunction<...>(...);
    }

    // macOS-specific fallback (e.g., calling shell commands or Swift APIs)
    return 'macOS Optimized Result';
  }
}
```

### 4. Linux Optimized Engine (`lib/modules/native/linux_core.dart`)

```dart
// lib/modules/native/linux_core.dart
import 'dart:ffi';
import 'dart:io';
import '../native_bridge.dart';

class LinuxNativeEngine implements NativeEngine {
  DynamicLibrary? _so;

  LinuxNativeEngine() {
    _loadNativeLibrary();
  }

  /// Loads C++/Rust compiled shared object (so) for Linux high-performance computation
  void _loadNativeLibrary() {
    final soPath = '${Directory.current.path}/lib/modules/native/libcore.so';
    if (File(soPath).existsSync()) {
      try {
        _so = DynamicLibrary.open(soPath);
      } catch (_) {}
    }
  }

  @override
  dynamic heavyCompute(dynamic dataInput) {
    if (_so != null) {
      // If high-performance C++ so is loaded, delegate execution
      // return _so!.lookupFunction<...>(...);
    }

    // Linux-specific fallback (e.g., calling bash commands)
    return 'Linux Optimized Result';
  }
}
```

## 🐧 Unix Runtime Scripts (macOS / Linux)

To make the project run on macOS and Linux, include `.sh` UNIX scripts parallel to the Windows `.bat` scripts.

Execution Script (`run.sh`):

```bash
#!/bin/bash
# Move to the directory containing this script
cd "$(dirname "$0")"

# Detect OS to select target desktop platform
OS_NAME="$(uname -s)"
case "$OS_NAME" in
    Darwin*)
        TARGET="macos"
        ;;
    Linux*)
        TARGET="linux"
        ;;
    *)
        TARGET="linux"
        ;;
esac

flutter run -d "$TARGET"
```

## 🚀 Release Build Workflow (build.bat / build.sh)

To package the application for release and create a shortcut pointing to the compiled files in the project root, add the following build scripts:

Release Build Script on Windows (`build_release.bat`):

```bat
@echo off
setlocal enabledelayedexpansion
title Build Release Packager

set WORKSPACE_DIR=%~dp0
cd /d "%WORKSPACE_DIR%"

:: 0. Kill running instances of the app
echo [0/5] Terminating any active app instances...
taskkill /IM MyProject.exe /F 2>nul
timeout /t 1 /nobreak >nul

:: 1. Clear previous distribution folder
echo [1/5] Clearing previous dist/ folder...
if exist "dist" rmdir /s /q "dist"
mkdir "dist"

:: 2. Compile Windows Release App
echo [2/5] Compiling Windows application (Release mode)...
call flutter build windows --release
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

set RELEASE_DIR=build\windows\x64\runner\Release

:: 3. Copy bin, assets, i18n, and docs to build output
echo [3/5] Bundling embedded binaries, assets, and docs...
if exist "bin" xcopy /e /i /y /q "bin" "%RELEASE_DIR%\bin\"
if exist "assets" xcopy /e /i /y /q "assets" "%RELEASE_DIR%\assets\"
if exist "i18n" xcopy /e /i /y /q "i18n" "%RELEASE_DIR%\i18n\"
if exist "ABOUT.txt" copy /y "ABOUT.txt" "%RELEASE_DIR%\" >nul
if exist "README.md" copy /y "README.md" "%RELEASE_DIR%\" >nul
if exist "CHANGELOG.md" copy /y "CHANGELOG.md" "%RELEASE_DIR%\" >nul
if exist "LICENSE" copy /y "LICENSE" "%RELEASE_DIR%\" >nul

:: Create debug.bat for quick debugging
(echo @echo off & echo cd /d %%~dp0 & echo for %%%%i in (*.exe^^^) do ^^^( & echo     start "" "%%%%i" -debug & echo     exit & echo ^^^)) > "%RELEASE_DIR%\debug.bat"

:: Create .Release shortcut in project root
powershell -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%WORKSPACE_DIR%\.Release.lnk'); $s.TargetPath='%WORKSPACE_DIR%\%RELEASE_DIR%'; $s.Save()"

:: 4. Copy to dist/ and create x64 zip
echo [4/5] Copying complete self-contained release to dist/...
xcopy /e /i /y /q "%RELEASE_DIR%\*.*" "dist\"

echo [5/5] Packaging standalone Windows x64 ZIP release wrapped in parent folder...
if exist "dist_pack" rmdir /s /q "dist_pack"
mkdir "dist_pack\MyProject_v1.0.0_Windows_x64"
xcopy /e /i /y /q "dist\*.*" "dist_pack\MyProject_v1.0.0_Windows_x64\"
powershell -Command "Compress-Archive -Path 'dist_pack\*' -DestinationPath 'dist\MyProject_v1.0.0_Windows_x64.zip' -Force"
if exist "dist_pack" rmdir /s /q "dist_pack"

echo [SUCCESS] Release build & packaging complete in dist/
pause
```

Release Build Script on macOS/Linux (`build.sh`):

```bash
#!/bin/bash
cd "$(dirname "$0")"

OS_NAME="$(uname -s)"
case "$OS_NAME" in
    Darwin*)
        TARGET="macos"
        SRC_DIR="build/macos/Build/Products/Release"
        ;;
    *)
        TARGET="linux"
        SRC_DIR="build/linux/x64/release/bundle"
        ;;
esac

echo "[BUILD] Compiling $TARGET desktop application in Release mode..."
flutter build "$TARGET"
if [ $? -ne 0 ]; then
    echo "[ERROR] Build failed!"
    exit 1
fi

echo "[LINK] Creating symlink Release to Release directory..."
rm -rf dist
ln -sfn "$SRC_DIR" Release
echo "[SUCCESS] Release build is complete. Symlink 'Release' created."
```

## ⚙️ Settings, Glassmorphism & Dialog Architecture

> **Note when applying this section:** the sample code below illustrates the general architecture (3 tabs, `SettingsService`/`config.ini`) but uses `withOpacity` (the old, deprecated API) and does not yet have a "legibility floor". When implementing for real, also apply the verified rules from skill `flutter-project-rules` rule 7: use `withValues(alpha:)` instead of `withOpacity`, reuse the existing Win10/Win11-aware color tokens instead of new alpha constants, and you MUST clamp `effectiveBlur = max(blur, 6.0)` when `opacity < 1.0` to avoid overlapping-text-through-transparency issues. The Flutter portion here also depends on the native layer described in the **🪟 Windows Native Theme Backdrop** section above — without that layer, the blur will have nothing behind it to "see through".

All applications built with this architecture must include a standard Settings Dialog containing 3 tabs, custom Glassmorphism blur/opacity sliders with real-time preview, a Restore Defaults button, and full persistence via `config.ini`.

### 1. Settings Service Configuration (`lib/services/settings_service.dart`)

The settings service manages and persists the following properties in `config.ini`:

- `license_author`: Default license author name (default: `'John Alaa'`).
- `max_depth`: Directory scan depth (default: `3`).
- `auto_create_repo`: Automatically create GitHub remote repository (default: `true`).
- `repo_public`: Create repository as PUBLIC by default (default: `false`).
- `bg_blur`: Main window backdrop filter blur sigma (default: `10.0`).
- `bg_opacity`: Main window background opacity percentage (default: `0.6`).
- `dialog_blur`: Popup dialog backdrop filter blur sigma (default: `2.0`).
- `dialog_opacity`: Popup dialog background opacity percentage (default: `0.8`).

### 2. Glassmorphic Popup Dialog (`lib/modules/ui/dialogs.dart` - `GlassDialog`)

`GlassDialog` accepts optional `blurSigma` and `bgOpacity` overrides, falling back to stored settings `dialog_blur` and `dialog_opacity`:

```dart
class GlassDialog extends StatelessWidget {
  final Widget child;
  final String title;
  final double width;
  final double height;
  final bool isDark;
  final double? blurSigma;
  final double? bgOpacity;

  const GlassDialog({
    Key? key,
    required this.child,
    required this.title,
    this.width = 640,
    this.height = 480,
    required this.isDark,
    this.blurSigma,
    this.bgOpacity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final settings = SettingsService.loadSettings();
    final double sigma = blurSigma ?? (settings['dialog_blur'] ?? 2.0);
    final double opacity = bgOpacity ?? (settings['dialog_opacity'] ?? 0.8);
    final enableTransparency = Platform.isWindows && WindowsInfo.isWindows11OrGreater;
    final bg = enableTransparency ? c.bgSecondary.withOpacity(opacity) : c.bgSecondary;
    final border = enableTransparency ? c.borderDefault.withOpacity((opacity * 0.5).clamp(0.1, 0.8)) : c.borderDefault;

    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

### 3. Comprehensive Settings Dialog (`lib/modules/ui/dialogs.dart` - `SettingsDialog`)

The dialog features 3 tabs, in this display order:
1. **⚙️ Advanced Settings (Cài đặt Nâng cao)**:
   - License & Git form defaults (`license_author`, `max_depth`).
   - GitHub push configuration (`remote_base`, `auto_create_repo`, `repo_public`).
   - **Glassmorphism Customization (Collapsed by default via ExpansionTile, Real-time Preview)**:
     - `App Background Blur (Sigma)`: Slider from 0.0 to 30.0 px (`_bgBlur`).
     - `App Background Opacity`: Slider from 10% to 100% (`_bgOpacity`).
     - `Popup Dialog Blur (Sigma)`: Slider from 0.0 to 30.0 px (`_dialogBlur`).
     - `Popup Dialog Opacity`: Slider from 10% to 100% (`_dialogOpacity`).
   - **Footer Action Buttons**:
     - **KHÔI PHỤC MẶC ĐỊNH (RESET DEFAULTS)**: Resets all text fields and sliders to default values instantly (`_resetToDefaults()`).
     - **LƯU CÀI ĐẶT (SAVE SETTINGS)**: Persists modified settings to `config.ini` and closes dialog (`_saveSettings()`).
2. **📖 User Guide (Hướng dẫn sử dụng)**: Complete operational walkthrough & usage guide.
3. **ℹ️ About Application (Giới thiệu ứng dụng)**: Application branding, version card (`appVersion`), developer credits (`John Alaa / JA Tech`), system environment status.

**Default/initial tab is About, not Advanced** — `TabController(length: 3, vsync: this, initialIndex: 2)`. Clicking the header's settings (gear) icon should land the user on branding/version/license first; that's more broadly useful at a glance than jumping straight into blur/opacity sliders, which are a secondary, occasionally-used tweak.

**Dialog size**: prefer sizing `GlassDialog`'s `width`/`height` relative to the main window (e.g. 70% of `MediaQuery.sizeOf(context)` on each axis, computed in the `showSettingsDialog` caller before `showDialog`) rather than a fixed pixel box — a fixed size looks cramped when the window is maximized on a large monitor and oversized on the default small window.

---

## 💾 Saved Presets / Reusable Setup Pattern (`lib/modules/preset_service.dart`)

For any app where the user dials in a non-trivial configuration (a cloned voice + generation settings, an export profile, a connection config...) and wants to name it and reapply it later in one click — a "presets" feature. Establishes the following pattern:

### 1. Storage — files under `<app_dir>/Presets/`, not SharedPreferences

```dart
String get _presetsDir => p.join(getAppDir(), 'Presets');
String get _jsonPath => p.join(_presetsDir, 'presets.json');
```

SharedPreferences on Windows persists to a location tied to the user's profile — outside the app's own folder — which breaks any app built around "copy the whole folder to another machine and it just works" (this app family's core portability story: `python/`, `hf_cache/`, `Output/` all live under the app root for the same reason). A plain JSON file under the app root travels with the folder like everything else.

### 2. Copy referenced files in at save time, don't just store the path

If a preset references an external file (a reference audio clip, an import template...), **copy it into `Presets/<asset-dir>/<presetId>.<ext>`** rather than storing the original path — the preset must stay valid even if the user later moves or deletes the source file they originally picked it from. Delete the copy when the preset is deleted.

### 3. Shared row above the tab bar, not duplicated per tab

When presets can apply to more than one mode/tab (e.g. Voice Clone vs. Voice Design), put the row *between the header and the `TabBar`* — outside `TabBarView` — so one preset list serves every tab instead of being duplicated per tab. Applying a preset from the "wrong" tab should switch `_tabController.index` to the correct one as part of applying it.

### 4. Save dialog: pre-fill + pre-select a sensible default name

```dart
final controller = TextEditingController(text: suggestedName)
  ..selection = TextSelection(baseOffset: 0, extentOffset: suggestedName.length);
```

Suggest the referenced file's basename (`p.basenameWithoutExtension(refAudioPath)`) as the default preset name, with the text **pre-selected** — accepting the default is one Enter/click, replacing it is one keystroke (typing over a selection), rather than requiring the user to select-all or backspace manually.

### 5. Gate the Save action on "is there anything to save yet"

```dart
bool get _canSavePreset =>
    _tabController.index == 1 || (_refAudioPath != null && _refAudioPath!.isNotEmpty);
```

Disable the Save button until the current mode has something meaningful captured (a reference file picked, for a mode that requires one). A mode with no required input (attributes default to "Auto" rather than needing a file) is never gated. Remember to add a `_tabController.addListener` that calls `setState` so this recomputes on tab switch, not just on the field that changes within a tab.

### 6. List UI: a scrollable vertical picker, not a horizontal chip row — once past a handful

A row of horizontally-scrolling chips works for 2–3 saved items; past that it overflows the window width and names truncate illegibly. Don't build the chip row and plan to fix it later — go straight to: a single "Browse presets (N)" button that opens a `GlassDialog` containing a bounded-height `ListView.separated` (same row layout as the History panel: leading icon, name, relative-time trailing label, trailing delete `IconButton`). Selecting a row closes the dialog and applies; deleting (behind its own confirm dialog) keeps the picker open so the user can keep browsing/pruning.

---

## 🏷️ Debug Stamp & Versioning (`lib/modules/build_info.dart`)

To display diagnostic info when running in development/debug mode, applications implement the `BuildInfo` configuration module. This parses custom CLI flags (such as `-debug` or `--debug`) and generates a build timestamp using the compilation date.

### 1. Build Info Module (`lib/modules/build_info.dart`)
```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'constants.dart';

class BuildInfo {
  static bool isCliDebug = false;
  static final String debugTimestamp = _generateBuildTimestamp();

  static String _generateBuildTimestamp() {
    try {
      final exeFile = File(Platform.resolvedExecutable);
      final appSoFile = File('${exeFile.parent.path}${Platform.pathSeparator}data${Platform.pathSeparator}app.so');
      final targetFile = appSoFile.existsSync() ? appSoFile : exeFile;

      if (targetFile.existsSync()) {
        final modified = targetFile.lastModifiedSync();
        return '${modified.year}-${modified.month.toString().padLeft(2, '0')}-${modified.day.toString().padLeft(2, '0')} '
               '${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')}:${modified.second.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return DateTime.now().toString().split('.')[0];
  }

  static bool get isDebug => kDebugMode || isCliDebug;
  static const String version = appVersion;
}
```

### 2. Arg Parsing at Entry Point (`lib/main.dart`)
To pass debug flags, the entry point parses `List<String> args`:
```dart
void main(List<String> args) {
  if (args.contains('-debug') || args.contains('--debug') || args.contains('-d')) {
    BuildInfo.isCliDebug = true;
  }
  runApp(const MyApp());
}
```

### 3. UI Stamp/Badge (`lib/modules/ui/main_window.dart`)
When `BuildInfo.isDebug` is true, show a diagnostic badge in the UI:
```dart
if (BuildInfo.isDebug) ...[
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.amber.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.amber.withOpacity(0.5)),
    ),
    child: Text(
      'DEBUG • v${BuildInfo.version} (${BuildInfo.debugTimestamp})',
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber),
    ),
  ),
]
```

---

## 📝 Logging Strategy & Configuration

The blueprint recommends separating logging strategies for Debug and Release modes:
- **Debug Mode**: Logs everything (Level.ALL), saves logs to `logs/debug_yyyy-mm-dd.log`, and rotates logs older than 7 days.
- **Release Mode**: Logs only important statements (Level.INFO and above), saves logs to `logs/yyyy-mm-dd.log`, and rotates logs older than 30 days.

### 1. Unified Config Bridge (`lib/modules/logger_config.dart`)
```dart
import 'build_info.dart';
import 'logger_release.dart';
import 'logger_debug.dart';

export 'logger_release.dart';
export 'logger_debug.dart';

void setupLogger() {
  if (BuildInfo.isDebug) {
    setupDebugLogger();
  } else {
    setupReleaseLogger();
  }
}

void disposeLogger() {
  if (BuildInfo.isDebug) {
    disposeDebugLogger();
  } else {
    disposeReleaseLogger();
  }
}
```

### 2. Debug Logging Strategy (`lib/modules/logger_debug.dart`)
```dart
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

IOSink? _debugLogSink;

void setupDebugLogger() {
  Logger.root.level = Level.ALL;
  final logDir = Directory(p.join(Directory.current.path, 'logs'));
  if (!logDir.existsSync()) logDir.createSync(recursive: true);

  final now = DateTime.now();
  final logFileName = 'debug_${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}.log';
  _debugLogSink = File(p.join(logDir.path, logFileName)).openWrite(mode: FileMode.append);
  _debugLogSink?.writeln('=== DEBUG LOG SESSION STARTED: ${now.toIso8601String()} ===');

  Logger.root.onRecord.listen((record) {
    final buffer = StringBuffer()
      ..write('[${record.time.toIso8601String()}] [DEBUG] ${record.level.name}: ${record.loggerName} - ${record.message}');
    if (record.error != null) buffer.write('\n  ERROR: ${record.error}');
    if (record.stackTrace != null) buffer.write('\n  STACKTRACE: ${record.stackTrace}');
    final logText = buffer.toString();
    print(logText);
    _debugLogSink?.writeln(logText);
  });
  rotateDebugLogs(logDir);
}

void rotateDebugLogs(Directory logDir) {
  try {
    final limit = DateTime.now().subtract(const Duration(days: 7));
    logDir.listSync().forEach((entity) {
      if (entity is File && entity.path.endsWith('.log')) {
        if (entity.statSync().modified.isBefore(limit)) entity.deleteSync();
      }
    });
  } catch (_) {}
}

void disposeDebugLogger() {
  _debugLogSink?.writeln('=== DEBUG LOG SESSION ENDED ===');
  _debugLogSink?.close();
}
```

### 3. Release Logging Strategy (`lib/modules/logger_release.dart`)
Similar to the debug strategy but sets `Logger.root.level = Level.INFO` and filters records where `record.level < Level.INFO`. The log rotation limit is set to 30 days (`const Duration(days: 30)`).

---

## 🔑 Appendix A — License Key Integration (JA Key Creator)

> **Only applies when the user confirms the project needs a License Key.** This section is ADDED ON TOP of the baseline above (not a replacement).

### A.1 Additions to Project Structure

```text
├── license.key.example              # [KEY] Guide license key sample (committed to Git)
├── license.key                      # [KEY] Actual license key file (ignored via .gitignore, DO NOT commit)
└── lib/modules/
    ├── ja_license_checker.dart      # [KEY] License key validation engine - copied from JA Key Creator
    └── LICENSE_SETUP.md             # [KEY] License integration guide
```

### A.2 Additions to `.gitignore`

```ini
# License keys - DO NOT commit production keys
license.key
```

Always commit a `license.key.example` sample file alongside it so other developers know how to place the license file.

### A.3 Validation Snippet in `lib/main.dart`

```dart
import 'dart:io';
import 'package:my_app/modules/ja_license_checker.dart';

const String appId = 'YOUR_APP_ID';
const String appName = 'Your App Display Name';

void main() {
  final (ok, msg) = checkLicense(appId: appId);
  if (!ok) {
    print('[LICENSE ERROR] $msg');
    exit(1);
  }
  // ... run app
}
```

### A.4 Registering the Application in License Key Manager (`apps.json`)

```json
{
  "id": "YOUR_APP_ID",
  "name": "Your App Display Name"
}
```

Mandatory rules:
- The `id` in the registry must match the `appId` in the code.
- A key issued for App A cannot unlock App B.
- Changing the `appId` requires regenerating a new key.
- If the project uses FVM (Appendix B), FVM only isolates the Flutter SDK version — it has no effect on license logic.

### A.5 License Checker Engine (`lib/modules/ja_license_checker.dart`)

```dart
// lib/modules/ja_license_checker.dart
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// The secret key used for license verification.
/// MUST match the secret key configured in JA Key Creator.
const String _licenseSecret = 'JohnAlaaSecretKey_2026!@#';

/// Checks if a valid license key exists for [appId].
/// Returns a tuple `(isValid, statusMessage)`.
(bool, String) checkLicense({required String appId}) {
  try {
    final keyFile = File('license.key');
    if (!keyFile.existsSync()) {
      return (false, 'File license.key not found. Please place your license key in the application folder.');
    }

    final encodedKey = keyFile.readAsStringSync().trim();
    if (encodedKey.isEmpty) {
      return (false, 'License key is empty.');
    }

    // 1. Decode Base64
    final decodedBytes = base64.decode(encodedKey);
    final raw = utf8.decode(decodedBytes);

    if (!raw.contains('|')) {
      return (false, 'Invalid license key format.');
    }

    final sepIdx = raw.lastIndexOf('|');
    final payload = raw.substring(0, sepIdx);
    final signature = raw.substring(sepIdx + 1);

    // 2. Verify HMAC Signature
    final secretBytes = utf8.encode(_licenseSecret);
    final payloadBytes = utf8.encode(payload);
    final hmac = Hmac(sha256, secretBytes);
    final expectedSig = hmac.convert(payloadBytes).toString();

    if (expectedSig != signature) {
      return (false, 'License signature verification failed (possibly tampered).');
    }

    // 3. XOR Decrypt Payload
    final buffer = StringBuffer();
    for (int i = 0; i < payload.length ~/ 2; i++) {
      final byteVal = int.parse(payload.substring(2 * i, 2 * i + 2), radix: 16);
      final passChar = _licenseSecret.codeUnitAt(i % _licenseSecret.length);
      buffer.writeCharCode(byteVal ^ passChar);
    }
    final decrypted = buffer.toString();

    if (!decrypted.contains(':')) {
      return (false, 'Invalid license content.');
    }

    final parts = decrypted.split(':');
    final expiryDateStr = parts[0];
    final appIdInKey = parts[1];
    final hwidInKey = parts.length > 2 ? parts.sublist(2).join(':') : '';

    // 4. Validate App ID
    if (appIdInKey != appId) {
      return (false, 'License is issued for another application ($appIdInKey).');
    }

    // 5. Validate Expiry Date
    if (expiryDateStr.length != 8) {
      return (false, 'Invalid expiry date in license.');
    }

    final now = DateTime.now();
    final todayStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    if (expiryDateStr.compareTo(todayStr) < 0) {
      final formattedExpiry = '${expiryDateStr.substring(0, 4)}-${expiryDateStr.substring(4, 6)}-${expiryDateStr.substring(6)}';
      return (false, 'License expired on $formattedExpiry.');
    }

    // 6. Validate HWID (if key has HWID bound)
    if (hwidInKey.isNotEmpty) {
      final localHwid = _getLocalHwid();
      if (localHwid != hwidInKey) {
        return (false, 'License is bound to another hardware (HWID: $hwidInKey, Local: $localHwid).');
      }
    }

    final formattedExpiry = '${expiryDateStr.substring(0, 4)}-${expiryDateStr.substring(4, 6)}-${expiryDateStr.substring(6)}';
    return (true, 'License is valid. Expiry date: $formattedExpiry.');
  } catch (e) {
    return (false, 'Failed to verify license: $e');
  }
}

/// Helper method to retrieve system HWID (currently for Windows, macOS, Linux fallbacks).
String _getLocalHwid() {
  try {
    if (Platform.isWindows) {
      final res = Process.runSync('wmic', ['csproduct', 'get', 'uuid']);
      if (res.exitCode == 0) {
        final lines = res.stdout.toString().split('\n');
        if (lines.length > 1) {
          return lines[1].trim();
        }
      }
    } else if (Platform.isMacOS) {
      final res = Process.runSync('system_profiler', ['SPHardwareDataType']);
      if (res.exitCode == 0) {
        for (var line in res.stdout.toString().split('\n')) {
          if (line.contains('Hardware UUID')) {
            return line.split(':').last.trim();
          }
        }
      }
    } else if (Platform.isLinux) {
      final file = File('/var/lib/dbus/machine-id');
      if (file.existsSync()) {
        return file.readAsStringSync().trim();
      }
    }
  } catch (_) {}
  return 'UNKNOWN_HWID';
}
```

### A.6 Setup Instructions (`lib/modules/LICENSE_SETUP.md`)

```markdown
# License Integration Setup Guide

Follow these steps to integrate the JA Key license verification system into your application:

## Step 1: Add Dependencies
Make sure you have `crypto` added to your dependencies in `pubspec.yaml`:
\`\`\`yaml
dependencies:
  flutter:
    sdk: flutter
  crypto: ^3.0.3
\`\`\`
Then run `flutter pub get` (or `fvm flutter pub get` if using FVM).

## Step 2: Add files
Copy `ja_license_checker.dart` into `lib/modules/`.

## Step 3: Implement Check on Startup
Update your `lib/main.dart` entry point to execute `checkLicense` before running the app.

## Step 4: Configure Git Ignores
Add `license.key` to your `.gitignore` file to avoid checking in production keys. You should commit `license.key.example` to let developers know where to place the license key file.
```

---

## 📦 Appendix B — FVM Integration (Flutter Version Management)

> **Only applies when the user confirms the project needs to pin the Flutter version using FVM.** This section is ADDED ON TOP of the baseline above (not a replacement). When applying this appendix, every `flutter ...` command in the baseline (run/build/pub get) must be changed to `fvm flutter ...`.

### B.1 Additions to Project Structure

```text
├── setup_fvm.bat          # Windows script to auto-initialize .fvm and install dependencies
├── setup_fvm.sh           # macOS/Linux script to auto-initialize .fvm and install dependencies
└── .fvm/                  # Local Flutter SDK managed by FVM (DO NOT commit)
```

### B.2 Additions to `.gitignore`

```ini
# FVM - do not commit local Flutter SDK
.fvm/
```

When sharing the project, only commit the source code, `pubspec.yaml`, launch scripts, and `license.key.example` (if Appendix A applies) — do not commit `.fvm/` or the real `license.key`.

### B.3 Manually Initializing `.fvm`

```bat
fvm install 3.27.4
fvm use 3.27.4
fvm flutter pub get
fvm flutter run -d windows
```

### B.4 `setup_fvm.bat` (Windows — Restore Environment)

```bat
@echo off
cd /d %~dp0

where fvm >nul 2>&1
if errorlevel 1 (
    echo [INFO] FVM not found. Installing via dart pub...
    dart pub global activate fvm
)

if not exist ".fvm\flutter_sdk" (
    echo [INFO] Installing Flutter SDK via FVM...
    fvm install 3.27.4
    fvm use 3.27.4
)

call fvm flutter pub get

echo.
echo [OK] .fvm is ready.
pause
```

### B.5 `setup_fvm.sh` (macOS/Linux — Restore Environment)

```bash
#!/bin/bash
cd "$(dirname "$0")"

if ! command -v fvm &> /dev/null; then
    echo "[INFO] FVM not found. Installing via dart pub..."
    dart pub global activate fvm
fi

if [ ! -d ".fvm/flutter_sdk" ]; then
    echo "[INFO] Installing Flutter SDK via FVM..."
    fvm install 3.27.4
    fvm use 3.27.4
fi

fvm flutter pub get

echo -e "\n[OK] FVM environment (.fvm) is ready."
```

### B.6 `run.bat` / `run.sh` (Replaces Baseline Version)

```bat
@echo off
cd /d %~dp0
call fvm flutter run -d windows
```

```bash
#!/bin/bash
cd "$(dirname "$0")"

OS_NAME="$(uname -s)"
case "$OS_NAME" in
    Darwin*) TARGET="macos" ;;
    Linux*)  TARGET="linux" ;;
    *)       TARGET="linux" ;;
esac

fvm flutter run -d "$TARGET"
```

### B.7 `build.bat` / `build.sh` (Replaces Baseline Version)

In the build script (see the "🚀 Release Build Workflow" section in the baseline), change the compile command from `flutter build windows --release` to `call fvm flutter build windows --release` (Windows) or `fvm flutter build "$TARGET"` (macOS/Linux). The packaging/ZIP compression portion stays identical to the baseline.

### B.8 Notes on `git_push.bat`

Add a warning before committing if `.fvm` is detected:

```bat
if exist ".fvm" (
    echo [INFO] .fvm will be excluded from commit if .gitignore is active.
)
```

### B.9 Managing Template Branches (If Using a Shared Template Repo)

```bash
git checkout main        # Basic nokey
git checkout nokey-fvm   # Nokey + FVM
git checkout key         # Key/License
git checkout key-fvm     # Key/License + FVM
```

---

## 📱 Appendix C — Target Android

> **Only applies when the user confirms the project needs to build for Android.** This section is ADDED ON TOP of the baseline (and is compatible with Appendix A/B, if applicable). The actual packaging/build (APK/AAB, release signing) belongs to the dedicated skill **`flutter-mobile-build-pro`** — this appendix only describes the architecture/source additions needed in `lib/modules/`.

### C.1 Additions to Project Structure

```text
├── android/                         # Android platform runner (auto-generated by Flutter)
│   ├── app/
│   │   ├── build.gradle             # applicationId, signingConfigs (release)
│   │   └── src/main/AndroidManifest.xml
│   ├── key.properties.example        # Sample keystore configuration file (safe to commit)
│   └── key.properties                 # Actual file containing keystore path/password (DO NOT commit)
└── lib/modules/native/
    └── android_core.dart            # [NEW] Android optimization (loads libcore.so via dart:ffi, JNI if calling Kotlin/Java APIs is needed)
```

### C.2 Additions to `.gitignore`

```ini
# Android signing — DO NOT commit real keystore config
android/key.properties
android/**/*.jks
android/**/*.keystore
```

### C.3 Android Native Engine (`lib/modules/native/android_core.dart`)

The native `.so` on Android lives inside the APK's `jniLibs/<abi>/`, automatically bundled by Flutter — there is no need to manually resolve a path like on Windows/Linux:

```dart
// lib/modules/native/android_core.dart
import 'dart:ffi';
import 'package:my_app/modules/native_bridge.dart';

class AndroidNativeEngine implements NativeEngine {
  DynamicLibrary? lib;

  AndroidNativeEngine() {
    _loadNativeLibrary();
  }

  void _loadNativeLibrary() {
    /// On Android, the .so is already bundled inside the APK (android/app/src/main/jniLibs/<abi>/libcore.so)
    /// so it only needs to be opened by library name — no absolute path is required.
    try {
      lib = DynamicLibrary.open('libcore.so');
    } catch (_) {
      // Silently fail — fallback will be used
    }
  }

  @override
  dynamic heavyCompute(dynamic dataInput) {
    if (lib != null) {
      // return lib!.lookupFunction<...>(...)(dataInput);
    }
    return 'Android Optimized Result';
  }
}
```

Register the additional Android branch in `native_bridge.dart` (`Platform.isAndroid → AndroidNativeEngine()`).

### C.4 License Checker Notes (If Appendix A Applies)

The `_getLocalHwid()` function in `ja_license_checker.dart` uses `wmic`/`system_profiler`/`/var/lib/dbus/machine-id` — **none of these commands exist on Android**. You need to add a branch that retrieves the device ID using the `device_info_plus` package:

```dart
// Add an Android branch to _getLocalHwid()
if (Platform.isAndroid) {
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  return androidInfo.id; // Android build ID (stable across app reinstalls)
}
```

### C.5 Build & Sign Release

See skill **`flutter-mobile-build-pro`** for the complete workflow: configuring `key.properties`, `signingConfigs` in `android/app/build.gradle`, and the `flutter build apk`/`flutter build appbundle` commands.

---

## 🍎 Appendix D — Target iOS

> **Only applies when the user confirms the project needs to build for iOS.** This section is ADDED ON TOP of the baseline (and is compatible with Appendix A/B/C, if applicable). The actual build/signing belongs to skill **`flutter-mobile-build-pro`**; this appendix only describes the source architecture.

### D.1 Additions to Project Structure

```text
├── ios/                              # iOS platform runner (auto-generated by Flutter, requires macOS + Xcode to build)
│   ├── Runner.xcodeproj              # Signing team ID, provisioning profile configured here
│   └── Runner/Info.plist
└── lib/modules/native/
    └── ios_core.dart                 # [NEW] iOS optimization (FFI via .framework static-link)
```

### D.2 Important Constraint: NO Dynamic-Loading Like Other Platforms

Unlike Windows/macOS/Linux/Android (which load `.dll`/`.dylib`/`.so` flexibly at runtime), **the iOS App Store sandbox prohibits dynamic-loading arbitrary libraries**. The native core (Rust/C/C++) must be **static-linked** into a `.framework` at Xcode build time — it is not possible to `DynamicLibrary.open()` a standalone file the way you can on other OSes.

```dart
// lib/modules/native/ios_core.dart
import 'dart:ffi';
import 'package:my_app/modules/native_bridge.dart';

class IosNativeEngine implements NativeEngine {
  IosNativeEngine();

  @override
  dynamic heavyCompute(dynamic dataInput) {
    /// On iOS, the symbol has already been static-linked into the executable/.framework
    /// during the Xcode build, so use DynamicLibrary.process() (symbol within the
    /// current process itself) instead of DynamicLibrary.open("path/to/file").
    try {
      final lib = DynamicLibrary.process();
      // return lib.lookupFunction<...>(...)(dataInput);
      return 'iOS Optimized Result';
    } catch (_) {
      return 'iOS Fallback Result';
    }
  }
}
```

Register the additional iOS branch in `native_bridge.dart` (`Platform.isIOS → IosNativeEngine()`).

### D.3 License Checker Notes (If Appendix A Applies)

Similar to Android, an iOS branch is needed in `_getLocalHwid()` using `device_info_plus`:

```dart
if (Platform.isIOS) {
  final iosInfo = await DeviceInfoPlugin().iosInfo;
  return iosInfo.identifierForVendor ?? 'UNKNOWN_HWID';
}
```

Note: `identifierForVendor` can change if the user removes every app from the same vendor and reinstalls — it is not as absolutely stable as hardware HWID on desktop. Weigh this carefully if the license needs to be hard-bound to a single device.

### D.4 Build & Sign Release

See skill **`flutter-mobile-build-pro`** for the complete workflow: configuring the signing team/provisioning profile in Xcode, the `flutter build ios` / `flutter build ipa` commands. Mandatory requirement: the build machine must run **macOS** with **Xcode** installed.

### Responsive Settings Tab Sizing

The three Settings tabs should not share one forced fixed height. The collapsed Advanced Settings tab should fit its CDP/accordion blocks; User Guide and About may expand the dialog to fit documentation, with scrolling for long content. Prefer an implicit size transition and top-aligned tab content so the compact state does not leave a large blank region.