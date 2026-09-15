// Keep the config root here so Quickshell can import the shared Plasma files.
import "hyprland"

AudioVisualizerShell {
    // Defaults: edit here, or right-click the widget for saved GUI overrides.
    // Reset to defaults in Settings restores these values.
    widgetWidth: 360
    widgetHeight: 104
    verticalPosition: 0.60 // Fraction of screen height, measured from the top.
    monitor: "" // Or an output name such as "DP-1".
    waveColor: "#b4befe"
    visualizerType: 0 // 0: wave, 1: bars, 2: mirror bars, 3: line, 4/5: dots.
    showMpris: true
    showBackground: false
    // Any Plasma appearance setting can be set here, using the same names.
    settings: ({
            alwaysVisible: true
        })
    desktopLayer: true // false: above application windows for easy testing.
}
