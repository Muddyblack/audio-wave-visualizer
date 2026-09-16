pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import "../package/contents/ui" as Shared
import "Configuration.js" as Configuration
import "../package/contents/code/Layouts.js" as LayoutSizes

ShellRoot {
    id: root
    property int widgetWidth: 360
    property int widgetHeight: 104
    property real verticalPosition: 0.60
    property string monitor: ""
    // Optional same-window wallpaper provider; a compositor layer is not a texture.
    property Component backdropComponent: null
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
        property string inputSource: root.defaults.inputSource
        property int lowCutoff: root.defaults.lowCutoff
        property int highCutoff: root.defaults.highCutoff
        property string frequencyScale: root.defaults.frequencyScale
        property real bassWeight: root.defaults.bassWeight
        property real trebleWeight: root.defaults.trebleWeight
        property int silenceDecay: root.defaults.silenceDecay
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
    // Settings › Audio › Run diagnostics.
    Process {
        id: doctorProcess
        property var done: null
        command: ["bash", Qt.resolvedUrl("../package/contents/code/doctor.sh").toString().replace(/^file:\/\//, "")]
        stdout: StdioCollector {
            onStreamFinished: {
                if (doctorProcess.done)
                    doctorProcess.done(text);
                doctorProcess.done = null;
            }
        }
    }
    function runDiagnostics(done) {
        doctorProcess.done = done;
        doctorProcess.running = true;
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
        inputSource: audioDefaults.inputSource,
        lowCutoff: audioDefaults.lowCutoff,
        highCutoff: audioDefaults.highCutoff,
        frequencyScale: audioDefaults.frequencyScale,
        bassWeight: audioDefaults.bassWeight,
        trebleWeight: audioDefaults.trebleWeight,
        silenceDecay: audioDefaults.silenceDecay,
        widgetWidth: widgetWidth,
        widgetHeight: widgetHeight,
        verticalPosition: verticalPosition,
        hAnchor: "center",
        dockMode: "none",
        dockMargin: 8,
        barHeight: 36,
        widthExpansion: true,
        ambientGlow: false,
        ambientGlowRadius: 80,
        ambientGlowIntensity: 0.7,
        ambientGlowMode: "cover",
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
        // The default 360 × 104 follows the chosen layout; explicit sizes win.
        const layoutSize = LayoutSizes.size(configuration);
        const defaultSize = configuration.widgetWidth === 360 && configuration.widgetHeight === 104;
        let baseWidth = defaultSize ? layoutSize[0] : configuration.widgetWidth;

        // Smart width expansion when docked to status bar (e.g. Waybar / Caelestia)
        const dock = configuration.dockMode ?? "none";
        const isDocked = dock !== "none";
        if (isDocked && (configuration.widthExpansion ?? true)) {
            if (!player) {
                baseWidth = Math.min(baseWidth, 220);
            }
        }

        const width = Math.min(baseWidth, screen.width);
        const height = defaultSize ? layoutSize[1] : configuration.widgetHeight;

        // Automatic margin negotiation for status bars
        const barH = configuration.barHeight ?? 36;
        const gap = configuration.dockMargin ?? 8;

        let yPos;
        if (dock === "top" || (dock === "auto" && configuration.verticalPosition <= 0.15)) {
            yPos = screen.y + barH + gap;
        } else if (dock === "bottom" || (dock === "auto" && configuration.verticalPosition >= 0.85)) {
            yPos = screen.y + screen.height - height - barH - gap;
        } else {
            yPos = screen.y + Math.max(0, Math.min(screen.height - height, screen.height * configuration.verticalPosition));
        }

        let xPos;
        if (configuration.hAnchor === "left") {
            xPos = screen.x + (isDocked ? gap : 0);
        } else if (configuration.hAnchor === "right") {
            xPos = screen.x + screen.width - width - (isDocked ? gap : 0);
        } else {
            xPos = screen.x + (screen.width - width) / 2;
        }

        return {
            name: screen.name,
            x: xPos,
            y: yPos,
            width: width,
            height: height,
            docked: isDocked
        };
    }
    Occlusion {
        id: occlusion
        enabled: root.configuration.pauseWhenCovered && root.configuration.desktopLayer && root.shouldShow
        rectangles: root.widgetRectangles
    }

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

    // The player switcher pins a player; otherwise follow the one playing.
    property var pinnedPlayer: null
    function cyclePlayer() {
        const players = Mpris.players.values;
        if (players.length === 0)
            return;
        const index = players.indexOf(root.player);
        root.pinnedPlayer = players[(index + 1) % players.length];
    }
    readonly property var player: {
        const players = Mpris.players.values;
        if (root.pinnedPlayer && players.indexOf(root.pinnedPlayer) !== -1)
            return root.pinnedPlayer;
        return players.find(p => p.isPlaying) || players[0] || null;
    }
    readonly property string runtimeDirectory: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/audio-wave-quickshell"

    readonly property bool onBattery: (configuration.batterySaver ?? false) && UPower.onBattery
    Shared.VisualizerCore {
        id: backend
        batterySaverActive: root.onBattery
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
            WlrLayershell.layer: widgetRectangle.docked ? WlrLayer.Top : (root.configuration.desktopLayer ? WlrLayer.Bottom : WlrLayer.Top)
            WlrLayershell.namespace: root.configuration.compositorGlass && root.configuration.showBg && ["glass", "liquid"].includes(root.configuration.surfaceStyle) ? "audio-wave-visualizer-glass" : "audio-wave-visualizer"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            MouseArea {
                anchors.fill: parent
                z: 10
                acceptedButtons: Qt.RightButton
                onClicked: root.configure()
            }
            Loader {
                id: backdrop
                anchors.fill: parent
                sourceComponent: root.backdropComponent
                visible: false
            }
            Shared.VisualizerView {
                id: view
                backdropSource: backdrop.item
                anchors.fill: parent
                configuration: root.configuration
                setLyricsOffset: value => root.saveSettings(Object.assign({}, root.userSettings, {
                        lyricsOffset: value
                    }))
                visualizer: backend
                player: root.player
                isPlaying: root.player?.isPlaying ?? false
                artist: root.player?.trackArtist ?? ""
                track: root.player?.trackTitle ?? ""
                playerArtUrl: root.player?.trackArtUrl ?? ""
                positionUnitsPerSecond: 1
                playerCount: Mpris.players.values.length
                switchPlayer: root.cyclePlayer
                onBattery: root.onBattery
                accentColor: root.configuration.waveColor
                systemTextColor: root.configuration.textColor
                fallbackIcon: Component {
                    Image {
                        source: (view.desktopEntry !== "" ? Quickshell.iconPath(view.desktopEntry, true) : "") || Qt.resolvedUrl("../package/icon.png")
                        fillMode: Image.PreserveAspectFit
                    }
                }
            }

            // Hover details (tooltip or drawer) below the card. The window
            // leaves 50 px around the details for their shadow.
            PopupWindow {
                id: detailsPopup
                // Named so the details' own `view` property does not shadow it.
                readonly property var cardView: view
                anchor.item: view
                anchor.rect.x: -50
                anchor.rect.y: (view.detailsPopupMode === "drawer" ? view.height - 14 : view.height + 10) - 50
                implicitWidth: Math.max(view.width, 250) + 100
                implicitHeight: hoverDetails.implicitHeight + 100
                color: "transparent"
                visible: view.detailsVisible && panel.visible
                Shared.TrackDetails {
                    id: hoverDetails
                    anchors.fill: parent
                    anchors.margins: 50
                    view: detailsPopup.cardView
                    mode: detailsPopup.cardView.detailsPopupMode
                }
            }
        }
    }

    FloatingWindow {
        visible: root.settingsOpen
        title: "Audio Visualizer Settings"
        implicitWidth: 1180
        implicitHeight: 800
        color: "#1e1e2e"
        onVisibleChanged: if (!visible)
            root.settingsOpen = false
        SettingsPage {
            id: settingsEditor
            anchors.fill: parent
            screenNames: Quickshell.screens.map(s => s.name)
            defaults: root.baseline
            savedDraft: root.configuration
            commandSourceComponent: Component {
                CommandProcess {}
            }
            diagnosticsRunner: root.runDiagnostics
            errorMessage: root.settingsError
            onApply: draft => {
                root.saveSettings(Configuration.overrides(root.baseline, draft));
            }
            onReset: {
                root.saveSettings({});
                draft = Object.assign({}, root.baseline);
            }
            onClose: root.settingsOpen = false
        }
    }
}
