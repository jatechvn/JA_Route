---
name: python-cli-ui-builder
description: >-
  Framework and design pattern for building professional, color-coded, user-friendly Python CLI tools.
  Includes adaptive dark/light terminal theme detection, cross-platform instant 1-keypress selection, smart box-drawing alignment, path defaults, batch processing, and summary table formatting.
  Use this skill whenever asked to build or refactor a Python CLI tool or script with interactive UI and batch processing features.
---

# Python CLI UI & Feature Builder Skill

This skill provides a complete, reusable architecture and copy-pasteable template for creating professional, robust Python command-line tools. It incorporates UI/UX best practices, adaptive dark/light terminal color theming, cross-platform single-key input, pixel-perfect box-drawing alignment, batch processing, and error-isolated execution.

---

## 1. Core Architectural Pillars

### A. Windows ANSI Virtual Terminal & UTF-8 Console Initialization
Enables native 24-bit/16-color ANSI escape codes (`\033[...]`) and UTF-8 I/O on Windows CMD and PowerShell consoles:
```python
if sys.platform == 'win32':
    try:
        if hasattr(sys.stdout, 'reconfigure'):
            sys.stdout.reconfigure(encoding='utf-8')
            sys.stderr.reconfigure(encoding='utf-8')
            sys.stdin.reconfigure(encoding='utf-8')
        import ctypes
        kernel32 = ctypes.windll.kernel32
        # ENABLE_PROCESSED_OUTPUT (1) | ENABLE_WRAP_AT_EOL_OUTPUT (2) | ENABLE_VIRTUAL_TERMINAL_PROCESSING (4)
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
    except Exception:
        pass
```

### B. Adaptive Dark/Light Terminal Color Engine
Bright text (yellow, white) is invisible on white/light terminal backgrounds (PuTTY, Xshell, macOS Terminal, legacy CentOS). This engine dynamically detects terminal luminance and swaps palettes:
- **Detection Priority**: `--theme` CLI flag > `CLI_THEME` env var > `COLORFGBG` env var > OSC 11 (`\033]11;?\033\\` with 0.3s non-blocking timeout) > Default `dark`.
- **Light Palette Mapping**: Uses saturated standard ANSI codes (`\033[31m` - `\033[36m`), maps `YELLOW` / `BRIGHT_YELLOW` to high-contrast Dark Magenta/Purple (`\033[35m`, `\033[1;35m`) for perfect legibility on white, and inverts `WHITE` / `BRIGHT_WHITE` to dark/bold black (`\033[30m`, `\033[1;30m`).

```python
class Color:
    """Default dark palette values for safe import-time usage."""
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    UNDERLINE = "\033[4m"
    BLACK = "\033[30m"; RED = "\033[91m"; GREEN = "\033[92m"; YELLOW = "\033[93m"
    BLUE = "\033[94m"; MAGENTA = "\033[95m"; CYAN = "\033[96m"; WHITE = "\033[97m"; GRAY = "\033[90m"
    BRIGHT_RED = "\033[1;91m"; BRIGHT_GREEN = "\033[1;92m"; BRIGHT_YELLOW = "\033[1;93m"
    BRIGHT_BLUE = "\033[1;94m"; BRIGHT_MAGENTA = "\033[1;95m"; BRIGHT_CYAN = "\033[1;96m"; BRIGHT_WHITE = "\033[1;97m"

def configure_theme(theme: Optional[str] = None, no_color: bool = False) -> str:
    """Call once at the start of main() right after parsing arguments."""
    ...
```

### C. Cross-Platform Instant Single-Key Selection (`get_single_key_choice`)
Captures a single keypress instantly without waiting for the user to press `Enter`:
- **Windows**: `msvcrt.getwch()` captures instant keys, Enter (default), and Ctrl+C (`\x03`).
- **Linux/macOS (POSIX)**: Uses `termios` & `tty.setraw()`, restoring terminal mode in `finally` before printing.
- **Fallback**: Gracefully falls back to standard `input()` when piped or non-interactive.

```python
def get_single_key_choice(prompt_text: str, valid_keys: Sequence[str], default_key: str = "1") -> str:
    print(prompt_text, end="", flush=True)
    if sys.platform == 'win32':
        try:
            import msvcrt
            while True:
                ch = msvcrt.getwch()
                if ch in ('\r', '\n'): return default_key
                elif ch in valid_keys: return ch
                elif ch == '\x03': raise KeyboardInterrupt
        except Exception: pass
    elif sys.stdin.isatty():
        try:
            import termios, tty
            fd = sys.stdin.fileno()
            old = termios.tcgetattr(fd)
            try:
                tty.setraw(fd)
                while True:
                    ch = sys.stdin.read(1)
                    if ch in ('\r', '\n'): return default_key
                    elif ch in valid_keys: return ch
                    elif ch == '\x03': raise KeyboardInterrupt
            finally:
                termios.tcsetattr(fd, termios.TCSADRAIN, old)
        except KeyboardInterrupt: raise
        except Exception: pass
    inp = input().strip(' "\' \t\r\n')
    return inp if inp in valid_keys else default_key
```

### D. Dynamic Box-Drawing & Alignment Engine
Hardcoding table rows with manual space padding causes border misalignments due to 2-cell wide characters (emojis `✔ ✖ ⚠ ⚡ 👉 📁 📄`, CJK):
- **`_display_width(text)`**: Calculates actual rendered terminal cells.
- **`_pad_display(text, width)`**: Spaces cells according to visual width.
- **`_truncate_display(text, width, keep_tail=True)`**: Truncates overlong text while preserving timestamps/extensions at the tail.
- **Unified border & row generation**: Auto-generates borders (`┌┬┐`, `├┼┤`, `└┴┘`) and cells from `(ColumnName, Width)` definitions.

### E. Reliable Script Directory Resolution
Resolves paths relative to where the script/executable actually resides (instead of `os.getcwd()`), preventing files from dropping into `C:\Users\<User>` when launched via shortcuts:
```python
def get_script_dir() -> Path:
    if getattr(sys, 'frozen', False):
        return Path(os.path.dirname(os.path.abspath(sys.executable)))
    else:
        return Path(os.path.dirname(os.path.abspath(__file__)))
```

### F. Multi-Mode Architecture
- **Mode 1**: Single Item Interactive Mode (with immediate prompts & validation).
- **Mode 2**: Batch Subfolder Scan Mode.
- **Mode 3**: Batch CSV / TXT Import Mode.
- **Mode 4**: Generate Template CSV File Mode (`mau_danh_sach.csv`).
- **Mode 5 / CLI Flags**: Full headless automation support (`--input`, `--csv-file`, `--generate-csv-template`, `--theme`, `--no-color`).

### G. Error Isolation & Dynamic Summary Table Reporting
Batch items are wrapped in individual `try...except` blocks. Failing items are marked `FAIL` without crashing the rest of the batch, followed by an adaptive summary table.

---

## 2. Reusable Template Reference

Use [`templates/cli_app_template.py`](templates/cli_app_template.py) as the starting point for any new script.

### Key Sections to Customize in New Scripts:
1. **`process_single_item(input_path, target_name, output_dir)`**: Implement your core business logic here.
2. **`print_header()`**: Customize tool title and subtitle banners.
3. **`_SUMMARY_COLUMNS`**: Adjust table columns to fit your specific data fields.
