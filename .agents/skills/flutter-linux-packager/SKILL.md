---
name: flutter-linux-packager
description: Build and packaging workflow for turning a Flutter Linux Desktop app into a .deb, .rpm, or AppImage. Activates when the user requests building a Linux app, packaging a Linux release, or creating an AppImage/deb.
---

# Flutter Linux Packaging Guide (`flutter-linux-packager`)

Alongside `dart-build-pro` (Windows), this skill standardizes the build & release packaging workflow for **Linux Desktop**, following the stack recommendations in `PROJECT_Linux/_sample/LINUX_STACK_GUIDE.md`.

## 4-Step Workflow

### 1. Compile the Release

```bash
flutter build linux --release
```

Output is located at `build/linux/x64/release/bundle/` (includes the executable binary + `data/` + `lib/`).

### 2. Package as `.deb` (Debian/Ubuntu)

Create the standard Debian package directory structure:

```text
dist_deb/
└── <app_name>_<version>_amd64/
    ├── DEBIAN/
    │   └── control
    ├── usr/
    │   ├── bin/<app_name>                       # symlink or wrapper script calling the real binary
    │   ├── lib/<app_name>/                       # copy the entire contents of build/linux/x64/release/bundle
    │   └── share/
    │       ├── applications/<app_name>.desktop
    │       └── icons/hicolor/256x256/apps/<app_name>.png
```

Sample `DEBIAN/control` file:

```text
Package: <app-name>
Version: <version>
Section: utils
Priority: optional
Architecture: amd64
Maintainer: <name> <email>
Description: <short description>
```

Sample `.desktop` file:

```ini
[Desktop Entry]
Name=<App Display Name>
Exec=/usr/bin/<app_name>
Icon=<app_name>
Type=Application
Categories=Utility;
```

Build the package:

```bash
dpkg-deb --build --root-owner-group "dist_deb/<app_name>_<version>_amd64"
```

### 3. Package as AppImage (runs on any distro, no installation required)

Requires the `appimagetool` tool (download it from AppImage/appimagetool on GitHub, or check whether it is already bundled in `bin/` following the `dart-build-pro` pattern).

```text
<App_Name>.AppDir/
├── AppRun                     # script calling the real binary, chmod +x
├── <app_name>.desktop         # same as the .desktop file from step 2
├── <app_name>.png             # icon
└── usr/                       # copy the contents of build/linux/x64/release/bundle here
```

```bash
appimagetool "<App_Name>.AppDir" "dist/<App_Name>_v<version>_Linux_x86_64.AppImage"
```

### 4. Package as `.rpm` (Fedora/RHEL) — optional

Only do this if the user explicitly asks for it (not the default, since it requires `rpmbuild` and an RPM-based distro to test on). The `.spec` file structure is similar to the Debian `control` file but follows the RPM spec format.

## Compatibility Notes

- Check whether the Flutter Linux binary's required GTK3 runtime (`libgtk-3-0`) is available on the target distro — if not, declare `Depends: libgtk-3-0` in `DEBIAN/control`.
- If the project has a native Rust/C core (`linux_core.dart`), make sure `libcore.so` is built for the correct target architecture (x86_64 by default; if ARM64 is needed, cross-compile separately with `cargo build --target aarch64-unknown-linux-gnu`).

## Skill Trigger Keywords

- `/build linux`, `build linux release`, `package linux`, `create AppImage`, `create deb file`
→ The agent asks which format is desired (`.deb`/AppImage/`.rpm`) if not clear, defaulting to AppImage (easiest to distribute, no install privileges required).
