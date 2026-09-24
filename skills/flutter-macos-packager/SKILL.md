---
name: flutter-macos-packager
description: Build, bundle (.app/.dmg), and notarize Flutter macOS Desktop applications. Use when packaging macOS releases or creating dmg installers.
---

# Flutter macOS Packaging Guide (`flutter-macos-packager`)

Standardized build, codesigning, and release packaging workflows for Flutter macOS Desktop applications.

> **Requirement:** Build machine MUST run **macOS** with **Xcode Command Line Tools** installed.

---

## 4-Step Packaging Workflow

### 1. Release Compilation
```bash
flutter build macos --release
```
Output: `.app` bundle at `build/macos/Build/Products/Release/<App_Name>.app`.

### 2. Codesigning (Mandatory for Distribution)
```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: <Developer Name> (<TEAM_ID>)" \
  "build/macos/Build/Products/Release/<App_Name>.app"
```

### 3. DMG Creation
Using built-in `hdiutil`:
```bash
hdiutil create -volname "<App Display Name>" \
  -srcfolder "build/macos/Build/Products/Release/<App_Name>.app" \
  -ov -format UDZO \
  "dist/<App_Name>_v<version>_macOS.dmg"
```

Or using `create-dmg` for customized visual installers:
```bash
create-dmg \
  --volname "<App Display Name>" \
  --window-size 600 400 \
  --icon "<App_Name>.app" 150 150 \
  --app-drop-link 450 150 \
  "dist/<App_Name>_v<version>_macOS.dmg" \
  "build/macos/Build/Products/Release/<App_Name>.app"
```

### 4. Apple Notarization (Mandatory for Non-App-Store Distribution)
```bash
# Archive .app to zip for notarization submission
ditto -c -k --keepParent "build/macos/Build/Products/Release/<App_Name>.app" "notarize.zip"

# Submit to Apple notarization service
xcrun notarytool submit "notarize.zip" \
  --apple-id "<apple-id>" --team-id "<TEAM_ID>" --password "<app-specific-password>" \
  --wait

# Staple notarization ticket to .app for offline Gatekeeper verification
xcrun stapler staple "build/macos/Build/Products/Release/<App_Name>.app"
```

*Note: Never hardcode credentials. Prompt user for `xcrun` authentication.*

---

## Native Core Dynlib Signing
If bundling native Rust/C libraries (`libcore.dylib`), sign dylibs before final `.app` bundle signing (`codesign --verify --deep --strict`).
