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

ROOT = os.path.abspath(os.path.join(SPECPATH, ".."))  # noqa: F821 — set by PyInstaller

datas = [
    (os.path.join(ROOT, "windows", "qml"), os.path.join("windows", "qml")),
    # The whole widget package: QML, the JS the QML imports, and main.xml,
    # which app.py reads for the configuration defaults.
    (os.path.join(ROOT, "package", "contents"), os.path.join("package", "contents")),
    (os.path.join(ROOT, "package", "icon.png"), "package"),
    # Only the settings parser; the rest of hyprland/ is Quickshell-only.
    (os.path.join(ROOT, "hyprland", "Configuration.js"), "hyprland"),
]

a = Analysis(  # noqa: F821
    [os.path.join(ROOT, "windows", "app.py")],
    pathex=[os.path.join(ROOT, "windows")],
    # app.py imports it only when not running --selftest.
    hiddenimports=["audio_capture"],
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
