"""Audio Visualizer for Windows — a desktop-wide, audio-reactive overlay.

Hosts the same QML the Plasma widget and the Hyprland panel render (see
windows/qml/Overlay.qml) in a borderless window pinned below every other
window, like a live wallpaper, plus a tray icon. Audio comes from
windows/audio_capture.py, which replaces the Linux cava feeder.

Run it:
  pip install -r windows/requirements.txt
  python windows/app.py

  python windows/app.py --selftest   load Overlay.qml headless, exit 1 on any
                                      QML warning/error — what CI runs; it
                                      opens no audio device.
"""

import os
import sys
from pathlib import Path

# Frozen by PyInstaller the bundled tree is rooted at _MEIPASS, which is where
# the spec lays out package/, hyprland/ and windows/qml/.
ROOT = Path(getattr(sys, "_MEIPASS", None) or Path(__file__).resolve().parent.parent)

# Must happen before PySide6 is imported: the QPA platform plugin is picked
# up at import time, not at QApplication() construction, so setting this any
# later (e.g. inside main()) still probes "xcb"/"windows" and aborts with a
# bare SIGABRT and no message on a machine with no display (found via a
# `nix develop .#windows` CI-style headless run — see docs/windows.md).
if "--selftest" in sys.argv and not os.environ.get("QT_QPA_PLATFORM"):
    os.environ["QT_QPA_PLATFORM"] = "offscreen"

try:
    from PySide6.QtCore import Qt, QTimer, QUrl
    from PySide6.QtGui import QColor, QIcon
    from PySide6.QtQuick import QQuickView
    from PySide6.QtWidgets import QApplication, QMenu, QSystemTrayIcon
except ImportError:  # pragma: no cover - dev-time hint only
    print(
        "Missing PySide6. Run: pip install -r windows/requirements.txt", file=sys.stderr
    )
    raise


def settings_json() -> str:
    """The user's saved settings, if any — parsed QML-side by Configuration.js."""
    base = (
        os.environ.get("APPDATA")
        or os.environ.get("XDG_CONFIG_HOME")
        or str(Path.home() / ".config")
    )
    path = Path(base) / "audio-visualizer" / "settings.json"
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def _pin_to_bottom(view: QQuickView) -> None:
    """Re-park the overlay below every other top-level window.

    Qt's WindowStaysOnBottomHint sets the style once; Windows restacks
    HWND_BOTTOM windows above newly created ones, so it has to be reasserted.
    """
    if sys.platform != "win32":
        return
    import ctypes

    HWND_BOTTOM, SWP_NOSIZE, SWP_NOMOVE, SWP_NOACTIVATE = 1, 0x0001, 0x0002, 0x0010
    ctypes.windll.user32.SetWindowPos(
        int(view.winId()),
        HWND_BOTTOM,
        0,
        0,
        0,
        0,
        SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE,
    )


def main(argv: list[str]) -> int:
    selftest = "--selftest" in argv

    app = QApplication(argv)
    app.setQuitOnLastWindowClosed(False)

    warnings = []
    view = QQuickView()
    view.setResizeMode(QQuickView.ResizeMode.SizeRootObjectToView)
    engine = view.engine()
    engine.warnings.connect(lambda errors: warnings.extend(errors))
    # Imported lazily: it pulls in numpy and soundcard and opens a device, and
    # --selftest runs on CI machines that have neither.
    if selftest:
        audio_capture = None
    else:
        import audio_capture

    view.setInitialProperties(
        {
            "runtimeDirectory": "" if selftest else str(audio_capture.runtime_dir()),
            "defaultsXml": (
                ROOT / "package" / "contents" / "config" / "main.xml"
            ).read_text(encoding="utf-8"),
            "settingsJson": settings_json(),
        }
    )
    view.setSource(QUrl.fromLocalFile(str(ROOT / "windows" / "qml" / "Overlay.qml")))

    if selftest:
        ok = (
            view.status() == QQuickView.Status.Ready
            and not warnings
            and not view.errors()
        )
        for error in view.errors():
            print(error.toString(), file=sys.stderr)
        for warning in warnings:
            print(warning.toString(), file=sys.stderr)
        return 0 if ok else 1

    if view.errors():
        for error in view.errors():
            print(error.toString(), file=sys.stderr)
        return 1

    # The QML side already merged main.xml's defaults with the user's
    # settings; read the result back rather than parsing either again here.
    audio_capture.start(view.rootObject().property("configuration"))

    view.setFlags(
        Qt.WindowType.FramelessWindowHint
        | Qt.WindowType.Tool
        | Qt.WindowType.WindowStaysOnBottomHint
        | Qt.WindowType.WindowDoesNotAcceptFocus
    )
    view.setColor(QColor(Qt.GlobalColor.transparent))
    view.setGeometry(app.primaryScreen().geometry())
    view.show()
    _pin_to_bottom(view)
    restack = QTimer(view)
    restack.timeout.connect(lambda: _pin_to_bottom(view))
    restack.start(2000)

    tray = QSystemTrayIcon()
    tray.setIcon(QIcon(str(ROOT / "package" / "icon.png")))
    tray.setToolTip("Audio Visualizer")

    menu = QMenu()
    toggle_action = menu.addAction("Show/Hide")
    toggle_action.triggered.connect(lambda: view.setVisible(not view.isVisible()))
    settings_action = menu.addAction("Settings…")
    settings_action.setEnabled(False)  # TODO: port hyprland/SettingsPage.qml
    menu.addSeparator()
    quit_action = menu.addAction("Quit")
    quit_action.triggered.connect(app.quit)
    tray.setContextMenu(menu)
    tray.show()

    try:
        return app.exec()
    finally:
        audio_capture.stop()


if __name__ == "__main__":
    sys.exit(main(sys.argv))
