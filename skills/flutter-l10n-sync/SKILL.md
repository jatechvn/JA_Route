---
name: flutter-l10n-sync
description: Skill that automatically scans, extracts, and synchronizes localization (.arb) files in Flutter. Activates when the user wants to add or update translations.
---

# Flutter L10n Sync Skill

This skill automates the localization workflow in Flutter projects, freeing the user from manual copy/paste and translation work.

## Workflow (For the Agent)
1. **Find ARB files:** Locate the directory containing `.arb` files (usually `lib/l10n/` or the directory configured in `l10n.yaml`).
2. **Scan the codebase:** Read `.dart` files in the `lib/` directory (if requested by the user) to find text strings not yet included in l10n. (This step may require confirmation with the user before modifying code.)
3. **Update & Translate:** 
   - Read the source language file (e.g., `app_vi.arb`).
   - Read the target language files (e.g., `app_en.arb`).
   - Detect keys that are missing in the target file.
   - Automatically use an LLM to translate the values from the source language into the corresponding target language.
   - Write the results back into the target `.arb` file.
4. **Build l10n:** Run `flutter gen-l10n` to have Flutter regenerate the localization code.
5. **Report:** Show the user the list of new words that were added and translated.
