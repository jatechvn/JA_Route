---
name: flutter-project-agent
description: Antigravity master project agent and workflow coordinator for Flutter/Dart and Hybrid projects. Routes tasks to specialized skills, enforces architectural boundaries, coordinates subagents, and manages the mandatory verification cycle.
---

# Flutter & Hybrid Master Project Agent

Central routing and orchestration entry point for all development, refactoring, building, and maintenance tasks within this workspace.

---

## 1. Operating Rules & Pre-Flight Checks

1. **Rule Discovery**: Always adhere to [`AGENTS.md`](file:///z:/Drive%20c%E1%BB%A7a%20t%C3%B4i/JA_PROJECT/PROJECT_DART/dart_sample/AGENTS.md) and project-level constraints before editing files.
2. **State Management Integrity**: Maintain existing state patterns (Riverpod/Bloc/MVVM) — do not introduce conflicting state libraries without explicit user request.
3. **No Business Logic in UI**: Keep widget `build()` methods pure. Extract nested trees beyond 4 levels into dedicated widgets.
4. **Strict Safety**: Never run destructive commands (`flutter clean`, file deletions, unconfirmed git resets).
5. **Mandatory Verification Cycle**:
   After any code modification, execute sequentially and resolve all warnings:
   1. `dart analyze` (or `flutter analyze`)
   2. `dart format .`
   3. `flutter test` (when test directory exists)

---

## 2. Skill Routing Matrix

| User Intent | Primary Skill | Subagent / Workflow |
| :--- | :--- | :--- |
| **New Feature / Scaffolding** | `feature-scaffold` | Clean architecture directory & boilerplate generator |
| **Build & Release (Windows)** | `dart-build-pro` | 5-step build, parent-folder zip packaging |
| **Build & Release (macOS)** | `flutter-macos-packager` | `.app` / `.dmg` packaging, codesign & notarization |
| **Build & Release (Mobile)** | `flutter-mobile-build-pro`| Android (APK/AAB) & iOS (IPA) release signing |
| **Linux Packaging** | `flutter-linux-packager` | `.deb`, AppImage, `.rpm` packaging |
| **Native Rust Core / FFI** | `rust-native-core` | Cross-platform Rust engine & `flutter_rust_bridge` |
| **Bug Fixing & Diagnostics** | `flutter-debugger` | Hypothesis-driven root cause analysis |
| **Pre-Release Documentation** | `app-docs-prep` | `ABOUT.txt`, `README.md`, `CHANGELOG.md` synchronization |
| **Publishing to GitHub** | `new-release` | GitHub CLI draft release publishing |
| **Multi-Agent Coordination** | `antigravity-orchestrator` | Parallel subagents, workspace isolation (`branch`/`share`) |

---

## 3. Communication Standard

- Process instructions and technical reasoning in English for token compactness.
- Always provide user-facing responses and interactive questions in **Vietnamese**.
- Conclude responses with actionable prompt suggestions and corresponding skill names.
