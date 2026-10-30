// The Windows overlay: the shared render tree, hosted by a plain QQuickView.
//
// VisualizerCore and VisualizerView take their host bindings as properties
// (configuration, runtimeDirectory, commandSourceComponent), so neither needs
// Plasma nor Quickshell — only those three have to be supplied here. Audio
// arrives the same way it does on Linux: windows/audio_capture.py publishes
// frame.ini into runtimeDirectory and VisualizerCore polls it. The player and
// the settings window are wired up the way hyprland/AudioVisualizerShell.qml
// does it, with windows/media_session.py standing in for MPRIS.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import "../../package/contents/ui" as Shared
import "../../package/contents/ui/text"
import "../../hyprland" as Hyprland
import "../../hyprland/Configuration.js" as Configuration
import "../../package/contents/code/HostDefaults.js" as HostDefaults
import "../../package/contents/code/Layouts.js" as LayoutSizes

Item {
    id: root

    // Set by app.py before the view loads: the contents of
    // package/contents/config/main.xml and of the user's settings.json, the
    // media sessions (media_session.MediaSessions) and the settings store.
    property string runtimeDirectory: ""
    property string defaultsXml: ""
    property string settingsJson: ""
    property var media: null
    property var host: null

    readonly property var defaults: Configuration.defaults(defaultsXml)
    property var userSettings: {
        if (!settingsJson)
            return ({});
        try {
            return Configuration.parsePreferences(settingsJson);
        } catch (error) {
            console.warn("Ignoring invalid settings:", error);
            return ({});
        }
    }
    // The Hyprland standalone defaults fit a desktop overlay; the Plasma ones
    // assume a panel applet. Without media sessions (not Windows, or winrt
    // missing) nothing would ever mark a player as present, so keep the bars.
    // The extra keys are the ones AudioVisualizerShell.qml adds to its baseline.
    readonly property var settingsBaseline: Object.assign({}, defaults, HostDefaults.hyprland, {
        widgetWidth: 360,
        widgetHeight: 104,
        ambientGlow: false,
        ambientGlowRadius: 80,
        ambientGlowIntensity: 0.7,
        ambientGlowMode: "cover",
        waveColor: "#b4befe",
        textColor: "#cdd6f4"
    }, root.media && root.media.available ? {} : {
        alwaysVisible: true
    })
    readonly property var configuration: Object.assign({}, settingsBaseline, userSettings)
    readonly property string language: configuration.language ?? ""
    onLanguageChanged: loadCatalog()
    Component.onCompleted: loadCatalog()
    function loadCatalog() {
        I18n.available = host ? host.catalogLanguages() : [];
        const texts = I18n.candidates(language).map(code => host ? host.readCatalog(code) : "");
        I18n.load(texts.find(text => text) || "");
        if (host)
            host.setLabels(JSON.stringify({
                hide: I18n.i18n("Hide"),
                show: I18n.i18n("Show"),
                adjust: I18n.i18n("Move / resize…"),
                lock: I18n.i18n("Lock in place"),
                adjusting: I18n.i18n("Audio Visualizer — drag, resize, then close (×) or Enter to lock"),
                reset: I18n.i18n("Reset position"),
                settings: I18n.i18n("Settings…"),
                quit: I18n.i18n("Quit"),
                saveFailed: I18n.i18n("Could not save settings to %1: %2")
            }));
    }

    function saveSettings(overrides) {
        userSettings = overrides;
        if (root.host)
            root.host.saveSettings(JSON.stringify(overrides, null, 2) + "\n");
    }

    readonly property var player: root.media ? root.media.player : null

    // Where the card goes on its screen, as hyprland/AudioVisualizerShell.qml
    // places its panel; app.py moves the window there unless the user has
    // placed it by hand (Move / resize).
    readonly property var widgetRect: {
        const screen = Configuration.screens(Qt.application.screens, configuration.monitor)[0];
        if (!screen)
            return ({
                    x: 0,
                    y: 0,
                    width: 360,
                    height: 104
                });
        const sx = screen.virtualX, sy = screen.virtualY;
        const layoutSize = LayoutSizes.size(configuration);
        const defaultSize = configuration.widgetWidth === 360 && configuration.widgetHeight === 104;
        let baseWidth = defaultSize ? layoutSize[0] : configuration.widgetWidth;
        const dock = configuration.dockMode ?? "none";
        const isDocked = dock !== "none";
        if (isDocked && (configuration.widthExpansion ?? true) && !player)
            baseWidth = Math.min(baseWidth, 220);
        const width = Math.min(baseWidth, screen.width);
        const height = defaultSize ? layoutSize[1] : configuration.widgetHeight;
        const barH = configuration.barHeight ?? 36;
        const gap = configuration.dockMargin ?? 8;
        let y;
        if (dock === "top" || (dock === "auto" && configuration.verticalPosition <= 0.15))
            y = sy + barH + gap;
        else if (dock === "bottom" || (dock === "auto" && configuration.verticalPosition >= 0.85))
            y = sy + screen.height - height - barH - gap;
        else
            y = sy + Math.max(0, Math.min(screen.height - height, screen.height * configuration.verticalPosition));
        let x;
        if (configuration.hAnchor === "left")
            x = sx + (isDocked ? gap : 0);
        else if (configuration.hAnchor === "right")
            x = sx + screen.width - width - (isDocked ? gap : 0);
        else
            x = sx + (screen.width - width) / 2;
        return ({
                x: Math.round(x),
                y: Math.round(y),
                width: Math.round(width),
                height: Math.round(height)
            });
    }

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
        id: view
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
        playerCount: root.media ? root.media.playerCount : 0
        switchPlayer: () => root.media && root.media.cyclePlayer()
        accentColor: root.configuration.waveColor
        systemTextColor: root.configuration.textColor
        fallbackIcon: Component {
            Image {
                source: Qt.resolvedUrl("../../package/icon.png")
                fillMode: Image.PreserveAspectFit
            }
        }
    }

    // The tray's / right-click menu's Settings… sets this.
    property bool settingsOpen: false

    Window {
        objectName: "settingsWindow" // app.py gives it a shader cache
        visible: root.settingsOpen
        title: I18n.i18n("Audio Visualizer Settings")
        // Centred on its screen and within the work area: left to the window
        // manager it opened with the title bar above the top edge.
        width: Math.min(1180, Screen.desktopAvailableWidth - 40)
        height: Math.min(800, Screen.desktopAvailableHeight - 60)
        x: Screen.virtualX + (Screen.desktopAvailableWidth - width) / 2
        y: Screen.virtualY + Math.max(40, (Screen.desktopAvailableHeight - height) / 2)
        color: "#1e1e2e"
        onVisibleChanged: if (!visible)
            root.settingsOpen = false
        Loader {
            anchors.fill: parent
            active: root.settingsOpen
            sourceComponent: Component {
                Hyprland.SettingsPage {
                    id: settingsEditor
                    Component.onCompleted: draft = Object.assign({}, root.configuration)
                    anchors.fill: parent
                    screenNames: Qt.application.screens.map(s => s.name)
                    defaults: root.settingsBaseline
                    savedDraft: root.configuration
                    commandSourceComponent: nullCommandSource
                    liveVisualizer: backend
                    livePlayer: root.player
                    liveIsPlaying: root.player?.isPlaying ?? false
                    errorMessage: root.host ? root.host.settingsError : ""
                    onApply: draft => root.saveSettings(Configuration.overrides(root.settingsBaseline, draft))
                    onReset: {
                        root.saveSettings({});
                        draft = Object.assign({}, root.settingsBaseline);
                    }
                    onClose: root.settingsOpen = false
                }
            }
        }
    }
}
