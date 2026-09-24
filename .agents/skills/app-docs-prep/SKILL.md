---
name: app-docs-prep
description: Automated pre-release documentation and metadata preparation skill. Updates ABOUT.txt, README.md, CHANGELOG.md, and multi-language docs before committing and pushing to GitHub.
---

# App Documentation & GitHub Release Preparation Skill

This skill automates preparing documentation and metadata for a project before committing and pushing to GitHub, following the JA-HUB documentation standard (reference implementation: `JA_Auto_Git`).

## Triggers
Activate when the user wants to:
- Prepare to push new code to GitHub / release the app
- Rewrite/update `ABOUT.txt`, `README.md` after finishing the app or a new feature
- Sync `CHANGELOG.md` and the app version
- Add or update translated docs in `i18n/`

## Workflow (For the Agent)

### 1. Sync version numbers
- Check `appVersion` in `lib/modules/constants.dart` (or the project's main constants file) against `pubspec.yaml`.
- Make sure the version follows Semantic Versioning (`MAJOR.MINOR.PATCH`).
- Grep the codebase for other hardcoded version literals (e.g. `BuildInfo.version = '1.0.0'`) and make sure they reference the constants file instead of a duplicated literal.

### 2. Sanity-check `.gitignore` before touching docs
A repo missing `.gitignore` entries silently ships build binaries or local tooling config to GitHub the next time someone pushes — catch this now, before it becomes a broken-push investigation later.
- Run `git ls-files` (or `git ls-files | grep -E '^(dist|dist_pack|build|Release)/'`) and check whether anything that shouldn't be version-controlled is currently tracked: build/packaging output (`dist/`, `dist_pack/`, `build/`, `Release/`), `.claude/` (project-local Claude Code skill/agent config — not app source), secrets-bearing config (`config.json`/`config.ini` if it holds tokens/passwords), `*.log`, `.dart_tool/`, `.fvm/`, `license.key`. Cross-reference against the canonical list in **`flutter-app-blueprint`**'s "🌿 Standard Git & .gitignore Configuration" section (the shared source of truth for what a Dart/Flutter project's `.gitignore` should contain).
- If `.gitignore` is missing any relevant rule, add it.
- If a path that should be ignored **is already tracked** (added before the rule existed), also run `git rm -r --cached <path>` to untrack it — this only removes it from git's index, the file stays on disk untouched. Don't commit or push this yourself (see Boundary below); just leave it staged alongside the rest of this pass so the user commits everything together, and call it out explicitly in the Step 9 report so it isn't missed.

### 3. Update the project info card (`ABOUT.txt`)
Create/update `ABOUT.txt` following the standard JA Auto Git format:
```text
========================================================================
                       PROJECT INFORMATION CARD
========================================================================
Project Name : <Project_Name>
Tech Stack   : <Tech_Stack>
Managed By   : JA Auto Git
Website      : https://jatechvn.github.io/
------------------------------------------------------------------------
Description  : <Short description for the GitHub About section>
========================================================================
```

### 4. Update `README.md`
Write detailed, elegant, professional content — not a bare-minimum README. Follow this skeleton (reference: `JA_Auto_Git/README.md`):

1. **Centered header block**: logo `<img>`, `# <emoji> <Project Name>`, one-line tagline, a row of shield.io badges (Flutter/Dart version, Platform, Release, License), a screenshot, a one-line pitch.
2. **Table of Contents** with anchor links to every `##` section below.
3. **Core Capabilities**: one `###` subsection per major feature area, each a bullet list of **bold feature name:** description.
4. **Architecture/UX table** (optional): a Markdown table when there's a design system or set of visual features worth comparing side by side.
5. **Directory & Technical Architecture**: a fenced ```text``` tree of the actual folder structure, with a one-line comment per entry — regenerate this from the real project layout, don't reuse a stale tree from another project.
   - **Cross-check against `git ls-files -- '*/' | cut -d/ -f1 | sort -u` (or equivalent) before finalizing the tree** — don't just describe `lib/`. A real incident: `JA_MES_Tool`'s `windows/runner/` directory (containing hand-written native Acrylic/Mica theming code, `theme_win10.cpp`/`theme_win11.cpp`) was committed and pushed to GitHub all along, but the README's directory tree only ever showed `lib/`/`docs/`/`i18n/` — the native code was invisible to anyone browsing the repo until a user noticed and asked. Any top-level directory that's actually git-tracked (native runners: `windows/`, `macos/`, `linux/`, `android/`, `ios/`; embedded tooling: `bin/`) and contains more than boilerplate deserves at least a summarized entry, even if it's not Dart/Flutter source — call out which files are hand-written/custom (worth a one-line comment each) vs. which are framework-generated boilerplate (fine to fold into one `# mostly Flutter-generated boilerplate` line rather than listing every file).
6. **Quick Start Guide**: "Option A: Portable Run" (download/extract/run the release zip) and "Option B: Building from Source" (prerequisites + numbered `git clone` / `pub get` / `flutter run` / `flutter build` commands).
7. **Configuration & Settings** (if applicable): a fenced ```json``` example of the persisted user-settings file.
8. **Changelog recap**: last 2-3 versions summarized in one bullet each, linking to `CHANGELOG.md` for full history.
9. **License & Author**: license type, link to `LICENSE`, author name/handle, repo link.
- Check the `assets/` folder for screenshots/logo to embed; use centered `<img>` tags to match the existing visual style.
- Update the install/run instructions and make sure all documentation links still resolve.

### 5. Update the in-app About & User Guide content
A feature isn't documented until it's visible inside the running app too, not just in Markdown files. If the app has a Settings/About dialog (see `flutter-app-blueprint`'s Comprehensive Settings Dialog spec — tabs "User Guide" and "About Application"), update both:

- **About Application tab**: app name + `v$appVersion`, one-line tagline (same text as `ABOUT.txt`'s `Description` field — keep both in sync), developer credit, license, and — **always required** — a tappable link to `https://jatechvn.github.io/` plus the GitHub repo link. Don't let this tab go stale after a rebrand/version bump.
- **User Guide tab**: keep it in sync with `README.md`'s "Core Capabilities" section — pull content from there rather than re-authoring separately, so the two never drift apart. Update Getting Started / Tips / Troubleshooting for any new feature.
- If the in-app text needs translating into other languages, delegate that to **`flutter-l10n-sync`** — this step only owns the English-source content, not the translation.

### 6. Sync `CHANGELOG.md`
`CHANGELOG.md` (permanent, cumulative, shipped with the app) is a **different file** from `RELEASE_NOTES.md` (temporary, TAG/TITLE/BODY, consumed by the `new-release` skill) — do not treat them as the same deliverable.

Format (reference: `JA_Auto_Git/CHANGELOG.md`):
```markdown
# 📜 CHANGELOG - <Project Name>

All notable changes to **<Project Name>** will be documented in this file.

---

## [v1.6.0] - YYYY-MM-DD

### 🚀 Major Features & Enhancements
- **🌐 <Feature Name>:**
  - <detail line>
  - <detail line>
- **🗂️ <Another Feature>:**
  - <detail line>

---

## [v1.5.0] - YYYY-MM-DD
...
```
- Scan commits since the latest tag (`git log <latest_tag>..HEAD --pretty=format:"%s"`), group them under one or more emoji-titled categories (`### 🚀 Major Features & Enhancements`, `### 🐛 Bug Fixes`, `### 🔧 Chores`), and write each as a bold, emoji-prefixed feature name with nested detail bullets — not a flat commit-message dump.
- Prepend the new version block above the previous one; never rewrite past entries.
- If the user also wants `RELEASE_NOTES.md` prepared for a GitHub release, call the **`auto-changelog`** skill separately for that — it's a different file with a different (TAG/TITLE/BODY) format.

### 7. Multi-language docs (`i18n/`)
This project's `i18n/` folder holds **translated copies of `README.md`**, not in-app UI strings — keep this separate from the app's own runtime localization (whatever file that is; grep for it, don't assume a fixed path/name, since it varies per project — e.g. `lib/utils/i18n.dart` in `JA_Auto_Git`, `.arb` files under `lib/l10n/` elsewhere. If in-app strings also need updating, delegate that to **`flutter-l10n-sync`**).

- File naming: `i18n/README.<lang-code>.md` (e.g. `README.vi.md`, `README.zh-CN.md`, `README.ja-JP.md`).
- Every README (root and translated) must carry the same language-switcher link bar near the top, only the current language left unlinked:
  ```markdown
  <p align="center"><a href="../README.md">🇺🇸 English</a> • 🇻🇳 Tiếng Việt • <a href="README.zh-CN.md">🇨🇳 中文</a> • <a href="README.ja-JP.md">🇯🇵 日本語</a> • <a href="README.es.md">🇪🇸 Español</a> • <a href="README.fr.md">🇫🇷 Français</a> • <a href="README.de.md">🇩🇪 Deutsch</a> • <a href="README.ru.md">🇷🇺 Русский</a> • <a href="README.pt.md">🇵🇹 Português</a> • <a href="README.ko.md">🇰🇷 한국어</a></p>
  ```
  (root `README.md` links out to `i18n/README.<lang>.md`; files inside `i18n/` link back with `../README.md` and to each other as siblings.)
- Only add/update languages the user actually asks for — don't invent translations for all 9 languages unprompted. When updating the English README's content, ask whether the translated copies should be refreshed too, since they can otherwise drift out of sync silently.

### 8. Verification pass (stack-aware)
- Detect the project's stack first, then run the matching check — don't assume Dart/Flutter by default:
  - Dart/Flutter present (`pubspec.yaml`) → delegate to **`dart-cleaner`** (`dart analyze`/`flutter analyze`, `dart format .`).
  - Rust core present (`Cargo.toml`, e.g. `rust_core/`) → run `cargo fmt --check` and `cargo clippy -- -D warnings`.
  - Python present (`pyproject.toml`/`requirements.txt`) → delegate to **`python-cleaner`** (ruff/black/mypy, whichever the project has configured).
  - More than one present → run every matching check.
- Confirm there are no warnings/errors left before proceeding.

### 9. Report
- Summarize which files were updated (ABOUT.txt, README.md + which `i18n/` translations, in-app About/User Guide content, CHANGELOG.md, version bump) and confirm nothing else needs attention.
- If Step 2 found and fixed a `.gitignore` gap (including untracking previously-committed files), call it out explicitly here — this is easy to miss since it's not a "documentation" change and the user needs to know before their next commit/push.

## Boundary
This skill only prepares documentation and metadata — it does **not** run `git commit` or `git push` itself. Committing/pushing stays a separate, explicit step for the user (or the **`new-release`** skill for the actual GitHub release).

### Runtime Version Sync Guard

After every version bump, search all runtime UI strings and translation maps under `lib/` for the previous version token. Verify the About and User Guide content displays the new version in every supported language; prefer `appVersion` interpolation where the translation architecture allows it, otherwise include the strings in the release-sync checklist alongside `ABOUT.txt`, `pubspec.yaml`, README files, and CHANGELOG.