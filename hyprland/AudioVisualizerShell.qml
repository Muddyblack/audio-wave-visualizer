pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../package/contents/ui" as Shared
import "Configuration.js" as Configuration

ShellRoot {
    id: root
    property int widgetWidth: 360
    property int widgetHeight: 104
    property real verticalPosition: 0.60
    property string monitor: ""
    property color waveColor: "#b4befe"
    property color textColor: "#cdd6f4"
    property int visualizerType: defaults.visualizerType
    property bool showMpris: defaults.showMpris
    property bool showBackground: defaults.showBg
    property bool desktopLayer: true
    // All keys use the Plasma configuration names (see contents/config/main.xml).
    property var settings: ({})
    property alias audio: audioDefaults
    // Preserve the original audio.* configuration API as defaults, so GUI
    // overrides still take precedence over values declared in shell.qml.
    QtObject {
        id: audioDefaults
        property int numBars: root.defaults.numBars
        // Updating desktop surfaces on several outputs keeps the compositor
        // busy. Keep the shared appearance with a lower standalone cadence;
        // explicit audio.*, GUI and declarative settings still take precedence.
        property int framerate: Math.min(root.defaults.framerate, 15)
        property int sensitivity: root.defaults.sensitivity
        property real noiseReduction: root.defaults.noiseReduction
        property string inputMethod: root.defaults.inputMethod
    }
    property bool settingsOpen: false
    property var userSettings: ({})
    property string settingsError: ""
    readonly property string configPath: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/audio-wave-visualizer/hyprland.json"

    FileView {
        id: preferences
        path: root.configPath
        blockLoading: true
        printErrors: false
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.userSettings = Configuration.parsePreferences(text());
                root.settingsError = "";
            } catch (error) {
                root.settingsError = "Cannot read settings: " + error;
            }
        }
        onSaveFailed: root.settingsError = "Could not save settings to " + root.configPath
        onSaved: root.settingsError = ""
    }
    FileView {
        id: declarativeFile
        path: Quickshell.env("AUDIO_WAVE_DEFAULTS") || ""
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property var declarativeSettings: {
        if (!declarativeFile.path)
            return ({});
        try {
            return Configuration.parsePreferences(declarativeFile.text());
        } catch (error) {
            console.warn("Invalid AUDIO_WAVE_DEFAULTS:", error);
            return ({});
        }
    }
    function configure() {
        settingsEditor.draft = Object.assign({}, configuration);
        settingsOpen = true;
    }
    function saveSettings(overrides) {
        userSettings = overrides;
        preferences.setText(JSON.stringify(overrides, null, 2) + "\n");
    }
    IpcHandler {
        target: "settings"
        function open(): void {
            root.configure();
        }
    }

    FileView {
        id: defaultsFile
        path: Qt.resolvedUrl("../package/contents/config/main.xml").toString().replace(/^file:\/\//, "")
        blockLoading: true
    }
    readonly property var defaults: Configuration.defaults(defaultsFile.text())
    readonly property var baseline: Object.assign({}, defaults, {
        visualizerType: visualizerType,
        showMpris: showMpris,
        showBg: showBackground,
        numBars: audioDefaults.numBars,
        framerate: audioDefaults.framerate,
        sensitivity: audioDefaults.sensitivity,
        noiseReduction: audioDefaults.noiseReduction,
        inputMethod: audioDefaults.inputMethod,
        widgetWidth: widgetWidth,
        widgetHeight: widgetHeight,
        verticalPosition: verticalPosition,
        hAnchor: "center",
        monitor: monitor,
        waveColor: waveColor.toString(),
        textColor: textColor.toString(),
        desktopLayer: desktopLayer,
        pauseWhenCovered: true
    }, settings, declarativeSettings)
    readonly property var configuration: Object.assign({}, baseline, userSettings)
    readonly property bool shouldShow: !!player || configuration.alwaysVisible
    readonly property var selectedScreens: Configuration.screens(Quickshell.screens, configuration.monitor)
    readonly property var widgetRectangles: selectedScreens.map(screen => widgetGeometry(screen))

    // Desktop coordinates for coverage detection; panels use the same bounds
    // with the screen origin removed from their top margin.
    function widgetGeometry(screen) {
        const width = Math.min(configuration.widgetWidth, screen.width);
        const height = configuration.widgetHeight;
        return {
            name: screen.name,
            x: screen.x + (screen.width - width) / 2,
            y: screen.y + Math.max(0, Math.min(screen.height - height, screen.height * configuration.verticalPosition)),
            width: width,
            height: height
        };
    }
    Occlusion {
        id: occlusion
        enabled: root.configuration.pauseWhenCovered && root.configuration.desktopLayer && root.shouldShow
        rectangles: root.widgetRectangles
    }

    QtObject {
        id: audioConfig
        property int numBars: root.configuration.numBars
        property int framerate: root.configuration.framerate
        property int sensitivity: root.configuration.sensitivity
        property real noiseReduction: root.configuration.noiseReduction
        property string inputMethod: root.configuration.inputMethod
    }

    readonly property var player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) || players[0] || null;
    }
    readonly property string runtimeDirectory: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/audio-wave-quickshell"

    Shared.VisualizerCore {
        id: backend
        configuration: audioConfig
        runtimeDirectory: root.runtimeDirectory
        active: root.shouldShow && root.selectedScreens.some(screen => occlusion.coveredScreens.indexOf(screen.name) === -1)
        stopWhenInactive: true
        commandSourceComponent: Component {
            CommandProcess {
                runtimeDirectory: root.runtimeDirectory
            }
        }
    }

    Variants {
        model: root.selectedScreens
        PanelWindow {
            id: panel
            required property var modelData
            readonly property var widgetRectangle: root.widgetGeometry(modelData)
            screen: modelData
            implicitWidth: widgetRectangle.width
            implicitHeight: widgetRectangle.height
            // The window's screen getter changes while it maps/unmaps. Using
            // it here makes visibility depend on creation of the same window.
            visible: root.shouldShow && occlusion.coveredScreens.indexOf(modelData.name) === -1
            anchors.top: true
            margins.top: widgetRectangle.y - modelData.y
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: root.configuration.desktopLayer ? WlrLayer.Bottom : WlrLayer.Top
            WlrLayershell.namespace: "audio-wave-visualizer"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            MouseArea {
                anchors.fill: parent
                z: 10
                acceptedButtons: Qt.RightButton
                onClicked: root.configure()
            }
            Shared.VisualizerView {
                id: view
                anchors.fill: parent
                configuration: root.configuration
                visualizer: backend
                player: root.player
                isPlaying: root.player?.isPlaying ?? false
                artist: root.player?.trackArtist ?? ""
                track: root.player?.trackTitle ?? ""
                playerArtUrl: root.player?.trackArtUrl ?? ""
                positionUnitsPerSecond: 1
                accentColor: root.configuration.waveColor
                systemTextColor: root.configuration.textColor
                fallbackIcon: Component {
                    Image {
                        source: Quickshell.iconPath(view.desktopEntry !== "" ? view.desktopEntry : "audio-x-generic-symbolic", true) || Qt.resolvedUrl("../package/icon.png")
                        fillMode: Image.PreserveAspectFit
                    }
                }
            }
        }
    }

    FloatingWindow {
        visible: root.settingsOpen
        title: "Audio Visualizer Settings"
        implicitWidth: 560
        implicitHeight: 720
        color: "#1e1e2e"
        onVisibleChanged: if (!visible)
            root.settingsOpen = false
        SettingsPage {
            id: settingsEditor
            anchors.fill: parent
            screenNames: Quickshell.screens.map(s => s.name)
            errorMessage: root.settingsError
            onApply: draft => {
                root.saveSettings(Configuration.overrides(root.baseline, draft));
                root.settingsOpen = false;
            }
            onReset: {
                root.saveSettings({});
                draft = Object.assign({}, root.baseline);
            }
            onClose: root.settingsOpen = false
        }
    }
}
