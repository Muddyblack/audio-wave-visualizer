# PyInstaller spec for the Windows overlay. From the repository root:
#
#   pip install -r windows/build-requirements.txt
#   pyinstaller --noconfirm windows/audio-visualizer.spec
#
# Produces dist/Audio Visualizer/Audio Visualizer.exe (one folder: starts
# faster than a one-file build, which unpacks itself on every launch).
#
# Overlay.qml imports the shared render tree by relative path, so package/ and
# hyprland/ have to keep their layout relative to windows/qml inside the
# bundle — app.py resolves them from _MEIPASS.

import os
from PyInstaller.utils.hooks import collect_data_files

ROOT = os.path.abspath(os.path.join(SPECPATH, ".."))  # noqa: F821 — set by PyInstaller

datas = [
    (os.path.join(ROOT, "windows", "qml"), os.path.join("windows", "qml")),
    # The whole widget package: QML, the JS the QML imports, and main.xml,
    # which app.py reads for the configuration defaults.
    (os.path.join(ROOT, "package", "contents"), os.path.join("package", "contents")),
    (os.path.join(ROOT, "package", "icon.png"), "package"),
    (os.path.join(ROOT, "translate", "*.po"), "translate"),
    # The settings parser and the settings window (plain QtQuick around the
    # shared studio); the rest of hyprland/ is Quickshell-only.
    (os.path.join(ROOT, "hyprland", "Configuration.js"), "hyprland"),
    (os.path.join(ROOT, "hyprland", "SettingsPage.qml"), "hyprland"),
]
# SoundCard reads its CFFI declarations from .py.h files at import time.
datas += collect_data_files("soundcard", includes=["*.py.h"])

a = Analysis(  # noqa: F821
    [os.path.join(ROOT, "windows", "app.py")],
    pathex=[os.path.join(ROOT, "windows")],
    # app.py imports these only when not running --selftest. The winrt
    # extension modules import each other from C, which PyInstaller cannot see.
    hiddenimports=[
        "audio_capture",
        "media_session",
        "_cffi_backend",
        "winrt.runtime",
        "winrt.windows.foundation",
        "winrt.windows.foundation.collections",
        "winrt.windows.media.control",
        "winrt.windows.storage.streams",
    ],
    datas=datas,
    excludes=["tkinter"],
)
pyz = PYZ(a.pure)  # noqa: F821
exe = EXE(  # noqa: F821
    pyz,
    a.scripts,
    # UTF-8 mode: without it Windows' default text encoding is the ANSI code
    # page (cp1252), for open() and subprocess output alike.
    [("X utf8", None, "OPTION")],
    exclude_binaries=True,
    name="Audio Visualizer",
    console=False,
    icon=os.path.join(ROOT, "package", "icon.png"),
)
coll = COLLECT(exe, a.binaries, a.datas, name="Audio Visualizer")  # noqa: F821
