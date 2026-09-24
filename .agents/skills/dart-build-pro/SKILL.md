---
name: dart-build-pro
description: Automated workflow for professionally compiling, packaging, and releasing Dart / Flutter Windows Desktop applications. Activates when the user requests building the app, packaging a release, or creating a release zip file for a Dart/Flutter project.
---

# Dart & Flutter Windows Build & Packaging Guide (`dart-build-pro`)

A standardized guide for the compilation workflow, bundling embedded tools (`bin/`, `assets/`, `i18n/`, documentation), terminating the running application, and compressing the standard `x64` release package wrapped inside a **parent folder** for Flutter Desktop applications on Windows.

## ⚡ Lightweight Variant: Quick Dev Build (`build_windows.bat`)

When you only need a quick compile to check the Release build during development (no need to package a zip/release), use this minimal script — it doesn't depend on the app name or specific project structure, so it can be copied verbatim for ANY new Flutter Desktop Windows project:

```bat
@echo off
cd /d %~dp0
echo [BUILD] Compiling Windows desktop application in Release mode...
call flutter build windows
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Build failed!
    pause
    exit /b %ERRORLEVEL%
)

echo [LINK] Creating shortcut .Release.lnk to Release directory...
powershell -NoProfile -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('.Release.lnk'); $Shortcut.TargetPath = Join-Path (Get-Item .).FullName 'build\windows\x64\runner\Release'; $Shortcut.Save()"
echo [SUCCESS] Release build complete. Shortcut .Release.lnk created.
pause
```

- Creates `.Release.lnk` right at the project root, pointing directly to `build\windows\x64\runner\Release\` — double-click to open the Release folder, no need to type the long path every time after building.
- Does not kill the process, does not clean the cache, does not copy `bin/`/`assets/`/`i18n/`, does not package a zip — INTENTIONALLY minimal for a fast dev loop (edit code → build → click shortcut to check), and does not replace the full 5-step process below when you need to build a real release.
- Remember to add `*.lnk` to `.gitignore` (usually already covered by the excluded `*.bat`/`*.lnk` pattern, see `flutter-app-blueprint`) — the shortcut points to an absolute path on the dev machine and should not be committed.
- When the user simply says "try a build"/"quick build to check" (without mentioning packaging/release/zip), use this variant instead of running the full 5-step process.

## Standard 5-Step Build & Packaging Process:

### 0. Ensure release output and backup are in .gitignore`
Before building a project for the first time, check whether .gitignore already excludes dist/, dist_pack/, and backup/` (these are binary build outputs — exe, dll, .so — not source code, and should not be committed to GitHub). If missing, add:
```gitignore
dist/
dist_pack/
```

### 1. Terminate the Running Application (Kill Process)
Before compiling or cleaning up files, always terminate the running application process to avoid file lock errors (`ERROR_SHARING_VIOLATION`):
```cmd
taskkill /IM <app_name>.exe /F 2>nul
```

### 2. Clean the Build Cache (Clean Cache)
If you move directories or make changes to source/C++ code, delete the temporary directories to avoid CMakeCache conflicts:
```cmd
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool
if exist windows\flutter\ephemeral rmdir /s /q windows\flutter\ephemeral
```

### 3. Compile the Release Build (Flutter Release Build)
Run the command to build the Windows application in Release mode:
```cmd
flutter build windows --release
```

### 4. Package All Accessories (`bin/`, `assets/`, `i18n/`, `docs`)
⚠️ **Before copying, always remove `config.json`/`config.ini`/`logs/` from `%REL%` if present** — this is runtime data left behind by the most recent `.exe` run from the Release folder itself (not a build artifact), and it often contains the user's real tokens/credentials. This bug has actually happened before (v2.6.0, JA MES Tool): a real bearer token nearly got packaged into the publicly released zip file because the `xcopy %REL%\*.* dist\` step copies everything currently in Release verbatim, without distinguishing build output from runtime state. Always inspect `dist/` after packaging, before compressing the zip or attaching it to a GitHub Release.

Copy all embedded toolsets and resources into the output folder `build\windows\x64\runner\Release\` and the `dist/` folder:
- `bin/` -> Embedded tools (`gh.exe`, `git/`)
- `assets/` -> Images, icons
- `i18n/` -> Localization/language files
- `debug.bat`, `ABOUT.txt`, `README.md`, `CHANGELOG.md`, `LICENSE` -> Documentation & debug file

Packaging command (`build_release.bat`):
```cmd
@echo off
setlocal enabledelayedexpansion
title Build Release Packager

set WORKSPACE_DIR=%~dp0
cd /d "%WORKSPACE_DIR%"

taskkill /IM <app_name>.exe /F 2>nul
call flutter build windows --release
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

set REL=build\windows\x64\runner\Release

:: Remove old runtime data left behind by the previous .exe run in the
:: Release folder itself (config.json usually contains the end user's REAL
:: token/credentials, logs/ contains operational logs) — this must NOT end
:: up in the release package. Must delete BEFORE copying accessories, since
:: the xcopy *.* dist\ step below copies everything in %REL% verbatim,
:: including this runtime junk.
if exist %REL%\config.json del /f /q %REL%\config.json
if exist %REL%\config.ini del /f /q %REL%\config.ini
if exist %REL%\logs rmdir /s /q %REL%\logs

if exist bin xcopy /e /i /y /q bin %REL%\bin\
if exist assets xcopy /e /i /y /q assets %REL%\assets\
if exist i18n xcopy /e /i /y /q i18n %REL%\i18n\
if exist debug.bat copy /y debug.bat %REL%\
if exist ABOUT.txt copy /y ABOUT.txt %REL%\
if exist README.md copy /y README.md %REL%\
if exist CHANGELOG.md copy /y CHANGELOG.md %REL%\
if exist LICENSE copy /y LICENSE %REL%\

xcopy /e /i /y /q %REL%\*.* dist\

if exist "dist_pack" rmdir /s /q "dist_pack"
mkdir "dist_pack\<App_Name>_v1.0.0_Windows_x64"
xcopy /e /i /y /q "dist\*.*" "dist_pack\<App_Name>_v1.0.0_Windows_x64\"
powershell -Command "Compress-Archive -Path 'dist_pack\*' -DestinationPath 'dist\<App_Name>_v1.0.0_Windows_x64.zip' -Force"
if exist "dist_pack" rmdir /s /q "dist_pack"
```

### 5. Create the Release ZIP Package Wrapped in a Parent Folder (Parent Folder Packaging)
**Mandatory rule:** To prevent files from spilling out loose when the user extracts the archive, all files must be wrapped inside a **parent folder** named in the format `<App_Name>_v<Version>_Windows_x64`:

```powershell
powershell -Command "if (Test-Path 'dist_pack') { Remove-Item 'dist_pack' -Recurse -Force }; New-Item -ItemType Directory -Path 'dist_pack\<App_Name>_v1.0.0_Windows_x64' -Force; Copy-Item -Path 'dist\*' -Destination 'dist_pack\<App_Name>_v1.0.0_Windows_x64' -Recurse -Force; Remove-Item 'dist_pack\<App_Name>_v1.0.0_Windows_x64\*.zip' -ErrorAction SilentlyContinue; Remove-Item 'dist\<App_Name>_v1.0.0_Windows_x64.zip' -ErrorAction SilentlyContinue; Compress-Archive -Path 'dist_pack\*' -DestinationPath 'dist\<App_Name>_v1.0.0_Windows_x64.zip' -Force; Remove-Item 'dist_pack' -Recurse -Force"
```

---

## Skill Trigger Keywords:
Whenever the user types or requests the following commands:
- `/build` or `build app` or `call build skill` or `build release`
- The AI will automatically activate the `dart-build-pro` Skill and fully execute the 5-step process above.

## Standard Debug & Logger Configuration Guide
To support debugging the application after a release build, the `debug.bat` file needs to be designed to run the compiled `.exe` file directly, rather than using the `flutter run` command.

### 1. Standard Content for `debug.bat`:
```cmd
@echo off
cd /d %~dp0
for %%i in (*.exe) do (
    start "" "%%i" -debug
    exit
)
```

### 2. Timestamp Configuration in the Logger (Debug mode)
For logs to store complete time information, use the full ISO format `DateTime.now().toIso8601String()` for debug mode.
Example configuration in Dart:
```dart
  static void log(String message, {String level = 'INFO', Object? error, StackTrace? stackTrace}) {
    // Use full ISO for debug mode to get date, time, and millisecond detail
    final timestamp = isDebugMode ? DateTime.now().toIso8601String() : DateTime.now().toIso8601String().substring(11, 19);
    var formatted = '[$timestamp] [$level] $message';
    // ...
  }
```

**Note:** make sure this debug timestamp applies to the EXACT format function that actually displays on the UI (e.g. the Console/Logs tab) — not just to an internal logger that writes to a separate file the user never sees. Verify by grepping which format function the UI is calling before making changes.

### 3. Debug Badge Displayed on the Main Interface (mandatory)
In addition to logging to file/console, the app MUST have a small badge, always displayed on the main interface (placed near the app's main status/engine area, e.g. next to the operating-status card) when running in debug mode, using exactly this format:

```
DEBUG · v<version> (<build time>)
```

Example: `DEBUG · v2.4.0 (2026-08-11 14:27:38)`

- `<version>` is taken from the app's version constant (constants.dart or equivalent).
- `<build time>` is the **moment the binary was built**, NOT the current time (do not use a live/ticking clock). Take it from the mtime of the AOT-compiled artifact (`data/app.so` for a Windows Release build), falling back to the mtime of the `.exe` file itself if `app.so` is not present (e.g. a debug/JIT build run via `flutter run`).
- Time format: `yyyy-MM-dd HH:mm:ss` (do not use ISO with the `T` character/milliseconds in this badge — full ISO is only used for logs, see section 2).
- Only shown when the app is launched with the `-debug` flag (completely hidden in normal mode).
- **If the text overflows the badge frame** (typically happens in a narrow sidebar): use an **asymmetric marquee** effect — a SLOW, linear, readable scroll from the start to the end of the text, a hold, then a FAST (easeOut) snap back to the start, a hold, then repeat. **This is NOT a symmetric ping-pong** (both directions at the same speed/curve) — the outbound and return trips are deliberately different in both duration and easing. Does NOT get cut off with `TextOverflow.ellipsis`.

**Standard implementation (source of truth: `JA_DUT_Info/lib/modules/ui/main_window.dart` → `_MarqueeText`, confirmed correct by the user — do NOT manually measure width by hand):** use `SingleChildScrollView` + `ScrollController.animateTo()`, do NOT use `TextPainter`/`RenderBox`/`GlobalKey` to manually estimate text width and then build a `SizedBox`/`Transform.translate` by hand — manual measurement was tried across 2 rounds (plain TextPainter, then TextPainter+textScaler, then even measuring the real RenderBox after render) and in every case there were still instances where the tail end of the text got permanently cut off for unclear reasons on real machines, even after the animation finished. The reason `SingleChildScrollView` is more reliable: `position.maxScrollExtent` is computed by Flutter itself from the actual layout, so there's no parallel measurement that can diverge from what's actually rendered.

⚠️ **A previous version of this section was wrong** (it described and coded a symmetric two-direction-same-speed ping-pong, and mislabeled it "verified correct"). The user had to point to their own reference project (`JA_DUT_Info`) again before the actually-intended asymmetric effect above got confirmed. Lesson: don't self-label a pattern "verified" unless it was actually checked against the user's own reference implementation.

```dart
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _MarqueeText({super.key, required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  Future<void> _startScrolling() async {
    if (!_scrollController.hasClients) return;
    await Future.delayed(const Duration(milliseconds: 1500)); // delay before starting
    if (!mounted) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (maxScrollExtent <= 0) return; // fits within frame, no need to run

    while (mounted) {
      // SLOW, linear scroll to the end — duration scales with text length
      await _scrollController.animateTo(
        maxScrollExtent,
        duration: Duration(milliseconds: widget.text.length * 60),
        curve: Curves.linear,
      );
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 1500)); // hold at the end

      // FAST snap back to the start — FIXED duration regardless of text length, different curve
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
      );
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 1500)); // hold at the start
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(), // block manual dragging
      child: Text(widget.text, style: widget.style, maxLines: 1),
    );
  }
}
```

- **The outbound and return trips are deliberately asymmetric — this is the core of the effect:** outbound uses `Curves.linear` with a duration proportional to `text.length * 60ms` (longer text scrolls longer, always at a readable pace — `60ms` is the user-confirmed value from an interactive simulation, NOT the original `90ms` first written into this skill); the return trip uses `Curves.easeOut` with a FIXED `800ms` regardless of text length (a distinct, snappy "bounce back" feel that contrasts with the slow outbound trip).
- **Confirmed via an interactive simulation, not just by reading code:** when tuning an effect's timing per user feedback and the real app can't be watched directly (e.g. screenshot tooling unavailable), build a small HTML/CSS/JS mockup that reproduces the exact animation (same easing, same duration formula) for the user to review and lock in the final numbers — much faster than "guess a number → build → ask again" loops.
- **A ~1.5s hold pause at both ends of the cycle** (before starting, and between the two scroll passes) — so the text stays still long enough in its fully-shown state, making it easier to read than just a quick pass-through.
- If `maxScrollExtent <= 0` (the text already fits within the frame), the loop exits immediately and the text is displayed statically, left-aligned — no need to separately check for overflow by any other means beforehand.
- **Performance:** very cheap, nothing to worry about — the badge only exists when `isDebugMode == true` (zero cost in a normal release build), and when the text fits the frame the loop exits immediately with no animation running at all. `SingleChildScrollView.animateTo()` uses Flutter's internal animation mechanism, so there's no need to manage a separate `AnimationController`/`Ticker`.
- **This widget is reusable for ANY text that may overflow its box, not just the debug badge** — real example: the "typed SN → resolved SN" label in a record-list header (JA_MES_Tool) started truncating with `TextOverflow.ellipsis` once a new badge/chip was added next to it and ate the remaining space; swapping the plain `Text` for this marquee fixed it without shrinking the badge or the label. When reusing it across a list of different entities (one label per SN, per row, etc.), you MUST attach `key: ValueKey(theTextContent)` to each instance — otherwise, when the entity changes (switching to a different SN) and Flutter reuses the same `State`, the old scroll loop keeps running with the `maxScrollExtent` measured from the previous text and never resets to position 0 for the new one.
- Remember to declare `super.key` in the constructor — without it, `key:` can't be passed to the widget (compile error `undefined_named_parameter`), a real error hit when reusing this pattern.

### 4. Note on App Self-Elevation to Admin Rights (self-elevation)
If the app needs to run with Administrator rights and relaunches itself using `Start-Process ... -Verb RunAs` (or an equivalent mechanism), you **MUST forward all the original command-line args** (including `-debug`) to the new elevated process, e.g. using `-ArgumentList`:
```powershell
Start-Process "<exePath>" -ArgumentList "-debug" -Verb RunAs
```
If this step is forgotten, the elevated process (the process the user actually interacts with) will always start with an empty args list — the `-debug` flag is silently lost even though the user ran `debug.bat` correctly, which is very hard to detect since no error is ever thrown.

## Release Artifact Lifecycle (Required)

Every release must create a clean dist/ directory. Never place dist_v<version>/, dist_pack_v<version>/, or another release output directory inside dist/; nested release directories make the package ambiguous and dirty.

After the Windows build succeeds, snapshot the existing dist/ as a whole into a unique, gitignored backup/dist_<timestamp>/ directory instead of deleting it or merging new files into it. Recreate an empty dist/ and copy only the current release output into it. If a stale dist_pack/ exists, move it to a unique backup/dist_pack_<timestamp>/ or remove it only after confirming it is disposable staging output.

Keep dist_pack/ as a temporary sibling used only while creating the parent-folder ZIP, then remove it. Before uploading, verify that dist/ contains no nested dist*, dist_pack*, or backup directories and no config.json, config.ini, or logs/. The backup/ directory may contain old runtime state and must remain gitignored.

### ⚠️ Portable Apps That Store LIVE Data Next To The Binary — `dist/` Is Not Always Disposable (Mandatory Check)

Some apps in this family are "portable": at runtime they read/write their own database file relative to `Directory.current.path` / `Platform.resolvedExecutable`'s folder (e.g. `assets/data/<name>_history.json`, `config.ini`, `pending_operation.json`) instead of a per-user OS profile folder. When such an app is actually run by the user directly from `dist/` (not installed anywhere else), `dist/` is simultaneously **build output** (safe to nuke and regenerate) AND **the user's live data store** (NOT safe to nuke) — the same folder serves two conflicting roles, and a build script that only thinks of it as "build output" will destroy real user data on every rebuild.

**Before writing `if exist dist rmdir /s /q dist` (or equivalent) into ANY build script**, you MUST check whether the target app has this pattern: grep the app's data-access modules (typically `*_service.dart`) for `Directory.current.path` / `Platform.resolvedExecutable` used to locate a JSON/CSV/DB file. Do not skip this check or defer it as "nice to have, keep the script simple" — that exact rationalization is what caused the real incident below. If the pattern is found, the build script MUST back up that live-data directory before wiping `dist/`, and restore it after re-copying the fresh Release build — snapshotting into `backup/dist_<timestamp>/` per the paragraph above satisfies this too, but a targeted backup/restore of just the data dir is simpler to get right:

```bat
set BACKUP_DIR=backup\dist_data_backup

:: BEFORE wiping dist\ — snapshot the live data directory (adjust the path
:: below to match where THIS app's *_service.dart actually reads/writes)
if exist "dist\assets\data" (
    if exist "%BACKUP_DIR%" rmdir /s /q "%BACKUP_DIR%"
    mkdir "%BACKUP_DIR%\assets\data"
    xcopy /e /i /y /q "dist\assets\data" "%BACKUP_DIR%\assets\data\" >nul
    if exist "dist\config.ini" copy /y "dist\config.ini" "%BACKUP_DIR%\" >nul
)

:: ... flutter build, kill process, "if exist dist rmdir /s /q dist" + recreate,
:: re-copy assets/i18n/docs into the fresh dist\ ...

:: AFTER dist\ is repopulated from the fresh Release build — restore live data
:: OVER the stub/seed copies that just got copied in from source assets\
if exist "%BACKUP_DIR%\assets\data" (
    xcopy /e /i /y /q "%BACKUP_DIR%\assets\data" "dist\assets\data\" >nul
)
if exist "%BACKUP_DIR%\config.ini" copy /y "%BACKUP_DIR%\config.ini" "dist\" >nul
```

Add `backup/` to `.gitignore` alongside `dist/`/`dist_pack/` — it is a local safety net, not source.

**Real incident (JA_Symlink, 2026-08-30):** a `build.bat` authored without this check ran `if exist dist rmdir /s /q dist` and permanently deleted the user's live `symlink_history.json` (their real tracked-symlink database, accumulated over months) along with the build output. No Recycle Bin involvement (`rmdir /s /q` bypasses it), no git history (`dist/` is gitignored, was never committed). The user had to reconstruct state from an old exported snapshot and manually re-verify every entry against the real filesystem. The skill guidance to snapshot instead of delete already existed in this file at the time — it was read, then consciously skipped as "a nice-to-have refinement beyond the core ask, keep the script simple." **This check is not optional for any app in this family that persists local state next to its binary.**

### ⚠️ Import/Restore Features That Mutate Existing State Are Destructive — Treat Old Snapshots With Care

If the app has an "Import"/"Restore from file" feature that re-applies a saved list of entries (symlinks, presets, configs...), check whether applying an entry **actively mutates live state even when nothing changed** (e.g. remove-then-recreate a symlink/junction, rather than a no-op when the target already matches). If so:
- Importing an OLD/stale snapshot silently **reverts** any change made to that same entity after the snapshot was taken — there is no diff/confirmation step warning which entries will actually change vs. are already correct.
- If the snapshot contains multiple entries for the same key (e.g. the same `linkPath` re-targeted at different times), only the LAST one in file order wins — earlier entries are applied and then immediately overwritten by a later one, which is easy to miss when skimming the file for "is this safe to import."
- When recommending "just re-import your last export to recover lost tracking," do not present it as a safe, no-op recovery step — say explicitly that it will re-execute the underlying mutation for every listed entry, and verify the actual resulting state afterward (e.g. `(Get-Item <path>).Target` on Windows for symlinks/junctions) against what the user expects, rather than assuming the import was inert for entries that didn't need to change.

