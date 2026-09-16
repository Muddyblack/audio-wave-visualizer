import QtQuick

// Audio-specific interface; loading, validation and lifetime live in one host.
CustomStyleLoader {
    id: root
    required property var waveform
    interfaceName: "visualizer"
    loaderName: "customVisualizerLoader"
    contentVisible: !waveform.backendFailed

    interfaceObject: QtObject {
        readonly property int apiVersion: 1
        readonly property var bars: root.waveform.bars
        readonly property int numBars: root.waveform.numBars
        readonly property real maxRange: root.waveform.maxRange
        readonly property real bass: root.waveform.bass
        readonly property real mid: root.waveform.mid
        readonly property real high: root.waveform.high
        readonly property real energy: {
            const bars = root.waveform.bars;
            if (!root.waveform.hasAudio || !bars.length)
                return 0;
            return Math.max(0, Math.min(1, bars.reduce((sum, value) => sum + value, 0) / bars.length / Math.max(1, root.waveform.maxRange)));
        }
        readonly property bool attack: root.waveform.attack
        readonly property bool hasAudio: root.waveform.hasAudio
        readonly property bool backendFailed: root.waveform.backendFailed
        readonly property bool active: root.visible && hasAudio && !backendFailed
        readonly property real frameTimeMs: root.waveform.visualFrameTime
        readonly property bool reducedMotion: root.waveform.reducedMotion
        readonly property bool softwareRendering: !root.waveform.shaderSupported
        readonly property color waveColor: root.waveform.waveColor
        readonly property color textColor: root.waveform.textColor
        readonly property color coverColor1: root.waveform.coverColor1
        readonly property color coverColor2: root.waveform.coverColor2
        readonly property real lineWidth: root.waveform.lineWidth
        readonly property bool fillWave: root.waveform.fillWave
        readonly property bool glowWave: root.waveform.glowWave
        readonly property string direction: root.waveform.vizDirection
    }
}
