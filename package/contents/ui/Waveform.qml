pragma ComponentBehavior: Bound
import QtQuick

// Picks the waveform renderer for the scene graph in use: WaveShader wherever
// shaders run, WaveCanvas on the software renderer (which ignores ShaderEffect).
Item {
    id: root

    property var bars: []
    property int numBars: bars.length
    property real maxRange: 1000
    property bool hasAudio: false
    property bool backendFailed: false
    property color waveColor: "#ffffff"
    property color textColor: "#ffffff"
    property real lineWidth: 2
    property bool fillWave: true
    property bool glowWave: true
    property int visualizerType: 0
    // Unknown until the window's scene graph starts; assume shaders until then.
    readonly property bool shaderSupported: GraphicsInfo.api !== GraphicsInfo.Software

    Loader {
        id: shaderLoader
        objectName: "shaderLoader"
        anchors.fill: parent
        active: root.shaderSupported
        sourceComponent: WaveShader {
            bars: root.bars
            numBars: root.numBars
            maxRange: root.maxRange
            hasAudio: root.hasAudio
            backendFailed: root.backendFailed
            waveColor: root.waveColor
            textColor: root.textColor
            lineWidth: root.lineWidth
            fillWave: root.fillWave
            glowWave: root.glowWave
            visualizerType: root.visualizerType
        }
    }

    Loader {
        id: canvasLoader
        objectName: "canvasLoader"
        anchors.fill: parent
        active: !root.shaderSupported
        sourceComponent: WaveCanvas {
            bars: root.bars
            numBars: root.numBars
            maxRange: root.maxRange
            hasAudio: root.hasAudio
            backendFailed: root.backendFailed
            waveColor: root.waveColor
            textColor: root.textColor
            lineWidth: root.lineWidth
            fillWave: root.fillWave
            glowWave: root.glowWave
            visualizerType: root.visualizerType
        }
    }
}
