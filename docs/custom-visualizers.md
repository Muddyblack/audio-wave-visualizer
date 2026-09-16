# Custom QML visualizers and progress bars

Open **Settings → Visualizer → Custom visualizers → Manage…**, choose **Import QML…**, and
select a trusted local `.qml` file. The live preview uses sample audio. Apply the
settings to use it with real audio. **Try example** loads the included Pulse Bars
style. Choose **Built-in visualizer** or click a built-in style tile to switch back.
**Remove** forgets a style without deleting its files.

Importing remembers the file's location; it does not copy or upload files. Keep
the QML file and any sibling assets in a permanent directory. To share a style,
send that directory (optionally zipped); the recipient extracts it and imports
the main QML file. You can import several files and switch between them in the
dropdown. File names supply the display names.

Custom visualizer styles replace the waveform inside existing layouts on both Plasma and
Hyprland. Orbit, lyrics-only layouts, and the pill's small EQ indicator have
separate renderers. In a pill, select the wave option to show a custom style.
Full card layout plugins and ZIP installation are not part of this interface.

## Custom progress bars

Open **Settings → Controls → Custom progress bars → Manage…** and import a QML file, or
choose **Try example** for the included gradient bar. This picker works just like
the visualizer picker, with its own saved list. Selecting a built-in progress bar
switches back to that style.

Custom progress bars replace the bar and its time labels inside the card. They
also take precedence over the built-in cover ring. They do not replace the pill's
separate thin progress indicator or add a bar to layouts that have none.

## Trust and errors

QML is executable code running in the Plasma or Quickshell host, **not a
sandboxed theme format**. Only import styles you trust. A style can use imports
and APIs available to the host; poorly written code can freeze or crash it.
Selecting a file immediately executes it for preview.

Missing files, QML load failures, and unsupported API versions fall back to the
selected built-in waveform. The custom style preview displays an error; the host
log contains QML diagnostics. Runtime script errors and performance problems
cannot be reliably caught by the loader. Select a built-in style to disable an
extension. If the host cannot start, clear `customVisualizer` and `customProgressBar` in its configuration.

Local saved looks can remember a custom style. Portable JSON look import/export
excludes custom file selections and libraries, so exchanging an ordinary
look never enables executable QML. Share custom files separately.

## Visualizer API version 1

Start with [PulseBars.qml](../package/contents/examples/PulseBars.qml). The root
must inherit `Item` and declare these properties:

```qml
import QtQuick

Item {
    id: root
    readonly property int apiVersion: 1
    required property var visualizer

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: parent.height * root.visualizer.energy
        color: root.visualizer.waveColor
    }
}
```

The host sizes the root to the waveform area and clips drawing to it. Bind to
the supplied `visualizer` object; do not depend on internal widget objects. All
interface properties are read-only and update with the host:

| Property | Meaning |
| --- | --- |
| `apiVersion` | Interface version, currently `1` |
| `bars`, `numBars`, `maxRange` | Smoothed spectrum values, count, and amplitude ceiling; divide each bar by `maxRange` to normalize |
| `bass`, `mid`, `high` | Source band levels in the range 0–1 |
| `energy` | Mean normalized displayed bar amplitude, 0–1 |
| `attack` | Audio onset indicator |
| `hasAudio`, `backendFailed` | Audio and backend state |
| `active` | Visible, receiving audio, and backend healthy |
| `frameTimeMs` | Shared audio frame clock, milliseconds; use differences for animation |
| `reducedMotion` | User preference to reduce decorative animation |
| `softwareRendering` | Whether the built-in renderer would use its software fallback |
| `waveColor`, `textColor` | Current visualizer and text colors |
| `coverColor1`, `coverColor2` | Artwork palette colors |
| `lineWidth`, `fillWave`, `glowWave` | Drawing preferences; glow is disabled by battery saving |
| `direction` | `"up"` or `"down"` |

Use the shared frame clock rather than a separate fast timer. Stop decorative
work when `active` is false and respect `reducedMotion`. Hidden styles are
unloaded and recreated when visible, so do not rely on retaining animation
state. The host clock follows the configured frame rate and battery limits and
stops advancing during settled silence.

Canvas-based styles can use `Connections` targeting `visualizer` and call
`requestPaint()` on bar/color/size changes. Simple Qt Quick shapes work on both
GPU and software rendering. Styles using shaders should provide their own
software fallback. Restart the host after editing an already-loaded QML file,
since the QML engine may cache it.

Loading and sizing follow Qt's [Loader behavior](https://doc.qt.io/qt-6/qml-qtquick-loader.html).


## Progress bar API version 1

Start with [GradientProgress.qml](../package/contents/examples/GradientProgress.qml).
Declare `readonly property int apiVersion: 1` and
`required property var progressBar` on an `Item` root. The host supplies width and
height; your `implicitHeight` is respected within 9–28 logical pixels to fit the
existing card layouts. Avoid binding `implicitHeight` to the supplied height.
Your style owns both drawing and pointer handling.

| Property / method | Meaning |
| --- | --- |
| `apiVersion` | Interface version, currently `1` |
| `progress` | Current fraction, 0–1 |
| `position`, `duration` | Playback position and duration in seconds, on both hosts |
| `elapsedText`, `totalText`, `remainingText` | Formatted timing labels |
| `isPlaying`, `hasAudio`, `active` | Playback, audio, and visibility/host activity |
| `canSeek` | Whether the current player allows seeking |
| `seekToFraction(fraction)` | Seek within 0–1 using the player's native units; returns success and rechecks capabilities |
| `showTimes`, `timeFormat`, `centerTimes` | Label preferences; time format is `"total"` or `"remaining"` |
| `textColor`, `startColor`, `endColor`, `waveColor` | Current colors |
| `track`, `artist` | Current track metadata |
| `reducedMotion`, `frameTimeMs` | Motion preference and the shared audio frame clock |

For example, a click handler can call:

```qml
MouseArea {
    anchors.fill: parent
    enabled: root.progressBar.canSeek
    onClicked: mouse => {
        if (width > 0)
            root.progressBar.seekToFraction(mouse.x / width);
    }
}
```

The host reuses its existing playback clock and seek adapter, so extensions do
not need their own timers, MPRIS connections, or seconds/microseconds conversion.
The shared loader unloads hidden styles and restores the built-in bar on load
errors. A visualizer file cannot be used as a progress bar without implementing
the corresponding interface.
