import QtQuick
import QtQuick.Controls as QQC

// Backend status and both renderers share the same area in every layout.
Waveform {
    id: root
    required property var configuration
    required property var visualizer
    property string defaultFontFamily: Qt.application.font.family

    bars: root.visualizer?.bars ?? []
    numBars: root.visualizer?.numBars ?? 0
    maxRange: root.visualizer?.maxRange ?? 1000
    hasAudio: root.visualizer?.hasAudio ?? false
    backendFailed: root.visualizer?.backendFailed ?? false
    lineWidth: root.configuration.lineWidth
    fillWave: root.configuration.fillWave
    glowWave: root.configuration.glowWave
    visualizerType: root.configuration.visualizerType
    visualFrameTime: root.visualizer?.frameTimeMs ?? 0
    bass: root.visualizer?.bass ?? 0
    mid: root.visualizer?.mid ?? 0
    high: root.visualizer?.high ?? 0
    attack: root.visualizer?.attack ?? false
    reducedMotion: root.configuration.reducedMotion ?? false
    simpleRender: root.configuration.simpleRender ?? false
    vizDirection: root.configuration.vizDirection ?? "up"
    vizColorMode: root.configuration.vizColorMode ?? "solid"
    vizPalette: root.configuration.vizPalette ?? "aurora"
    hueReactive: root.configuration.hueReactive ?? false
    bloom: root.configuration.bloom ?? 1
    ribbonCurvature: root.configuration.ribbonCurvature ?? 1
    ribbonFullness: root.configuration.ribbonFullness ?? 1

    // Backend down: say what broke and what to type, instead of
    // drawing a flat line that looks exactly like silence.
    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: 0
        visible: root.backendFailed

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.pixelSize: 10
            color: root.textColor
            opacity: 0.8
            text: root.visualizer?.backendMessage ?? ""
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
            // Monospace only when the line is literally a
            // command to type.
            font.family: root.visualizer?.backendCode === "no-cava" ? "monospace" : root.defaultFontFamily
            font.pixelSize: 9
            color: root.textColor
            opacity: 0.55
            text: root.visualizer?.backendAction ?? ""
            visible: text !== ""
        }

        QQC.ToolTip.visible: hoverHandler.hovered
        QQC.ToolTip.text: (root.visualizer?.backendMessage ?? "") + "\n" + (root.visualizer?.backendHint ?? "")
        HoverHandler {
            id: hoverHandler
        }
    }
}
