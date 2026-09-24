# 🤖 JA_Route

<p align="center">
  <br>
  <i>**JA_Route is a cross-platform application developed in Dart/Flutter.**</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.2.0-blue.svg?style=flat-square" alt="Version 1.2.0">
  <img src="https://img.shields.io/badge/Dart-Flutter-blue.svg?style=flat-square&logo=flutter" alt="Dart & Flutter">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square" alt="License">
</p>

<p align="center"><a href="#quick-start">🚀 Quick Start</a> • <a href="#features">💡 Features</a> • <a href="#setup">📖 Setup</a> • <a href="https://jatechvn.github.io/">🌐 Website</a></p>

<p align="center">🇺🇸 English • <a href="i18n/README.vi.md">🇻🇳 Tiếng Việt</a> • <a href="i18n/README.zh-CN.md">🇨🇳 中文</a> • <a href="i18n/README.ja-JP.md">🇯🇵 日本語</a> • <a href="i18n/README.es.md">🇪🇸 Español</a> • <a href="i18n/README.fr.md">🇫🇷 Français</a> • <a href="i18n/README.de.md">🇩🇪 Deutsch</a> • <a href="i18n/README.ru.md">🇷🇺 Русский</a> • <a href="i18n/README.pt.md">🇵🇹 Português</a> • <a href="i18n/README.ko.md">🇰🇷 한국어</a></p>

---

<a id="introduction"></a>
## Introduction

**JA_Route** is an automated Dual-NIC network route optimizer and diagnostic tool for Windows desktop, featuring a modern Bento Glassmorphism UI, intelligent route verification, root cause analysis, and 1-click route fixing.

## Recent Changes (v1.2.0)
- **Smart Route Verification**: Manual input for any IP, Domain, or URL with DNS resolution, Windows kernel route inspection, TCP port check, and ping latency.
- **Root Cause Analysis & Misroute Detection**: Automatic alert when private LAN IP is routed to Internet gateway or vice-versa.
- **⚡ 1-Click Quick Fix**: Instantly add persistent route to Windows routing table.
- **Multi-column Layout**: Optimized viewports for Diagnostics, Configuration, and About tabs.
- **Instant Language QuickButton**: 1-click switching between VI, EN, and ZH with automatic Windows locale detection.
- **LAN OTA Updates**: Seamless auto-updates over local enterprise shares.

<a id="features"></a>
## Key Features

- **Dual-NIC Separation**: Keep Internet traffic on high-speed connection while routing company internal subnets through corporate LAN.
- **Bento Glassmorphism UI**: Real-time frosted glass effects, mesh background orbs, and GPU-optimized rendering.
- **Auto-Heal Engine**: Automatic background monitoring and routing self-healing.
- **LAN Over-The-Air (OTA)**: Effortless silent and manual updates over SMB network share.

---

## Directory Structure

```text
JA_Route/
├── lib/                       # Application source code
│   ├── main.dart              # Program entry point
│   ├── models/                # Data models
│   ├── services/              # Business logic and APIs
│   └── widgets/               # UI component widgets
├── assets/                    # Application static resources
├── .gitignore                 # Git exclusion patterns
├── README.md                  # Project documentation (this file)
├── LICENSE                    # License file
├── ABOUT.txt                  # Short description of the project
├── git_push.bat               # Auto push script to GitHub
└── pubspec.yaml               # Flutter package dependencies and version
```

---

<a id="setup"></a>
## Installation & Usage Guide

### System Requirements
*   OS: **Windows 10/11**
*   Interpreter: **Python 3.13** or equivalent environment.

<a id="quick-start"></a>
### How to Run
1. Install required dependencies:
   ```cmd
   flutter pub get
   ```
2. Run the application:
   ```cmd
   flutter run
   ```

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
