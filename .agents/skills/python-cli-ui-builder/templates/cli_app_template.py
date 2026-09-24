#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Khung Mẫu Ứng Dụng CLI Python Chuyên Nghiệp (Professional CLI App Framework)
Bao gồm:
- Hỗ trợ màu ANSI chuẩn Windows CMD/PowerShell & Linux/macOS Terminal.
- Tự động nhận diện & thích ứng màu theo nền tối (Dark) / sáng (Light) của Terminal (OSC 11 / COLORFGBG / --theme).
- Chọn nhanh 1 phím (Instant Single-Key Selection) qua msvcrt (Windows) hoặc termios/tty raw mode (Linux/macOS).
- Căn chỉnh bảng biểu box-drawing tự động, đo chính xác độ rộng ký tự 2-cell (Emoji, CJK, ký hiệu).
- Cắt chuỗi thông minh (Smart Truncation) giữ lại phần đuôi quan trọng (timestamp, filename extension).
- Tự động định vị thư mục chứa script (get_script_dir) tránh lệch đường dẫn khi chạy shortcut.
- 4 Chế độ làm việc: Đơn lẻ (Single Mode), Quét Batch thư mục, Đọc file CSV/TXT, Tạo CSV mẫu.
- Bắt lỗi từng item độc lập (Error Isolation) không làm dừng cả mẻ batch.
- Bảng tổng hợp báo cáo trực quan dạng khung Unicode.
"""

import argparse
import csv
import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

# 1. Enable ANSI escape sequences on Windows console
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


# 2. Adaptive ANSI Color Palette & Theme Engine
class Color:
    """Bảng mã màu ANSI. Mặc định là bảng 'dark' (chữ sáng trên nền tối).
    Gọi configure_theme() để tự động nhận diện hoặc ép buộc theo nền tối/sáng thật.
    """
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    UNDERLINE = "\033[4m"

    BLACK = "\033[30m"
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN = "\033[96m"
    WHITE = "\033[97m"
    GRAY = "\033[90m"

    BRIGHT_RED = "\033[1;91m"
    BRIGHT_GREEN = "\033[1;92m"
    BRIGHT_YELLOW = "\033[1;93m"
    BRIGHT_BLUE = "\033[1;94m"
    BRIGHT_MAGENTA = "\033[1;95m"
    BRIGHT_CYAN = "\033[1;96m"
    BRIGHT_WHITE = "\033[1;97m"


_STYLE_CODES = {"RESET": "\033[0m", "BOLD": "\033[1m", "DIM": "\033[2m", "UNDERLINE": "\033[4m"}

_PALETTES = {
    "dark": {
        "BLACK": "\033[30m",
        "RED": "\033[91m", "GREEN": "\033[92m", "YELLOW": "\033[93m",
        "BLUE": "\033[94m", "MAGENTA": "\033[95m", "CYAN": "\033[96m", "WHITE": "\033[97m",
        "GRAY": "\033[90m",
        "BRIGHT_RED": "\033[1;91m", "BRIGHT_GREEN": "\033[1;92m", "BRIGHT_YELLOW": "\033[1;93m",
        "BRIGHT_BLUE": "\033[1;94m", "BRIGHT_MAGENTA": "\033[1;95m", "BRIGHT_CYAN": "\033[1;96m",
        "BRIGHT_WHITE": "\033[1;97m",
    },
    "light": {
        "BLACK": "\033[30m",
        "RED": "\033[31m", "GREEN": "\033[32m",
        # Màu vàng trên nền trắng rất khó nhìn -> đổi sang màu tím/tía sẫm (Dark Magenta) tương phản cao, dễ đọc
        "YELLOW": "\033[35m",
        "BLUE": "\033[34m", "MAGENTA": "\033[35m", "CYAN": "\033[36m", "WHITE": "\033[30m",
        "GRAY": "\033[90m",
        "BRIGHT_RED": "\033[1;31m", "BRIGHT_GREEN": "\033[1;32m",
        "BRIGHT_YELLOW": "\033[1;35m",
        "BRIGHT_BLUE": "\033[1;34m", "BRIGHT_MAGENTA": "\033[1;35m", "BRIGHT_CYAN": "\033[1;36m",
        "BRIGHT_WHITE": "\033[1;30m",
    },
}
_NO_COLOR_PALETTE = {name: "" for name in list(_PALETTES["dark"]) + list(_STYLE_CODES)}


def _detect_from_colorfgbg() -> Optional[str]:
    """Heuristic nhanh qua biến môi trường COLORFGBG='fg;bg'."""
    val = os.environ.get("COLORFGBG")
    if not val:
        return None
    try:
        bg = int(val.split(";")[-1])
    except (ValueError, IndexError):
        return None
    return "light" if bg in (7, 15) else "dark"


def _detect_from_osc11() -> Optional[str]:
    """Truy vấn màu nền thực tế của Terminal qua mã OSC 11 (hỗ trợ Linux/macOS/POSIX).
    Timeout ngắn 0.3s không làm đơ chương trình nếu Terminal không phản hồi.
    """
    if sys.platform == "win32":
        return None
    try:
        if not sys.stdin.isatty() or not sys.stdout.isatty():
            return None
        import select
        import termios
        import tty

        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setraw(fd)
            sys.stdout.write("\033]11;?\033\\")
            sys.stdout.flush()
            ready, _, _ = select.select([fd], [], [], 0.3)
            if not ready:
                return None
            response = os.read(fd, 100).decode("utf-8", errors="ignore")
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
    except Exception:
        return None

    match = re.search(r"rgb:([0-9a-fA-F]{2,4})/([0-9a-fA-F]{2,4})/([0-9a-fA-F]{2,4})", response)
    if not match:
        return None
    try:
        r, g, b = (round(int(c, 16) / (16 ** len(c) - 1) * 255) for c in match.groups())
    except (ValueError, ZeroDivisionError):
        return None
    luminance = 0.299 * r + 0.587 * g + 0.114 * b
    return "light" if luminance > 128 else "dark"


def _resolve_theme(forced: Optional[str]) -> str:
    """Thứ tự ưu tiên: ép buộc flag > biến môi trường > COLORFGBG > OSC 11 > mặc định 'dark'."""
    if forced in ("dark", "light"):
        return forced

    env_theme = os.environ.get("CLI_THEME", "").strip().lower()
    if env_theme in ("dark", "light"):
        return env_theme

    return _detect_from_colorfgbg() or _detect_from_osc11() or "dark"


def configure_theme(theme: Optional[str] = None, no_color: bool = False) -> str:
    """Áp dụng bảng màu theo nền tối/sáng đã ép buộc hoặc tự động nhận diện.
    Gọi 1 lần ở đầu main() ngay sau khi parse args, trước mọi thao tác in màu.
    """
    if no_color or os.environ.get("NO_COLOR") or not sys.stdout.isatty():
        palette, resolved = _NO_COLOR_PALETTE, "none"
    else:
        resolved = _resolve_theme(theme)
        palette = dict(_STYLE_CODES)
        palette.update(_PALETTES[resolved])

    for name, code in palette.items():
        setattr(Color, name, code)
    return resolved


# 3. Cross-Platform Single-Key Input
def get_single_key_choice(prompt_text: str, valid_keys: Sequence[str], default_key: str = "1") -> str:
    """Bắt phím bấm đơn lẻ lập tức mà không cần nhấn Enter.
    - Windows: msvcrt.getwch()
    - Linux/macOS: termios/tty raw mode
    - Fallback: input() thông thường
    """
    print(prompt_text, end="", flush=True)

    if sys.platform == 'win32':
        try:
            import msvcrt
            while True:
                ch = msvcrt.getwch()
                if ch in ('\r', '\n'):
                    print(f"{default_key}")
                    return default_key
                elif ch in valid_keys:
                    print(f"{ch}")
                    return ch
                elif ch == '\x03':  # Ctrl+C
                    print()
                    raise KeyboardInterrupt
        except Exception:
            pass
    elif sys.stdin.isatty():
        try:
            import termios
            import tty

            fd = sys.stdin.fileno()
            old_settings = termios.tcgetattr(fd)
            result = None
            try:
                tty.setraw(fd)
                while result is None:
                    ch = sys.stdin.read(1)
                    if ch in ('\r', '\n'):
                        result = default_key
                    elif ch in valid_keys:
                        result = ch
                    elif ch == '\x03':  # Ctrl+C
                        raise KeyboardInterrupt
            finally:
                termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
            print(result)
            return result
        except KeyboardInterrupt:
            print()
            raise
        except Exception:
            pass

    inp = input().strip(' "\' \t\r\n')
    return inp if inp in valid_keys else default_key


# 4. Box-Drawing & Alignment Engine
_WIDE_RANGES = (
    (0x1100, 0x115F),   # Hangul Jamo
    (0x2600, 0x27BF),   # Symbols & Dingbats (✔ ✖ ⚠ ⚡ 👉 ...)
    (0x2E80, 0xA4CF),   # CJK Radicals .. Yi
    (0xAC00, 0xD7A3),   # Hangul Syllables
    (0xF900, 0xFAFF),   # CJK Compatibility Ideographs
    (0xFF00, 0xFF60),   # Fullwidth Forms
    (0xFFE0, 0xFFE6),
    (0x1F300, 0x1FAFF),  # Emoji
)


def _display_width(text: str) -> int:
    """Ước lượng độ rộng hiển thị thật trên terminal (loại trừ mã ANSI, tính ký tự rộng = 2 cell)."""
    width = 0
    for ch in text:
        code = ord(ch)
        width += 2 if any(lo <= code <= hi for lo, hi in _WIDE_RANGES) else 1
    return width


def _pad_display(text: str, width: int) -> str:
    """Đệm khoảng trắng bên phải để đạt đúng độ rộng hiển thị `width`."""
    return text + " " * max(0, width - _display_width(text))


def _truncate_display(text: str, width: int, keep_tail: bool = False) -> str:
    """Cắt bớt văn bản nếu vượt độ rộng hiển thị `width`, chèn '...'.
    keep_tail=True: giữ lại phần ĐUÔI (hữu ích cho đường dẫn file / timestamp).
    """
    if _display_width(text) <= width:
        return text
    budget = max(0, width - 3)
    if keep_tail:
        out = ""
        for ch in reversed(text):
            if _display_width(ch + out) > budget:
                break
            out = ch + out
        return "..." + out
    out = ""
    for ch in text:
        if _display_width(out + ch) > budget:
            break
        out += ch
    return out + "..."


def _build_border(widths: Sequence[int], left: str, mid: str, right: str) -> str:
    segments = ["─" * (w + 2) for w in widths]
    return f"{Color.BRIGHT_CYAN}{left}" + mid.join(segments) + f"{right}{Color.RESET}"


def _build_row(cells: Sequence[Tuple[str, int]], colors: Optional[Sequence[Optional[str]]] = None) -> str:
    """Tạo một dòng bảng kẻ viền Unicode chuẩn xác."""
    colors = colors or [None] * len(cells)
    parts = []
    for (raw, width), color in zip(cells, colors):
        padded = _pad_display(raw, width)
        parts.append(f"{color}{padded}{Color.RESET}" if color else padded)
    sep = f" {Color.BRIGHT_CYAN}│{Color.RESET} "
    return f"{Color.BRIGHT_CYAN}│{Color.RESET} " + sep.join(parts) + f" {Color.BRIGHT_CYAN}│{Color.RESET}"


def print_header(title: str = "TÊN CÔNG CỤ / SCRIPT (CLI FRAMEWORK)", subtitle: str = "Mô tả ngắn gọn chức năng của công cụ") -> None:
    """In khung tiêu đề giao diện."""
    border = "═" * 71
    print(f"\n{Color.BRIGHT_CYAN}╔{border}╗{Color.RESET}")
    print(f"{Color.BRIGHT_CYAN}║{Color.RESET} {Color.BOLD}{Color.BRIGHT_WHITE}{title.center(69)}{Color.RESET} {Color.BRIGHT_CYAN}║{Color.RESET}")
    if subtitle:
        print(f"{Color.BRIGHT_CYAN}║{Color.RESET} {Color.GRAY}{subtitle.center(69)}{Color.RESET} {Color.BRIGHT_CYAN}║{Color.RESET}")
    print(f"{Color.BRIGHT_CYAN}╚{border}╝{Color.RESET}\n")


# 5. Path & Directory Resolution
def get_script_dir() -> Path:
    """Lấy đường dẫn thư mục tuyệt đối chứa script/exe hiện tại (tránh lệch sang C:\\Users\\...)."""
    if getattr(sys, 'frozen', False):
        return Path(os.path.dirname(os.path.abspath(sys.executable)))
    else:
        return Path(os.path.dirname(os.path.abspath(__file__)))


# 6. Core Business Logic (Tùy biến hàm này theo bài toán cụ thể của bạn)
def process_single_item(input_path_raw: str, target_name_raw: str, output_dir_raw: str) -> Dict:
    """Hàm xử lý cho 1 đối tượng duy nhất. Trả về dict kết quả báo cáo."""
    input_path = os.path.abspath(input_path_raw.strip(' "\' \t\r\n'))
    target_name = target_name_raw.strip(' "\' \t\r\n') if target_name_raw else "DEFAULT_ITEM"

    script_dir = get_script_dir()
    output_dir = os.path.abspath(output_dir_raw.strip(' "\' \t\r\n')) if output_dir_raw else str(script_dir / "output")
    os.makedirs(output_dir, exist_ok=True)

    # -------------------------------------------------------------
    # TODO: VIẾT MÃ XỬ LÝ CHÍNH CỦA BẠN Ở ĐÂY (Vd: đọc file, parse log, xuất báo cáo)
    # -------------------------------------------------------------
    print(f"\n{Color.BRIGHT_CYAN}⚡ [ĐANG XỬ LÝ]{Color.RESET} Mục: {Color.BOLD}{Color.WHITE}{target_name}{Color.RESET}")
    print(f"  {Color.BLUE}📂 Nguồn:{Color.RESET} {Color.GRAY}{input_path}{Color.RESET}")

    saved_file = os.path.join(output_dir, f"report_{target_name}.txt")
    with open(saved_file, "w", encoding="utf-8") as f:
        f.write(f"Báo cáo kết quả cho {target_name}\nNguồn: {input_path}\n")

    print(f"  {Color.BRIGHT_GREEN}✔ Đã lưu kết quả tại:{Color.RESET} {Color.WHITE}➜ {saved_file}{Color.RESET}")

    return {
        "name": target_name,
        "type": "FILE_LOG",
        "count": 1,
        "status": "SUCCESS",
        "error": None,
        "out_dir": output_dir,
    }


# 7. Batch & CSV Processing Logic
_SUMMARY_COLUMNS = [
    ("STT", 3),
    ("Target Name", 18),
    ("Phân Loại", 12),
    ("Số lượng", 8),
    ("Trạng Thái", 10),
    ("Thư mục lưu kết quả", 36),
]


def print_batch_summary_table(results: List[Dict]) -> None:
    """In bảng tổng hợp kết quả chạy Batch với căn chỉnh tự động và màu sắc thích ứng."""
    widths = [w for _, w in _SUMMARY_COLUMNS]

    # Tính màu trong hàm để luôn đồng bộ với theme hiện tại
    status_display = {
        "SUCCESS": (Color.BRIGHT_GREEN, "SUCCESS"),
        "WARNING": (Color.BRIGHT_YELLOW, "NOT FOUND"),
    }
    status_fail_default = (Color.BRIGHT_RED, "FAIL")

    print()
    print(_build_border(widths, "┌", "┬", "┐"))
    print(_build_row([(title, w) for title, w in _SUMMARY_COLUMNS], colors=[Color.BOLD] * len(_SUMMARY_COLUMNS)))
    print(_build_border(widths, "├", "┼", "┤"))

    success_count = 0
    fail_count = 0

    for idx, item in enumerate(results, 1):
        name = _truncate_display(str(item.get("name", "UNKNOWN")), _SUMMARY_COLUMNS[1][1])
        item_type = _truncate_display(str(item.get("type", "-")), _SUMMARY_COLUMNS[2][1])
        count = str(item.get("count", 1))
        status = item.get("status", "FAIL")
        out_dir = _truncate_display(str(item.get("out_dir", "-")), _SUMMARY_COLUMNS[5][1], keep_tail=True)

        status_color, status_label = status_display.get(status, status_fail_default)
        if status == "SUCCESS":
            success_count += 1
        elif status not in status_display:
            fail_count += 1

        print(
            _build_row(
                [
                    (str(idx), _SUMMARY_COLUMNS[0][1]),
                    (name, _SUMMARY_COLUMNS[1][1]),
                    (item_type, _SUMMARY_COLUMNS[2][1]),
                    (count, _SUMMARY_COLUMNS[3][1]),
                    (status_label, _SUMMARY_COLUMNS[4][1]),
                    (out_dir, _SUMMARY_COLUMNS[5][1]),
                ],
                colors=[None, f"{Color.BOLD}{Color.WHITE}", Color.CYAN, Color.YELLOW, status_color, Color.GRAY],
            )
        )

    print(_build_border(widths, "└", "┴", "┘"))
    print(
        f"\n{Color.BOLD}📊 Thống kê:{Color.RESET} Tổng số: {Color.BOLD}{len(results)}{Color.RESET} │ "
        f"{Color.BRIGHT_GREEN}Thành công: {success_count}{Color.RESET} │ "
        f"{Color.BRIGHT_RED}Thất bại: {fail_count}{Color.RESET}\n"
    )


def generate_sample_csv(output_filename: str = "mau_danh_sach.csv") -> Path:
    """Tạo file CSV mẫu tại cùng thư mục chứa script."""
    if not os.path.isabs(output_filename):
        abs_csv = get_script_dir() / output_filename
    else:
        abs_csv = Path(output_filename)

    sample_content = [
        ["# Danh sach mau xu ly hang loat", "", ""],
        ["# Cau truc cot: InputPath, TargetName, OutputDir (tuy chon)", "", ""],
        ["InputPath", "TargetName", "OutputDir"],
        [r"D:\PATH\TO\SAMPLE_FILE_1.log", "ITEM_01", r"D:\PATH\TO\OUTPUT"],
        [r"D:\PATH\TO\SAMPLE_FILE_2.log", "ITEM_02", ""],
    ]
    with open(abs_csv, "w", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerows(sample_content)

    print(
        f"\n{Color.BRIGHT_GREEN}✔ Đã tạo thành công file CSV mẫu tại:{Color.RESET}\n"
        f"  {Color.BOLD}{Color.WHITE}➜ {abs_csv}{Color.RESET}\n"
    )
    return abs_csv


def parse_csv_file(csv_path: str) -> List[Tuple[str, str, str]]:
    """Đọc danh sách từ file CSV hoặc TXT, tự động bỏ qua ghi chú và dòng tiêu đề."""
    abs_path = os.path.abspath(csv_path.strip(' "\' \t\r\n'))
    if not os.path.exists(abs_path):
        raise FileNotFoundError(f"File CSV không tồn tại: {abs_path}")

    batch_items = []
    with open(abs_path, 'r', encoding='utf-8-sig', errors='ignore') as f:
        first_line = f.readline()
        f.seek(0)
        delimiter = ';' if ';' in first_line and ',' not in first_line else ','
        reader = csv.reader(f, delimiter=delimiter)

        for row in reader:
            if not row:
                continue
            first_cell = row[0].strip()
            if not first_cell or first_cell.startswith("#"):
                continue

            # Bỏ qua dòng tiêu đề nếu có
            if first_cell.lower() in ("inputpath", "input_path", "path", "file", "target"):
                continue

            inp_path = first_cell
            target_name = row[1].strip() if len(row) > 1 else ""
            out_dir = row[2].strip() if len(row) > 2 else ""

            if inp_path:
                batch_items.append((inp_path, target_name, out_dir))

    return batch_items


def run_batch_execution(batch_items: List[Tuple[str, str, str]]) -> None:
    """Chạy vòng lặp cách ly lỗi (Error Isolation) cho từng item trong danh sách."""
    results = []
    total = len(batch_items)
    print(f"\n{Color.BRIGHT_YELLOW}🚀 Bắt đầu xử lý hàng loạt ({total} mục trong danh sách)...{Color.RESET}")
    print(f"{Color.GRAY}─────────────────────────────────────────────────────────────────────────────{Color.RESET}")

    for idx, (inp_path, target_name, out_dir) in enumerate(batch_items, 1):
        print(f"\n{Color.BRIGHT_CYAN}[{idx}/{total}]{Color.RESET} Đang xử lý: {Color.GRAY}{inp_path}{Color.RESET}")
        try:
            res = process_single_item(inp_path, target_name, out_dir)
            results.append(res)
        except Exception as e:
            print(f"  {Color.BRIGHT_RED}✖ Lỗi khi xử lý {target_name}: {e}{Color.RESET}")
            results.append({
                "name": target_name if target_name else "N/A",
                "type": "ERROR",
                "count": 0,
                "status": "FAIL",
                "error": str(e),
                "out_dir": "-",
            })

    print_batch_summary_table(results)


# 8. Main Entry Point & Command Line Parsing
def main() -> int:
    parser = argparse.ArgumentParser(description="Mô tả công cụ của bạn.")
    parser.add_argument("--input", required=False, default=None, help="Đường dẫn file/folder đầu vào.")
    parser.add_argument("--name", required=False, default=None, help="Tên hoặc nhãn định danh.")
    parser.add_argument("--output", required=False, default=None, help="Thư mục xuất kết quả.")
    parser.add_argument("--batch-dir", required=False, default=None, help="Thư mục gốc quét hàng loạt.")
    parser.add_argument("--csv-file", required=False, default=None, help="File CSV danh sách đầu vào.")
    parser.add_argument("--generate-csv-template", action="store_true", help="Tạo file CSV mẫu.")
    parser.add_argument(
        "--theme",
        choices=["auto", "dark", "light"],
        default="auto",
        help="Bảng màu: 'auto' tự nhận diện nền tối/sáng, 'dark' hoặc 'light' để ép buộc.",
    )
    parser.add_argument("--no-color", action="store_true", help="Tắt toàn bộ màu ANSI.")

    args = parser.parse_args()

    # Kích hoạt theme màu ngay đầu chương trình
    theme_forced = None if args.theme == "auto" else args.theme
    configure_theme(theme=theme_forced, no_color=args.no_color)

    if args.generate_csv_template:
        generate_sample_csv("mau_danh_sach.csv")
        return 0

    if args.csv_file:
        batch_items = parse_csv_file(args.csv_file)
        if not batch_items:
            print(f"{Color.YELLOW}Không có mục nào hợp lệ trong CSV.{Color.RESET}")
            return 0
        run_batch_execution(batch_items)
        return 0

    if args.input:
        res = process_single_item(args.input, args.name, args.output)
        print_batch_summary_table([res])
        return 0 if res.get("status") == "SUCCESS" else 1

    # Giao diện Chọn Chế độ Tương tác (Interactive Menu)
    print_header()
    print(f"{Color.BRIGHT_YELLOW}Vui lòng chọn chế độ làm việc:{Color.RESET}\n")
    print(f"   {Color.CYAN}[1]{Color.RESET} Trực tiếp 1 đối tượng (Single Mode)")
    print(f"   {Color.CYAN}[2]{Color.RESET} Quét hàng loạt từ thư mục gốc (Batch Folder Scan)")
    print(f"   {Color.CYAN}[3]{Color.RESET} Đọc danh sách từ file CSV / TXT (Batch CSV Import)")
    print(f"   {Color.CYAN}[4]{Color.RESET} Tạo file CSV mẫu (mau_danh_sach.csv)")
    print(f"   {Color.CYAN}[5]{Color.RESET} Thoát chương trình\n")

    prompt_str = f"   {Color.CYAN}👉 Chọn nhanh số (1-5) hoặc nhấn Enter để chọn [1]: {Color.RESET}"
    mode_choice = get_single_key_choice(prompt_str, ["1", "2", "3", "4", "5"], default_key="1")

    if mode_choice == "5":
        print(f"\n{Color.GRAY}Đã thoát chương trình.{Color.RESET}\n")
        return 0
    elif mode_choice == "4":
        generate_sample_csv("mau_danh_sach.csv")
        return 0
    elif mode_choice == "3":
        print(f"\n{Color.BRIGHT_YELLOW}📌 [Batch CSV Mode] Đọc danh sách từ file CSV/TXT:{Color.RESET}")
        csv_path = input(f"   {Color.CYAN}👉 Nhập đường dẫn file CSV/TXT (Mặc định: mau_danh_sach.csv): {Color.RESET}").strip(' "\' \t\r\n')
        if not csv_path:
            script_dir = get_script_dir()
            csv_path = str(script_dir / "mau_danh_sach.csv")
            if not os.path.exists(csv_path):
                generate_sample_csv(csv_path)

        batch_items = parse_csv_file(csv_path)
        run_batch_execution(batch_items)
        return 0
    elif mode_choice == "2":
        print(f"\n{Color.BRIGHT_YELLOW}📌 [Batch Folder Scan] Quét hàng loạt thư mục gốc:{Color.RESET}")
        parent_dir = input(f"   {Color.CYAN}👉 Nhập đường dẫn thư mục gốc: {Color.RESET}").strip(' "\' \t\r\n')
        while not parent_dir or not os.path.exists(parent_dir):
            print(f"   {Color.RED}✖ Thư mục không tồn tại. Vui lòng nhập lại!{Color.RESET}")
            parent_dir = input(f"   {Color.CYAN}👉 Nhập đường dẫn thư mục gốc: {Color.RESET}").strip(' "\' \t\r\n')

        # Đọc danh sách các subfolder trong parent_dir
        batch_items = [(os.path.join(parent_dir, d), d, "") for d in os.listdir(parent_dir) if os.path.isdir(os.path.join(parent_dir, d))]
        run_batch_execution(batch_items)
        return 0
    else:
        # Chế độ 1: Single Mode
        print(f"\n{Color.BRIGHT_YELLOW}📌 [Single Mode] Xử lý đơn lẻ 1 mục:{Color.RESET}\n")

        while True:
            prompt_str = f"   {Color.BRIGHT_YELLOW}Nhập đường dẫn đầu vào (Input Path):{Color.RESET}\n   {Color.CYAN}👉 {Color.RESET}"
            inp_raw = input(prompt_str).strip(' "\' \t\r\n')
            if inp_raw and os.path.exists(inp_raw):
                break
            print(f"   {Color.RED}✖ Đường dẫn không tồn tại. Vui lòng kiểm tra lại!{Color.RESET}\n")

        prompt_str = f"\n   {Color.BRIGHT_YELLOW}Nhập thư mục xuất kết quả (Nhấn Enter để chọn mặc định ./output):{Color.RESET}\n   {Color.CYAN}👉 {Color.RESET}"
        out_raw = input(prompt_str).strip(' "\' \t\r\n')

        res = process_single_item(inp_raw, os.path.basename(inp_raw), out_raw)
        print_batch_summary_table([res])
        return 0 if res.get("status") == "SUCCESS" else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print(f"\n\n{Color.YELLOW}[!] Thao tác đã bị hủy bởi người dùng (Ctrl+C).{Color.RESET}\n")
        sys.exit(0)
