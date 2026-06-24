"""
每隔 1 秒向所有标题完整等于「魔兽世界」的窗口后台发送按键 CTRL-SHIFT-NUMPAD8。
使用 PostMessage，不会把窗口切到前台。

运行: python wow_send_e.py
停止: Ctrl+C
"""

import ctypes
import ctypes.wintypes
import time

user32 = ctypes.windll.user32

WM_KEYDOWN = 0x0100
WM_KEYUP = 0x0101
VK_CONTROL = 0x11
VK_SHIFT = 0x10
VK_NUMPAD8 = 0x68
KEY_MODIFIERS = (VK_CONTROL, VK_SHIFT)
KEY_MAIN = VK_NUMPAD8
KEY_LABEL = "CTRL-SHIFT-NUMPAD8"

# 窗口标题须与此字符串完全一致
WINDOW_TITLE = "魔兽世界"

# 发送间隔（秒）
INTERVAL_SEC = 1.0


def get_window_title(hwnd: int) -> str:
    length = user32.GetWindowTextLengthW(hwnd) + 1
    buf = ctypes.create_unicode_buffer(length)
    user32.GetWindowTextW(hwnd, buf, length)
    return buf.value


def find_target_windows(exact_title: str) -> list[tuple[int, str]]:
    """枚举可见顶层窗口，标题完整匹配时返回 (hwnd, title) 列表。"""
    matches: list[tuple[int, str]] = []

    @ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.wintypes.HWND, ctypes.wintypes.LPARAM)
    def enum_callback(hwnd, _lparam):
        if not user32.IsWindowVisible(hwnd):
            return True
        title = get_window_title(hwnd)
        if title == exact_title:
            matches.append((hwnd, title))
        return True

    user32.EnumWindows(enum_callback, 0)
    return matches


def make_lparam(vk: int, key_up: bool) -> int:
    scan = user32.MapVirtualKeyW(vk, 0)
    lparam = 1 | (scan << 16)
    if key_up:
        lparam |= (1 << 30) | (1 << 31)  # 先前状态、转换状态
    return lparam


def send_key_background(hwnd: int) -> None:
    """向指定 hwnd 后台投递 CTRL-SHIFT-NUMPAD8 组合键。"""
    for vk in KEY_MODIFIERS:
        user32.PostMessageW(hwnd, WM_KEYDOWN, vk, make_lparam(vk, key_up=False))
    user32.PostMessageW(hwnd, WM_KEYDOWN, KEY_MAIN, make_lparam(KEY_MAIN, key_up=False))
    user32.PostMessageW(hwnd, WM_KEYUP, KEY_MAIN, make_lparam(KEY_MAIN, key_up=True))
    for vk in reversed(KEY_MODIFIERS):
        user32.PostMessageW(hwnd, WM_KEYUP, vk, make_lparam(vk, key_up=True))


def main() -> None:
    print(f"目标窗口标题（完整匹配）: 「{WINDOW_TITLE}」")
    print(f"发送按键: {KEY_LABEL}")
    print(f"间隔: {INTERVAL_SEC} 秒，按 Ctrl+C 停止\n")

    try:
        while True:
            windows = find_target_windows(WINDOW_TITLE)
            if windows:
                for hwnd, title in windows:
                    send_key_background(hwnd)
                names = ", ".join(t for _, t in windows)
                print(f"[{time.strftime('%H:%M:%S')}] 已向 {len(windows)} 个窗口发送 {KEY_LABEL}: {names}")
            else:
                print(f"[{time.strftime('%H:%M:%S')}] 未找到匹配窗口，继续等待…")
            time.sleep(INTERVAL_SEC)
    except KeyboardInterrupt:
        print("\n已停止。")


if __name__ == "__main__":
    main()
