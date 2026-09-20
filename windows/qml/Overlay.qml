// The Windows overlay: the shared render tree, hosted by a plain QQuickView.
//
// VisualizerCore and VisualizerView take their host bindings as properties
// (configuration, runtimeDirectory, commandSourceComponent), so neither needs
// Plasma nor Quickshell — only those three have to be supplied here. Audio
// arrives the same way it does on Linux: windows/audio_capture.py publishes
// frame.ini into runtimeDirectory and VisualizerCore polls it.
import QtQuick
import "../../package/contents/ui" as Shared
import "../../hyprland/Configuration.js" as Configuration
import "../../package/contents/code/HostDefaults.js" as HostDefaults

Item {
    id: root

    // Set by app.py before the view loads: the contents of
    // package/contents/config/main.xml and of the user's settings.json.
    property string runtimeDirectory: ""
    property string defaultsXml: ""
    property string settingsJson: ""

    readonly property var defaults: Configuration.defaults(defaultsXml)
    readonly property var userSettings: {
        if (!settingsJson)
            return ({});
        try {
            return Configuration.parsePreferences(settingsJson);
        } catch (error) {
            console.warn("Ignoring invalid settings:", error);
            return ({});
        }
    }
    // The Hyprland standalone defaults fit a desktop-wide overlay; the Plasma
    // ones assume a panel applet. alwaysVisible because there is no MPRIS on
    // Windows yet, so nothing would ever mark a player as present.
    readonly property var configuration: Object.assign({}, defaults, HostDefaults.hyprland, {
        alwaysVisible: true,
        desktopLayer: true
    }, userSettings)

    // VisualizerCore drives feeder.sh through this on Linux. Windows has no
    // feeder to launch — audio_capture.py is already running — so the calls
    // go nowhere and only frame.ini matters.
    Component {
        id: nullCommandSource
        QtObject {
            property var connectedSources: []
            signal newData(string source, var data)
            function connectSource(source, detached, owned) {
            }
            function disconnectSource(source) {
            }
            function cancelSource(source) {
            }
        }
    }

    // VisualizerCore watches these for changes with Connections, which needs a
    // real QObject — the merged configuration above is a plain JS object.
    QtObject {
        id: audioConfig
        property int visualizerType: root.configuration.visualizerType
        property bool reducedMotion: root.configuration.reducedMotion
        property int numBars: root.configuration.numBars
        property int framerate: root.configuration.framerate
        property int sensitivity: root.configuration.sensitivity
        property real noiseReduction: root.configuration.noiseReduction
        property string inputMethod: root.configuration.inputMethod
        property string inputSource: root.configuration.inputSource
        property int lowCutoff: root.configuration.lowCutoff
        property int highCutoff: root.configuration.highCutoff
        property string frequencyScale: root.configuration.frequencyScale
        property real bassWeight: root.configuration.bassWeight
        property real trebleWeight: root.configuration.trebleWeight
        property int silenceDecay: root.configuration.silenceDecay
    }

    Shared.VisualizerCore {
        id: backend
        configuration: audioConfig
        runtimeDirectory: root.runtimeDirectory
        commandSourceComponent: nullCommandSource
    }

    Shared.VisualizerView {
        anchors.fill: parent
        configuration: root.configuration
        visualizer: backend
    }
}
