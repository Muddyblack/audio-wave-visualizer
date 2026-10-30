"""Audio Visualizer for Windows — an audio-reactive desktop widget.

Hosts the same QML the Plasma widget and the Hyprland panel render (see
windows/qml/Overlay.qml) in a borderless window pinned below every other
window, like a live wallpaper, plus a tray icon and the shared settings
studio. Audio comes from windows/audio_capture.py, which replaces the Linux
cava feeder; now playing from windows/media_session.py, which replaces MPRIS.

Run it:
  pip install -r windows/requirements.txt
  python windows/app.py

  python windows/app.py --selftest   load Overlay.qml headless, exit 1 on any
                                      QML warning/error — what CI runs; it
                                      opens no audio device.
  python windows/app.py --selftest-audio   synthetic capture and backend imports
"""

import os
import sys
import time
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
    from PySide6.QtCore import (
        Property,
        QEvent,
        QObject,
        QPoint,
        QRect,
        QSettings,
        QSize,
        Qt,
        QTimer,
        QUrl,
        Signal,
        Slot,
    )
    from PySide6.QtGui import QColor, QCursor, QIcon
    from PySide6.QtQml import QJSValue
    from PySide6.QtQuick import QQuickView, QQuickWindow
    from PySide6.QtWidgets import QApplication, QMenu, QSystemTrayIcon
except ImportError:  # pragma: no cover - dev-time hint only
    print(
        "Missing PySide6. Run: pip install -r windows/requirements.txt", file=sys.stderr
    )
    raise


def settings_path() -> Path:
    base = (
        os.environ.get("APPDATA")
        or os.environ.get("XDG_CONFIG_HOME")
        or str(Path.home() / ".config")
    )
    return Path(base) / "audio-visualizer" / "settings.json"


def settings_json() -> str:
    """The user's saved settings, if any — parsed QML-side by Configuration.js."""
    path = settings_path()
    return path.read_text(encoding="utf-8") if path.is_file() else ""


class SettingsStore(QObject):
    """Saves what the settings window applies; Overlay.qml calls saveSettings."""

    changed = Signal()

    def __init__(self):
        super().__init__()
        self._error = ""

    settingsError = Property(str, lambda self: self._error, notify=changed)

    @Slot(str, result=str)
    def readCatalog(self, language: str) -> str:
        try:
            return (ROOT / "translate" / f"{language}.po").read_text(encoding="utf-8")
        except OSError:
            return ""

    @Slot(str)
    def saveSettings(self, text: str) -> None:
        path = settings_path()
        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            tmp = path.with_suffix(".json.tmp")
            tmp.write_text(text, encoding="utf-8")
            os.replace(tmp, path)
            self._error = ""
        except OSError as error:
            self._error = f"Could not save settings to {path}: {error.strerror}"
        self.changed.emit()


def _cache_pipelines(window: QQuickWindow, path: Path) -> None:
    """Keep the window's compiled shaders on disk between runs.

    The settings studio draws dozens of live previews; compiling their shader
    pipelines took ~45 s on first open (CPU-only VM) and then cost 2.6 cores,
    every time. Loaded from this file it opens in under a second. One file per
    window, since each window saves only its own pipelines and would overwrite
    another's. Must be set before the window is first shown.
    """
    configuration = window.graphicsConfiguration()
    configuration.setPipelineCacheLoadFile(str(path))
    configuration.setPipelineCacheSaveFile(str(path))
    window.setGraphicsConfiguration(configuration)


def _qml_value(root, name: str):
    """A QML `var` property as Python data (it arrives as a QJSValue)."""
    value = root.property(name)
    return value.toVariant() if isinstance(value, QJSValue) else value


def qml_directory(path: Path) -> str:
    """A directory as the shared QML expects it: "file://" + dir must be a URL.

    VisualizerCore builds its readers' locations as "file://" + path, which on
    Windows turns C:\\Users\\... into file://C:\\Users\\... — host "c", so Qt
    reads //c/frame.ini and the bars never move. A leading slash and forward
    slashes make it file:///C:/Users/..., without touching the QML the Linux
    hosts share.
    """
    if sys.platform != "win32":
        return str(path)
    return "/" + path.resolve().as_posix()


def _pin_to_bottom(view: QQuickView) -> None:
    """Re-park the overlay below every other top-level window.

    Qt's WindowStaysOnBottomHint sets the style once; Windows restacks
    HWND_BOTTOM windows above newly created ones, so it has to be reasserted.
    """
    if sys.platform != "win32":
        return
    import ctypes
    from ctypes import wintypes

    # HWND is pointer-sized; ctypes otherwise converts it to a 32-bit int.
    set_window_pos = ctypes.windll.user32.SetWindowPos
    set_window_pos.argtypes = [
        wintypes.HWND,
        wintypes.HWND,
        ctypes.c_int,
        ctypes.c_int,
        ctypes.c_int,
        ctypes.c_int,
        wintypes.UINT,
    ]
    set_window_pos.restype = wintypes.BOOL

    HWND_BOTTOM, SWP_NOSIZE, SWP_NOMOVE, SWP_NOACTIVATE = 1, 0x0001, 0x0002, 0x0010
    set_window_pos(
        int(view.winId()),
        HWND_BOTTOM,
        0,
        0,
        0,
        0,
        SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE,
    )


# What audio_capture reads from the configuration (see _Feed.__init__).
AUDIO_KEYS = (
    "numBars",
    "framerate",
    "sensitivity",
    "noiseReduction",
    "lowCutoff",
    "highCutoff",
)

PINNED_FLAGS = (
    Qt.WindowType.FramelessWindowHint
    | Qt.WindowType.Tool
    | Qt.WindowType.WindowDoesNotAcceptFocus
)
# A normal window with a title bar, so Windows itself provides dragging, edge
# resizing and snapping; on top, so it is not lost behind what it overlays.
ADJUST_FLAGS = Qt.WindowType.Window | Qt.WindowType.WindowStaysOnTopHint


class Placement:
    """Where the overlay sits: pinned to the desktop, or being moved/resized.

    By default the window goes where the Hyprland panel would: Overlay.qml's
    widgetRect, from the settings' Placement section (size, anchor, vertical
    position, monitor), above or behind windows per its Layer. Move / resize
    overrides that with a hand-placed geometry, remembered in
    %APPDATA%\\audio-visualizer\\window.ini until Reset position.
    """

    def __init__(self, view: QQuickView, app: QApplication):
        self.view = view
        self.app = app
        self.root = view.rootObject()
        self.adjusting = False
        self.changed = lambda: None
        self.store = QSettings(
            QSettings.Format.IniFormat,
            QSettings.Scope.UserScope,
            "audio-visualizer",
            "window",
        )

    def _saved_geometry(self) -> QRect:
        saved = self.store.value("geometry")
        # A monitor that has since been unplugged would leave it offscreen.
        if (
            isinstance(saved, QRect)
            and saved.isValid()
            and any(s.geometry().intersects(saved) for s in self.app.screens())
        ):
            return saved
        rect = _qml_value(self.root, "widgetRect") or {}
        return QRect(
            int(rect.get("x", 0)),
            int(rect.get("y", 0)),
            int(rect.get("width", 360)),
            int(rect.get("height", 104)),
        )

    def _behind(self) -> bool:
        configuration = _qml_value(self.root, "configuration") or {}
        return bool(configuration.get("desktopLayer", True))

    def _pinned_flags(self):
        return PINNED_FLAGS | (
            Qt.WindowType.WindowStaysOnBottomHint
            if self._behind()
            else Qt.WindowType.WindowStaysOnTopHint
        )

    def refresh(self) -> None:
        """Follow a settings change (placement or layer) while pinned."""
        if self.adjusting or not self.view.isVisible():
            return
        if self.view.flags() != self._pinned_flags():
            self.pin()
        else:
            self.view.setGeometry(self._saved_geometry())

    def _finish_adjusting(self) -> None:
        if self.adjusting:
            self.remember()
        self.adjusting = False

    def _reachable(self, geometry: QRect) -> QRect:
        """Room for the title bar and resize edges Move/resize adds.

        Those sit outside the window's own rect, so on a screen-filling
        overlay they would land offscreen: no way to drag, resize or even see
        how to get out, just a topmost tinted window over everything.
        """
        screen = self.view.screen() or self.app.primaryScreen()
        area = screen.availableGeometry().adjusted(8, 40, -8, -8)
        if geometry.width() >= area.width() or geometry.height() >= area.height():
            size = QSize(area.width() * 3 // 5, area.height() * 2 // 5)
            geometry = QRect(QPoint(0, 0), size)
            geometry.moveCenter(area.center())
            return geometry
        geometry = QRect(geometry)
        geometry.moveLeft(
            max(area.left(), min(geometry.left(), area.right() - geometry.width()))
        )
        geometry.moveTop(
            max(area.top(), min(geometry.top(), area.bottom() - geometry.height()))
        )
        return geometry

    def toggle_visible(self) -> None:
        if self.view.isVisible():
            self._finish_adjusting()
            self.view.hide()
            self.changed()
        else:
            # Through pin(), not a bare show(): showing raises the window to
            # the top of the Z-order, over everything it is meant to sit under.
            self.pin()

    def pin(self) -> None:
        self._finish_adjusting()
        geometry = self._saved_geometry()
        # Flags only take effect on a hidden window.
        self.view.hide()
        self.view.setFlags(self._pinned_flags())
        self.view.setTitle("")
        self.view.setColor(QColor(Qt.GlobalColor.transparent))
        self.view.setGeometry(geometry)
        self.view.show()
        self.restack()
        self.changed()

    def adjust(self) -> None:
        self.adjusting = True
        geometry = self._reachable(self.view.geometry())
        self.view.hide()
        self.view.setFlags(ADJUST_FLAGS)
        self.view.setTitle(
            "Audio Visualizer — drag, resize, then close (×) or Enter to lock"
        )
        # Tinted, so the window's extent is visible even with silent bars.
        self.view.setColor(QColor(20, 20, 30, 140))
        self.view.setGeometry(geometry)
        self.view.show()
        self.view.requestActivate()
        self.changed()

    def remember(self) -> None:
        """Keep the current geometry as the hand-placed one."""
        self.store.setValue("geometry", self.view.geometry())

    def reset(self) -> None:
        """Back to the settings' placement, dropping the hand-placed one."""
        self.adjusting = False
        self.store.remove("geometry")
        self.pin()

    def restack(self) -> None:
        if not self.adjusting and self._behind():
            _pin_to_bottom(self.view)


class OverlayEvents(QObject):
    """Right-click menu, middle-button drag, and ways out of Move/resize."""

    def __init__(self, menu: QMenu, placement: Placement):
        super().__init__()
        self.menu = menu
        self.placement = placement
        self._grab: QPoint | None = None

    def eventFilter(self, watched, event) -> bool:
        kind = event.type()
        if (
            kind == QEvent.Type.MouseButtonPress
            and event.button() == Qt.MouseButton.RightButton
        ):
            self.menu.popup(QCursor.pos())
            return True
        # Hold the middle button to drag the overlay anywhere — the quick way,
        # without going through Move / resize. Left clicks stay with the card
        # (seek, play/pause).
        if (
            kind == QEvent.Type.MouseButtonPress
            and event.button() == Qt.MouseButton.MiddleButton
        ):
            self._grab = event.globalPosition().toPoint() - watched.position()
            return True
        if kind == QEvent.Type.MouseMove and self._grab is not None:
            watched.setPosition(event.globalPosition().toPoint() - self._grab)
            return True
        if (
            kind == QEvent.Type.MouseButtonRelease
            and event.button() == Qt.MouseButton.MiddleButton
            and self._grab is not None
        ):
            self._grab = None
            if not self.placement.adjusting:
                self.placement.remember()
            return True
        if not self.placement.adjusting:
            return False
        # The title bar's × would otherwise hide the overlay with no obvious
        # way back; while adjusting it means "done", as Enter and Esc do.
        if kind == QEvent.Type.Close or (
            kind == QEvent.Type.KeyPress
            and event.key() in (Qt.Key.Key_Return, Qt.Key.Key_Enter, Qt.Key.Key_Escape)
        ):
            event.ignore()
            QTimer.singleShot(0, self.placement.pin)
            return True
        return False


def main(argv: list[str]) -> int:
    if "--selftest-audio" in argv:
        from selftest_audio import main as audio_selftest

        return audio_selftest()

    selftest = "--selftest" in argv

    app = QApplication(argv)
    app.setQuitOnLastWindowClosed(False)
    # Every window's title bar and taskbar entry — the settings window above
    # all — instead of Qt's generic icon.
    app.setWindowIcon(QIcon(str(ROOT / "package" / "icon.png")))

    warnings = []
    view = QQuickView()
    view.setResizeMode(QQuickView.ResizeMode.SizeRootObjectToView)
    engine = view.engine()
    engine.warnings.connect(lambda errors: warnings.extend(errors))
    # Imported lazily: it pulls in numpy and soundcard and opens a device, and
    # --selftest runs on CI machines that have neither.
    # The media sessions likewise: --selftest must not depend on what happens
    # to be playing on the machine running it.
    if selftest:
        audio_capture = None
        media = None
    else:
        import audio_capture
        from media_session import MediaSessions

        media = MediaSessions(audio_capture.runtime_dir())
    store = SettingsStore()

    view.setInitialProperties(
        {
            "runtimeDirectory": (
                "" if selftest else qml_directory(audio_capture.runtime_dir())
            ),
            "defaultsXml": (
                ROOT / "package" / "contents" / "config" / "main.xml"
            ).read_text(encoding="utf-8"),
            "settingsJson": settings_json(),
            "media": media,
            "host": store,
        }
    )
    view.setSource(QUrl.fromLocalFile(str(ROOT / "windows" / "qml" / "Overlay.qml")))

    if selftest:
        # Open the settings window too: it loads the whole shared Studio,
        # which is far more QML than the overlay itself.
        if view.status() == QQuickView.Status.Ready:
            view.rootObject().setProperty("settingsOpen", True)
            deadline = time.monotonic() + 3
            while time.monotonic() < deadline:
                app.processEvents()
                time.sleep(0.01)
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
    # `configuration` is a QML `var` holding a plain JS object, which comes
    # back as a QJSValue, not a dict — toVariant() is what makes it one.
    root = view.rootObject()
    cache_dir = audio_capture.runtime_dir()
    _cache_pipelines(view, cache_dir / "overlay.pipelines")
    _cache_pipelines(
        root.findChild(QQuickWindow, "settingsWindow"),
        cache_dir / "settings.pipelines",
    )
    configuration = _qml_value(root, "configuration") or {}
    audio_capture.start(configuration)

    placement = Placement(view, app)
    placement.pin()

    # Settings applied in the settings window: capture reads its options only
    # when it starts, so restart it when one of them changed.
    def configuration_changed() -> None:
        nonlocal configuration
        updated = _qml_value(root, "configuration") or {}
        if any(updated.get(key) != configuration.get(key) for key in AUDIO_KEYS):
            audio_capture.start(updated)
        configuration = updated
        placement.refresh()

    root.configurationChanged.connect(configuration_changed)
    root.widgetRectChanged.connect(placement.refresh)
    restack = QTimer(view)
    restack.timeout.connect(placement.restack)
    restack.start(2000)

    tray = QSystemTrayIcon()
    tray.setIcon(QIcon(str(ROOT / "package" / "icon.png")))
    tray.setToolTip("Audio Visualizer")

    menu = QMenu()
    toggle_action = menu.addAction("Hide")
    toggle_action.triggered.connect(placement.toggle_visible)
    adjust_action = menu.addAction("Move / resize…")
    adjust_action.triggered.connect(
        lambda: placement.pin() if placement.adjusting else placement.adjust()
    )

    def update_menu() -> None:
        toggle_action.setText("Hide" if view.isVisible() else "Show")
        adjust_action.setText(
            "Lock in place" if placement.adjusting else "Move / resize…"
        )

    placement.changed = update_menu
    menu.aboutToShow.connect(update_menu)
    # Left-clicking the tray icon toggles, so a hidden overlay is one click
    # away rather than buried in a menu.
    tray.activated.connect(
        lambda reason: (
            placement.toggle_visible()
            if reason == QSystemTrayIcon.ActivationReason.Trigger
            else None
        )
    )
    reset_action = menu.addAction("Reset position")
    reset_action.triggered.connect(placement.reset)
    settings_action = menu.addAction("Settings…")
    settings_action.triggered.connect(lambda: root.setProperty("settingsOpen", True))
    menu.addSeparator()
    quit_action = menu.addAction("Quit")
    quit_action.triggered.connect(app.quit)
    tray.setContextMenu(menu)
    tray.show()
    # The same menu on the overlay itself, like a widget's right-click menu on
    # Linux — the tray icon is easy to lose in the overflow area.
    overlay_events = OverlayEvents(menu, placement)
    view.installEventFilter(overlay_events)

    try:
        return app.exec()
    finally:
        media.stop()
        audio_capture.stop()


if __name__ == "__main__":
    sys.exit(main(sys.argv))
