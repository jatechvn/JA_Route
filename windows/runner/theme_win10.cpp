// windows/runner/theme_win10.cpp
#include "theme_win10.h"
#include <dwmapi.h>
#include <fstream>

#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

// Undocumented DWM structures for Windows 10 blur behind
enum ACCENT_STATE {
    ACCENT_DISABLED = 0,
    ACCENT_ENABLE_GRADIENT = 1,
    ACCENT_ENABLE_TRANSPARENTGRADIENT = 2,
    ACCENT_ENABLE_BLURBEHIND = 3,
    ACCENT_ENABLE_ACRYLICBLURBEHIND = 4,
    ACCENT_ENABLE_HOSTBACKDROP = 5
};

struct ACCENT_POLICY {
    int AccentState;
    int AccentFlags;
    int GradientColor; // ABGR format
    int AnimationId;
};

struct WINDOWCOMPOSITIONATTRIBDATA {
    int Attrib; // WCA_ACCENT_POLICY = 19
    void* pvData;
    unsigned int cbData;
};

typedef BOOL (WINAPI *pSetWindowCompositionAttribute)(HWND, WINDOWCOMPOSITIONATTRIBDATA*);

void ApplyThemeWin10(HWND hwnd, bool is_dark) {
  BOOL enable_dark_mode = is_dark ? TRUE : FALSE;
  
  // Set both 19 and 20 attributes for immersive dark mode compatibility
  DwmSetWindowAttribute(hwnd, 19, &enable_dark_mode, sizeof(enable_dark_mode));
  DwmSetWindowAttribute(hwnd, 20, &enable_dark_mode, sizeof(enable_dark_mode));

  // Enable Acrylic Blur Behind on Windows 10 using SetWindowCompositionAttribute
  HMODULE hUser = GetModuleHandleA("user32.dll");
  if (hUser) {
    pSetWindowCompositionAttribute setWindowCompAttr = 
        (pSetWindowCompositionAttribute)GetProcAddress(hUser, "SetWindowCompositionAttribute");
    if (setWindowCompAttr) {
      // ABGR format: Alpha (A), Blue (B), Green (G), Red (R)
      int alpha = 0x66; // ~40% opacity
      
      // Ensure alpha is never exactly 0 in Acrylic mode to prevent black background glitch
      if (alpha == 0) {
        alpha = 1;
      }
      
      int r = is_dark ? 0x1B : 0xF3;
      int g = is_dark ? 0x15 : 0xF4;
      int b = is_dark ? 0x14 : 0xF6;
      
      int tint_color = (alpha << 24) | (b << 16) | (g << 8) | r;
      
      // Use ACCENT_ENABLE_BLURBEHIND (3) instead of ACCENT_ENABLE_ACRYLICBLURBEHIND (4) to ensure 100% smooth dragging and resizing
      ACCENT_POLICY policy = { ACCENT_ENABLE_BLURBEHIND, 2, tint_color, 0 };
      WINDOWCOMPOSITIONATTRIBDATA data = { 19, &policy, sizeof(policy) }; // WCA_ACCENT_POLICY = 19
      setWindowCompAttr(hwnd, &data);
    }
  }

  // Extend window frame with a 1px top margin to enable client composition blur without drawing duplicate inner borders
  MARGINS margins = { 0, 0, 1, 0 };
  DwmExtendFrameIntoClientArea(hwnd, &margins);

  // Recalculate the non-client frame without resizing the Flutter surface
  // while a theme platform-channel call is being handled.
  SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
               SWP_NOACTIVATE | SWP_FRAMECHANGED);

  // Simulate focus change message to force titlebar caption repaint
  SendMessage(hwnd, WM_NCACTIVATE, FALSE, 0);
  SendMessage(hwnd, WM_NCACTIVATE, TRUE, 0);
}
