---
name: asset-manager
description: Asset management skill (images, icons, fonts) for Flutter projects. Automatically adds assets to pubspec.yaml and generates management code.
---

# Asset Manager Skill

This skill helps automatically configure and manage asset files to avoid missing files or forgetting to declare them in pubspec.

## Execution Process (For Agent)
1. **Scan assets:** Scan the `assets/` directory (and subdirectories such as `images`, `icons`, `fonts`) to get a list of existing files.
2. **Update pubspec.yaml:** Open the `pubspec.yaml` file, check the `assets:` section, and automatically declare new asset directories (e.g., `- assets/images/`) if they are not already present. Make sure to preserve the YAML format.
3. **Generate App Icons:** If the user requests app icon generation, help run the `flutter_launcher_icons` package by updating the configuration and running `dart run flutter_launcher_icons`.
4. **Generate Asset Class (Optional):** If the user wants, create a `lib/core/constants/app_assets.dart` file containing static const String values pointing to image/icon files, for convenient use in code and to avoid typos in file names.
5. **Report:** Notify completion and inform the user how to use the new asset files.
