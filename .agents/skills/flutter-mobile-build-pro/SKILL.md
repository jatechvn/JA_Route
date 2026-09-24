---
name: flutter-mobile-build-pro
description: Build, sign, and package Flutter mobile applications for Android (APK/AAB) and iOS (IPA). Use when creating release builds for mobile platforms.
---

# Flutter Mobile Build & Signing Guide (`flutter-mobile-build-pro`)

Standardized build, signing, and release pipeline for Flutter Android and iOS mobile applications.

## ⚠️ Security Constraints
- Do NOT upload directly to Google Play Console or App Store Connect.
- Do NOT delete or modify keystores/certificates without explicit user consent.
- Never commit `key.properties`, `.jks`, `.keystore`, or provisioning profiles.

---

## 🤖 Section A — Android

### A.1 Release Keystore Setup (`android/key.properties`)
Create `android/key.properties` (git-ignored):
```properties
storePassword=<keystore_password>
keyPassword=<key_password>
keyAlias=<key_alias>
storeFile=../my-release-key.jks
```

Generate keystore (if not existing):
```bash
keytool -genkey -v -keystore my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias <key_alias>
```

### A.2 Build Commands
```bash
# APK for direct testing/distribution
flutter build apk --release

# App Bundle for Google Play distribution
flutter build appbundle --release
```
Outputs:
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

---

## 🍎 Section B — iOS

> **Requirement:** Build machine MUST run **macOS** with **Xcode** installed.

### B.1 Xcode Signing Configuration
Configure signing in `ios/Runner.xcworkspace` under **Signing & Capabilities**:
- Set Apple Developer Team.
- Verify Bundle Identifier matches Apple Developer Portal.
- Select App Store or Ad Hoc Provisioning Profile.

### B.2 Build Commands
```bash
# Build .app for device testing
flutter build ios --release

# Export .ipa for distribution
flutter build ipa --release
```
Output: `build/ios/ipa/*.ipa`.

### B.3 Verification Checklist
- Ensure `CFBundleShortVersionString` in `Info.plist` matches `appVersion` in `lib/modules/constants.dart`.
- Verify static `.framework` linkage if using native Rust/C cores.
