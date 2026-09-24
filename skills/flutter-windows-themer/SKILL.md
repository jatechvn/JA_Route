---
name: flutter-windows-themer
description: Detailed guide and rules for customizing native Windows 10/11 windows, composition blur (Aero/Acrylic), single-instance Mutexes, and glassmorphic UI performance.
---

# Window Theming and Customization Guide (Windows 10 & 11 Integration Guide)

Specifications for native Windows 10 & 11 window integration, corner rounding, composition blur (Aero/Acrylic), Single-Instance Mutex enforcement, and glassmorphic UI optimization.

## 1. Dynamic Platform Detection

Windows 11 supports native rounded corners and fluid design languages, whereas Windows 10 relies on sharp rectangular frames. Trying to clip a transparent window with rounded corners on Windows 10 causes black corner rendering artifacts.

To solve this, the application dynamically detects whether it is running on Windows 11 or an older version (Windows 10) inside the Dart styling layer.

### Dart Detection Logic

Windows 11 build numbers start at `22000`. The app reads `Platform.operatingSystemVersion` and parses the build number:

```dart
  void _detectWindowsVersion() {
    if (!Platform.isWindows) return;
    try {
      final versionStr = Platform.operatingSystemVersion;
      final match = RegExp(r'Build\s+(\d+)').firstMatch(versionStr);
      if (match != null) {
        final buildNumber = int.tryParse(match.group(1) ?? '') ?? 0;
        _isWin11 = buildNumber >= 22000;
      }
    } catch (_) {}
  }
```

---

## 2. C++ Runner Architecture (Windows Theming Modules)

To prevent code pollution and build conflicts, the native theme drawing logic is split into isolated files under `windows/runner/`:

```text
windows/runner/
├── theme_win10.h / theme_win10.cpp   # Windows 10 composition blur (Aero Blur)
├── theme_win11.h / theme_win11.cpp   # Windows 11 native Acrylic title bar
└── win32_window.h / win32_window.cpp # Version check dispatcher & window frame creation
```

### 1. Windows 11 Theming (`theme_win11.cpp`)

**⚠️ Scope warning, learned the hard way:** `DWMWA_SYSTEMBACKDROP_TYPE` (below) reliably
blurs the native **title bar/caption chrome** on Win11. It does **not** blur a Flutter
app's own client-area content — that API only produces genuine blur for
DirectComposition-based apps (WinUI3/UWP). Flutter presents via a plain D3D swapchain,
so on its own this code path just yields flat, **unblurred** see-through transparency
for the client area — confirmed by actually zooming into a screenshot with sharp detail
(e.g. hair strands, small text) behind the window: with only this code, the detail
stays perfectly crisp through the "blurred" window. A full-screen/maximized test won't
catch this, since there's nothing sharp behind the window to reveal the missing blur —
always test with the window floating over content that has fine detail.

**Getting title bar blur and client-area blur to coexist looked like an
irreconcilable trade-off for a long time — it wasn't. The real bug was a third
party silently destroying the composition setup this code depends on.** Chasing
this down took a full round-trip through several wrong conclusions, so the whole
story is worth keeping — the wrong conclusions are exactly what to not repeat:

1. `DWMWA_SYSTEMBACKDROP_TYPE` alone blurs the title bar correctly (DWM-native
   composited chrome, unaffected by the Flutter/D3D swapchain gap above) but leaves
   the client area flat/unblurred.
2. Adding the legacy `SetWindowCompositionAttribute` blur-behind call (the
   `ACCENT_POLICY` block below) fixes the client area — but appears to flatten the
   title bar to solid black as a side effect.
3. Re-issuing `DWMWA_SYSTEMBACKDROP_TYPE` + `DWMWA_USE_HOSTBACKDROPBRUSH` every call,
   *after* the accent-policy call, reclaims title-bar blur — but then the client area
   goes visibly hazy/murky, as if two blur layers were stacking.
4. **This is where it's easy to stop and conclude "pick one, it's a genuine API
   conflict, can't have both."** That conclusion is wrong. The actual cause: if the
   app also uses the `window_manager` package (very common in Flutter Windows apps)
   with `WindowOptions.titleBarStyle` set to anything, **`window_manager`'s own
   native plugin** (`windows/window_manager.cpp`, method `SetTitleBarStyle`) calls
   `DwmExtendFrameIntoClientArea(hwnd, {0,0,0,0})` — silently **resetting the glass
   extension** this file sets up at native window-create time back to *none*. That
   call fires from Dart during `windowManager.waitUntilReadyToShow(options, ...)`,
   which runs *after* `Win32Window::Create()` (and this function's `is_startup=true`
   call) but *before* the app's own Dart-side theme sync fires this function again.
   So every subsequent call — accent policy, backdrop type, host backdrop brush,
   all of it — was operating on a window with no glass region to actually composite
   into. That's what made the title-bar/client-area behavior swing unpredictably
   between experiments: the actual foundation was being torn down by a third party
   in between, and each "fix" was really just interacting differently with an
   already-broken state.
   `window_manager`'s `SetBackgroundColor` (triggered by `WindowOptions.backgroundColor`)
   is a second, milder instance of the same problem: it sets its own competing
   `SetWindowCompositionAttribute` accent policy independently of this file's.

**The actual fix has two parts:**

- **Stop the interference at the source.** Don't pass `titleBarStyle` or
  `backgroundColor` in `WindowOptions` if a custom native theme file
  (`theme_win10.cpp`/`theme_win11.cpp`) already owns composition. The native runner
  already creates a normal-titlebar, non-transparent window by default — nothing
  needs `window_manager` to set those two specifically. Keep using `window_manager`
  freely for everything else (size, position, close-prevention, focus, drag) — those
  don't touch composition and are fine.
- **Defense in depth: re-assert the glass extension unconditionally, every call**
  (not just `is_startup`), so even an unknown future interferer touching it gets
  silently corrected on the next theme sync:

```cpp
void ApplyThemeWin11(HWND hwnd, bool is_dark, bool is_startup) {
  BOOL enable_dark_mode = is_dark ? TRUE : FALSE;
  DwmSetWindowAttribute(hwnd, 20, &enable_dark_mode, sizeof(enable_dark_mode)); // DWMWA_USE_IMMERSIVE_DARK_MODE

  // UNCONDITIONAL — every call, not gated by is_startup. See the story above:
  // window_manager's SetTitleBarStyle resets this to {0,0,0,0} after our
  // is_startup=true call already ran, so re-asserting here on every
  // subsequent theme sync is what actually keeps blur working at all.
  MARGINS margins = { -1, -1, -1, -1 };
  DwmExtendFrameIntoClientArea(hwnd, &margins);

  int r = is_dark ? 0x0B : 0xF8, g = is_dark ? 0x0F : 0xFA, b = is_dark ? 0x19 : 0xFC;

  // Client-area blur (see theme_win10.cpp for the shared ACCENT_STATE /
  // ACCENT_POLICY / WINDOWCOMPOSITIONATTRIBDATA struct defs — either share
  // them via a common header or duplicate them in theme_win11.cpp).
  HMODULE hUser = GetModuleHandleA("user32.dll");
  if (hUser) {
    pSetWindowCompositionAttribute setWindowCompAttr =
        (pSetWindowCompositionAttribute)GetProcAddress(hUser, "SetWindowCompositionAttribute");
    if (setWindowCompAttr) {
      int alpha = 0x4D; // ~30% — Win11's material already carries its own noise/blur
      if (alpha == 0) alpha = 1; // Zero-alpha guard
      int tint_color = (alpha << 24) | (b << 16) | (g << 8) | r; // ABGR format
      ACCENT_POLICY policy = { ACCENT_ENABLE_ACRYLICBLURBEHIND, 2, static_cast<DWORD>(tint_color), 0 };
      WINDOWCOMPOSITIONATTRIBDATA data = { WCA_ACCENT_POLICY, &policy, sizeof(policy) };
      setWindowCompAttr(hwnd, &data);
    }
  }

  // Title-bar blur — also unconditional, every call, after the accent-policy
  // call above. With the glass extension no longer being wiped out from
  // under it, this combo now blurs BOTH the title bar and the client area
  // correctly at the same time — confirmed visually and by the app author.
  int backdrop_type = 3; // DWMSBT_TRANSIENTWINDOW (Acrylic)
  DwmSetWindowAttribute(hwnd, 38, &backdrop_type, sizeof(backdrop_type)); // DWMWA_SYSTEMBACKDROP_TYPE
  BOOL use_host_backdrop_brush = TRUE;
  DwmSetWindowAttribute(hwnd, 17, &use_host_backdrop_brush, sizeof(use_host_backdrop_brush)); // DWMWA_USE_HOSTBACKDROPBRUSH
}
```

And the Dart side — `WindowOptions` must NOT set `titleBarStyle` or `backgroundColor`
when this native setup is in play:

```dart
// main.dart — deliberately no titleBarStyle / backgroundColor here.
// window_manager is only used for size/position/close-prevention/focus;
// composition is owned entirely by theme_win10.cpp / theme_win11.cpp.
const windowOptions = WindowOptions(
  size: Size(1180, 900),
  minimumSize: Size(900, 640),
  title: appName,
);
await windowManager.waitUntilReadyToShow(windowOptions, () async {
  await windowManager.setPreventClose(true);
  await windowManager.show();
  await windowManager.focus();
});
```

**If a future symptom looks like "blur works sometimes, or one region blurs while
another doesn't, with no code change in between":** suspect another package's
native Windows plugin touching `DwmExtendFrameIntoClientArea`,
`SetWindowCompositionAttribute`, or `DwmSetWindowAttribute` behind your back before
assuming it's an irreconcilable DWM API conflict. Grep that package's `windows/*.cpp`
for those three calls first — it's a five-minute check that would have saved most of
the time spent here.

Windows 10 has no `DWMWA_SYSTEMBACKDROP_TYPE`/`DWMWA_CAPTION_COLOR` equivalent — its
title bar stays whatever `DWMWA_USE_IMMERSIVE_DARK_MODE` gives it (flat black/white,
no blur, no custom color), which is an acceptable platform limitation there.

### 2. Windows 10 Theming (`theme_win10.cpp`)

Windows 10 uses the undocumented `SetWindowCompositionAttribute` API from `user32.dll`. To maintain performance and visual excellence, the implementation applies three critical optimizations:
- **Aero Blur (`ACCENT_ENABLE_BLURBEHIND` = 3)**: Classic Aero blur is used instead of Acrylic. Aero Blur is fully hardware-accelerated, ensuring **100% lag-free dragging, movement, and resizing** of desktop windows.
- **Zero-Alpha Guard**: Acrylic/Blur composition fails (renders solid black) if the alpha channel is exactly `0`. We force alpha to `1` as a safety check.
- **Optimized Frame Extension margins `{0, 0, 1, 0}`**: Extending margins completely (`-1`) instructs DWM to draw duplicate window borders inside the client area. We extend only the top by `1px` to authorize transparent backdrop composition without rendering duplicate borders.

```cpp
void ApplyThemeWin10(HWND hwnd, bool is_dark) {
  BOOL enable_dark_mode = is_dark ? TRUE : FALSE;
  DwmSetWindowAttribute(hwnd, 19, &enable_dark_mode, sizeof(enable_dark_mode));
  DwmSetWindowAttribute(hwnd, 20, &enable_dark_mode, sizeof(enable_dark_mode));

  HMODULE hUser = GetModuleHandleA("user32.dll");
  if (hUser) {
    pSetWindowCompositionAttribute setWindowCompAttr = 
        (pSetWindowCompositionAttribute)GetProcAddress(hUser, "SetWindowCompositionAttribute");
    if (setWindowCompAttr) {
      int alpha = 0x66; // ~40% opacity
      if (alpha == 0) alpha = 1; // Zero-alpha guard
      
      int r = is_dark ? 0x1B : 0xF3;
      int g = is_dark ? 0x15 : 0xF4;
      int b = is_dark ? 0x14 : 0xF6;
      int tint_color = (alpha << 24) | (b << 16) | (g << 8) | r; // ABGR format
      
      ACCENT_POLICY policy = { ACCENT_ENABLE_BLURBEHIND, 2, tint_color, 0 };
      WINDOWCOMPOSITIONATTRIBDATA data = { 19, &policy, sizeof(policy) };
      setWindowCompAttr(hwnd, &data);
    }
  }

  // Authorize composition with a 1px top margin to prevent duplicate border rendering
  MARGINS margins = { 0, 0, 1, 0 };
  DwmExtendFrameIntoClientArea(hwnd, &margins);

  // Force window repaint to apply layout alterations
  RECT rect;
  GetWindowRect(hwnd, &rect);
  SetWindowPos(hwnd, nullptr, 0, 0, (rect.right - rect.left) - 1, (rect.bottom - rect.top), SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
  SetWindowPos(hwnd, nullptr, 0, 0, (rect.right - rect.left), (rect.bottom - rect.top), SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);

  SendMessage(hwnd, WM_NCACTIVATE, FALSE, 0);
  SendMessage(hwnd, WM_NCACTIVATE, TRUE, 0);
}
```

### 3. Window Title Bounding Box Fix (`win32_window.cpp`)

- **The Issue**: GDI text rendering on transparent windows draws a fallback solid white/black box around the native title text.
- **The Fix**: During window creation, if the OS is Windows 10, we pass an empty string `L""` as the window title. This completely hides the title bar text and removes the visual box. The taskbar entry remains identifiable because it automatically falls back to the executable name (`ja_adb_tool`).

```cpp
  HWND window = CreateWindow(
      window_class, IsWindows11OrGreater() ? title.c_str() : L"", WS_OVERLAPPEDWINDOW,
      Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
      Scale(size.width, scale_factor), Scale(size.height, scale_factor),
      nullptr, nullptr, GetModuleHandle(nullptr), this);
```

---

## 3. Single-Instance Window Activation (C++)

To prevent users from opening parallel windows of the application, we implement native single-instance Mutex checks and window redirection when launching.

### 1. Verification Logic (`main.cpp`)

We attempt to create a named Mutex at the start of `wWinMain`. If `GetLastError() == ERROR_ALREADY_EXISTS`, we find and activate the first instance window, then exit:

```cpp
  HANDLE hMutex = ::CreateMutexW(nullptr, TRUE, L"Local\\ja_adb_tool_single_instance_mutex");
  if (hMutex == nullptr) {
    return EXIT_FAILURE;
  }

  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    ::CloseHandle(hMutex);

    // Try to find the existing window of the first instance
    HWND existing_hwnd = nullptr;
    for (int i = 0; i < 20; ++i) { // Retry for up to 2 seconds
      FindInstanceParams params;
      ::EnumWindows(FindInstanceWindowProc, reinterpret_cast<LPARAM>(&params));
      if (params.hwndFound != nullptr) {
        existing_hwnd = params.hwndFound;
        break;
      }
      ::Sleep(100);
    }

    if (existing_hwnd != nullptr) {
      if (::IsIconic(existing_hwnd)) {
        ::ShowWindow(existing_hwnd, SW_RESTORE);
      } else {
        ::ShowWindow(existing_hwnd, SW_SHOW);
      }
      ::SetForegroundWindow(existing_hwnd);
      ::SetFocus(existing_hwnd);
    }
    return EXIT_SUCCESS;
  }
```

### 2. Window Property Identification (`main.cpp`)

On successful creation, we attach a custom property string `JA_ADB_TOOL_INSTANCE` to the window handle:

```cpp
  ::SetPropW(window.GetHandle(), L"JA_ADB_TOOL_INSTANCE", (HANDLE)1);
```

During window enumeration, we fetch the property to ensure we target only our specific app:

```cpp
BOOL CALLBACK FindInstanceWindowProc(HWND hwnd, LPARAM lParam) {
  FindInstanceParams* params = reinterpret_cast<FindInstanceParams*>(lParam);
  wchar_t className[256];
  if (::GetClassNameW(hwnd, className, 256) > 0) {
    if (::wcscmp(className, L"FLUTTER_RUNNER_WIN32_WINDOW") == 0) {
      if (::GetPropW(hwnd, L"JA_ADB_TOOL_INSTANCE") == (HANDLE)1) {
        params->hwndFound = hwnd;
        return FALSE; // Stop search
      }
    }
  }
  return TRUE;
}
```

### 3. Cleanup on Destruction (`flutter_window.cpp`)

Always remove the property list entry before the window is destroyed:

```cpp
  HWND hwnd = GetHandle();
  if (hwnd != nullptr) {
    ::RemovePropW(hwnd, L"JA_ADB_TOOL_INSTANCE");
  }
```

---

## 4. Dart Styling Architecture (Split Modules)

To allow the native Windows backdrop blur to show through, the Dart layer uses OS-specific theme configurations:

```text
lib/modules/ui/
├── styles.dart        # Platform coordinate dispatcher
├── styles_win10.dart  # Translucent theme colors tailored for Windows 10
└── styles_win11.dart  # Transparent theme colors tailored for Windows 11
```

### 1. Translucency Adaptations
- **Windows 10 (`styles_win10.dart`)**: Uses semi-opaque solid overlays to contrast with the Aero composition blur:
  - `sidebarBg` has a higher opacity (`~70%`) to block high-frequency desktop changes.
  - `cardBg` utilizes `~85%` opacity for clear item definition.
- **Windows 11 (`styles_win11.dart`)**: Uses lower opacities and subtle borders to let the fluid native system Acrylic bleed through cleanly.

### 2. Font and Text Color Adaptations
- **Premium Font Family**: The application applies the premium modern font `Outfit` codebase-wide. It is registered inside the global `ThemeData` textTheme to ensure it applies automatically to all Text widgets:
  ```dart
  ThemeData get themeData {
    return ThemeData(
      // ...
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontFamily: 'Outfit'),
      ),
    );
  }
  ```
- **Dynamic Text Colors**: When the theme switches (Light/Dark mode), text colors must adapt dynamically to maintain legibility over blurred backgrounds:
  - **Primary Text (`textPrimary`)**: Transitions between `Colors.white` (Dark Mode) and `Colors.black87` (Light Mode).
  - **Secondary Text (`textSecondary`)**: Transitions between `Colors.white70` (Dark Mode) and `Colors.black54` (Light Mode).
  - **Component Borders (`borderTheme`)**: Transitions between `Colors.white10` (Dark Mode) and `Colors.black12` (Light Mode).
- **State Integration**: Text widgets must listen to the active `ThemeProvider` rather than declaring static colors:
  ```dart
  Text(
    'Sample Text',
    style: TextStyle(color: theme.textPrimary, fontSize: 13),
  )
  ```

---

## 5. UI Best Practices for Glassmorphic & Performance-Minded Apps

### 1. Glassmorphic Modal Backdrops (Popup Blurring)

When opening modal dialogs over a transparent/blurred window client area, wrap the returned widget in a `BackdropFilter` using blur variables to separate content layers:

```dart
showDialog(
  context: context,
  builder: (context) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
    child: AlertDialog(
      backgroundColor: themeProvider.cardBg,
      title: Text('Dialog Title'),
      content: Text('Dialog Content'),
    ),
  ),
);
```

### 2. Lazy Loading Asynchronous Data Pattern

When querying heavy hardware info or list details (such as package labels or files via ADB shell):
1. **Immediate Initial Load**: Fetch basic keys or IDs (e.g. package names) first and render the list immediately using default placeholders.
2. **Background Query**: Spawn a secondary asynchronous background task to fetch details (e.g. application labels using `dumpsys package | grep ...`).
3. **In-place State Update**: Once background futures return, write details back to the active models in-place and notify listeners. This prevents blocking UI loads and keeps lists responsive.

Implementation Example (`logic.dart`):

```dart
  Future<void> loadApps() async {
    // 1. Instantly pull package names
    final userResult = await getAdbShellOutput(['pm', 'list', 'packages', '-3']);
    _apps = parsePackages(userResult);
    _loadingApps = false;
    notifyListeners(); // Render initial list immediately

    // 2. Fetch app names in background without blocking UI
    unawaited(_loadLabelsInBackground());
  }
```

### 3. Cycle Locale Globals (Lightweight i18n)

Instead of importing heavy localization setups, implement a cyclic i18n structure:
- Bind translations to a ChangeNotifier `LanguageProvider`.
- Use a lightweight extension on BuildContext `context.tr('key')`.
- Place a single icon button (`Icons.language`) in settings to cycle languages (`en` -> `vi` -> `zh`) instantly.

---

## 6. Bento Glassmorphism UI Template (canonical source)

**As of this revision, don't hand-roll glass/mesh widgets from scratch.** A finished, ready-to-copy UI kit lives at `PROJECT_DART/dart_sample/flutter_ui_template/` — copy its `lib/theme/`, `lib/widgets/`, `lib/layout/` folders straight into a project's `lib/` rather than reimplementing any of section 6 by hand. `JA_TetherPC` is the first production app remade from this template — use it as a working reference when the template's own docs aren't enough.

An earlier revision of this section hand-wrote a smaller set of components (`MeshOrb`, `GlassContainer`, `PillBadge`, a `StepCard`, a font-pairing note) inline here, inspired by an external reference page. The template below is the matured, superset version of that same idea — it has since absorbed all of it and grown well past it. Treat the template as authoritative; this section now only indexes what's in it.

### 6.1 What's in the template

```text
flutter_ui_template/
├── README.md                            # Integration guide (copy-paste steps below)
├── lib/
│   ├── theme/
│   │   ├── app_colors.dart              # AppColors token model (see 6.2)
│   │   ├── styles_win10.dart            # win10DarkColors / win10LightColors
│   │   ├── styles_win11.dart            # win11DarkColors / win11LightColors
│   │   └── theme_provider.dart          # ChangeNotifier + context.appColors extension
│   ├── widgets/
│   │   ├── glass_widgets.dart           # MeshOrb, MeshBackground, GlassContainer,
│   │   │                                # PillBadge, BentoCard, WaveIndicator,
│   │   │                                # DynamicIslandCapsule, SlidingPillTabBar,
│   │   │                                # GlowingActionButton (see 6.3)
│   │   └── glass_dialog.dart            # GlassDialog — standard modal, 22px radius
│   ├── layout/
│   │   └── dashboard_shell.dart         # DashboardShell — top header + pill tabs (see 6.4)
│   └── sample_views/                    # Reference usage: bento overview, device list, stats
└── windows_native_guide/
    └── windows_blur_setup.md            # Quick-start native blur setup (condensed —
                                          # sections 1-3 above remain the authoritative,
                                          # battle-tested version for real bugs/edge cases)
```

### 6.2 `AppColors` token model

The template's `AppColors` (in `theme/app_colors.dart`) is a strict superset of the plain `bgPrimary`/`cardBg`/`textPrimary`/`borderDefault`/`accentColor` fields this skill described in earlier revisions — add the missing fields rather than inventing parallel ones if a project already has an older `AppColors`:

```dart
// Structural surfaces
bgPrimary, bgSecondary, cardBg, cardHoverBg, subCardBg, subCardBorder,
sidebarBg, headerBg, headerBorder, borderDefault

// Text
textPrimary, textSecondary, textMuted

// Accent palette (semantic, not just one blue)
accentColor,               // primary blue, #0066FF
primaryGlow,                // blue glow shadow color, ~35% alpha of accentColor
accentCyan, accentEmerald, accentAmber, accentRose, accentPurple

// Mesh background orbs
orb1, orb2, orb3, orbOpacity   // orbOpacity: ~0.12 (Win11 dark) to ~0.18 (Win11 light) —
                                 // keep low for control-heavy screens; this is ambient tint,
                                 // not a poster background

// Frosted glass surfaces
glassBg, glassBorder, glassHighlight
```

Concrete values for all 4 combinations (Win10/Win11 × Dark/Light) are in `styles_win10.dart`/`styles_win11.dart` — copy them as-is rather than re-deriving; they're already tuned per-platform (Win10 has no native client blur to layer under, so its `glassBg` is more opaque than Win11's).

### 6.3 Widget catalog (`widgets/glass_widgets.dart`, `widgets/glass_dialog.dart`)

| Widget | Use for |
|---|---|
| `MeshOrb` / `MeshBackground` | 3 drifting blurred circles behind the app content — ambient depth, not decoration to stack more of |
| `GlassContainer` | Generic frosted-glass panel (blur + border + top highlight line) — the base every other glass surface builds on |
| `PillBadge` | Small status/version/mode indicator, optional glowing dot, optional icon |
| `BentoCard` | The main content card for a Bento-grid dashboard — hover lift, `isFeatured` glow border variant |
| `WaveIndicator` | 3-bar animated equalizer, used inside `DynamicIslandCapsule` for "actively running" |
| `DynamicIslandCapsule` | iPhone-style status capsule for the header (running/standby state + optional sub-text like device count) |
| `SlidingPillTabBar` | Horizontal pill navigation — **replaces the older vertical sidebar pattern** (see 6.4) |
| `GlowingActionButton` | Primary CTA with gradient fill + glow shadow; `isDestructive: true` for stop/delete actions |
| `GlassDialog` | Standard modal shell (22px radius, title bar + close button built in) — use instead of raw `showDialog` + `AlertDialog` |
| `DetailDialog` | `GlassDialog` variant for "item details" (badges + subtitle + description + tag block + actions) — project/release/device detail views |
| `KbdTag` | Small keyboard-shortcut badge (e.g. `ESC`, `Ctrl+K`) |
| `BorderBeam` | Animated rotating gradient border around a card/container — sparing use for a single featured/live element |
| `SpotlightGlow` | Mouse-follow radial highlight on hover — wrap a card's child |
| `CommandPalette` / `showCommandPalette()` / `CommandPaletteShortcut` | Ctrl+K spotlight search over app actions — wrap the root content with `CommandPaletteShortcut` once, build the item list from current app state per open |
| `showAppToast()` | Transient glass toast notification (auto-dismiss), via `Overlay` |
| `FilterSearchDock` | Search field + toggleable filter pill row, above a list/grid view |

All widgets take `colors` (an `AppColors`) as a constructor parameter rather than reading `ThemeProvider` internally — keeps them pure/testable. Call sites fetch it once via `context.appColors` and pass it down.

**Performance discipline (verified against `UI_DESIGN_Sample.html`'s own perf pass):** every widget that animates continuously (`MeshOrb`, `BorderBeam`) or sits inside a `BackdropFilter` (`GlassContainer`) is wrapped in its own `RepaintBoundary` — otherwise a `BackdropFilter`'s expensive blur resample, or a ticking `AnimationController`, drags nearby unrelated widgets into the same repaint. `SpotlightGlow` tracks the cursor via a `ValueNotifier<Offset?>` + `ValueListenableBuilder` scoped to just the glow overlay, not `setState` — a raw `MouseRegion.onHover` can fire far more often than the frame rate, and `setState` would rebuild the wrapped `child` on every event. Follow the same two rules (`RepaintBoundary` around anything that repaints on its own timer, `ValueNotifier` instead of `setState` for anything driven by high-frequency pointer events) when adding new widgets here.

### 6.4 `DashboardShell` layout (`layout/dashboard_shell.dart`)

The template's shell **replaces the sidebar-navigation layout** used before this revision with a top-header pattern: brand mark + app name + version + optional DEBUG `PillBadge`, a centered `SlidingPillTabBar` for view switching, a `DynamicIslandCapsule` showing live status, then theme-toggle and settings icon buttons. Content below is an `AnimatedSwitcher` over the current view, with `MeshBackground` layered behind everything.

When remaking an existing app's shell (see `JA_TetherPC` for a completed example): replace the sidebar `Row` layout with `DashboardShell`-style top navigation rather than retrofitting pill tabs into a sidebar — the two navigation patterns don't mix well visually.

### 6.5 Font note

`DynamicIslandCapsule` and the version label in `DashboardShell` already set `fontFamily: 'JetBrains Mono'` directly. **This only renders correctly once the font is actually registered** — either add the `google_fonts` package, or bundle the `.ttf` under `assets/fonts/` and declare it in `pubspec.yaml`'s `fonts:` section. Check this before assuming the mono styling "isn't working" — a missing font registration silently falls back to the default UI font with no error.

### 6.6 Integration steps (from the template's own README)

1. Copy `lib/theme/`, `lib/widgets/`, `lib/layout/` into the target project's `lib/`.
2. Register `ChangeNotifierProvider(create: (_) => ThemeProvider())` in `main.dart`, set `fontFamily: 'Outfit'` on the app's `ThemeData`.
3. Either use `DashboardShell` directly as `home:`, or pull individual widgets (`BentoCard`, `GlowingActionButton`, `GlassDialog`, ...) into an existing layout incrementally.
4. If the project already has its own `AppColors`/`ThemeProvider` (pre-dating this template), merge token sets per 6.2 instead of running two parallel theming systems side by side.

**Adoption note:** still apply incrementally on an existing app — start with `GlassContainer`/`BentoCard` since they have the most reuse, verify against `flutter-project-rules` (const constructors, ≤4 widget nesting levels) as each piece goes in, and profile `MeshBackground` on lower-end Windows 10 hardware (3 animated `ImageFiltered` blurs redraw every frame).
