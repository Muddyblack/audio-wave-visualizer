import QtQuick

// GPU counterpart of WaveCanvas: the same inputs are drawn by one fragment
// shader, so an audio frame costs a few uniform writes instead of a CPU raster
// pass, a texture upload and MultiEffect blur passes. Waveform.qml keeps
// WaveCanvas for scene graphs that cannot run shaders.
Item {
    id: wave

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
    // Two Gaussians fitted to WaveCanvas' MultiEffect shadow (shadowBlur 1,
    // blurMax 8): line, edge, dot and translucent-fill profiles.
    property real glowSigma: 2.136
    property real glowGain: 0.533
    property real glowSigma2: 5.875
    property real glowGain2: 0.091

    // The shader holds 32 vec4 blocks; settings allow at most 128 bars.
    readonly property int _count: Math.max(0, Math.min(numBars, 128))
    readonly property bool _drawing: visible && hasAudio && !backendFailed && width > 0 && height > 0
    readonly property var _blockNames: Array.from({
        length: 32
    }, (_, index) => "levels" + index)

    // The same cosine edge taper WaveCanvas applies.
    readonly property var _tapers: {
        const values = [];
        for (let i = 0; i < _count; i++) {
            const pos = _count > 1 ? i / (_count - 1) : 0.5;
            const edge = 0.15;
            const weight = pos < edge ? pos / edge : (pos > 1.0 - edge ? (1.0 - pos) / edge : 1.0);
            values.push(weight < 1.0 ? 0.5 - 0.5 * Math.cos(weight * Math.PI) : 1.0);
        }
        return values;
    }

    // Hidden, idle and failed states skip uploads; becoming visible uploads
    // the latest frame.
    function upload() {
        if (!_drawing)
            return;
        const n = _count;
        const samples = bars;
        const range = maxRange;
        const taper = _tapers;
        const level = i => i < n ? (samples[i] || 0) / range * taper[i] : 0;
        for (let block = 0; block * 4 < n; block++) {
            const i = block * 4;
            effect[_blockNames[block]] = Qt.vector4d(level(i), level(i + 1), level(i + 2), level(i + 3));
        }
        effect.barCount = n;
    }

    onBarsChanged: upload()
    on_DrawingChanged: upload()
    on_TapersChanged: upload()
    onMaxRangeChanged: upload()

    Rectangle {
        // WaveCanvas' idle state: a 1.2 px round-capped centre line.
        objectName: "idleLine"
        visible: !wave.hasAudio && !wave.backendFailed
        x: 1.4
        y: wave.height / 2 - 0.6
        width: Math.max(0, wave.width - 2.8)
        height: 1.2
        radius: 0.6
        antialiasing: true
        color: Qt.rgba(wave.textColor.r, wave.textColor.g, wave.textColor.b, 0.35)
    }

    ShaderEffect {
        id: effect
        objectName: "waveEffect"
        anchors.fill: parent
        visible: wave._drawing
        fragmentShader: Qt.resolvedUrl("../shaders/visualizer.frag.qsb")

        // Uniforms, matched to the shader by name.
        readonly property size canvasSize: Qt.size(width, height)
        readonly property real pixelRatio: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1
        readonly property real style: wave.visualizerType
        property real barCount: 0
        readonly property real lineWidth: wave.lineWidth
        readonly property real fillAmount: wave.fillWave ? 1 : 0
        readonly property real glowAmount: wave.glowWave ? 1 : 0
        readonly property real glowSigma: wave.glowSigma
        readonly property real glowGain: wave.glowGain
        readonly property real glowSigma2: wave.glowSigma2
        readonly property real glowGain2: wave.glowGain2
        readonly property color waveColor: wave.waveColor
        property vector4d levels0
        property vector4d levels1
        property vector4d levels2
        property vector4d levels3
        property vector4d levels4
        property vector4d levels5
        property vector4d levels6
        property vector4d levels7
        property vector4d levels8
        property vector4d levels9
        property vector4d levels10
        property vector4d levels11
        property vector4d levels12
        property vector4d levels13
        property vector4d levels14
        property vector4d levels15
        property vector4d levels16
        property vector4d levels17
        property vector4d levels18
        property vector4d levels19
        property vector4d levels20
        property vector4d levels21
        property vector4d levels22
        property vector4d levels23
        property vector4d levels24
        property vector4d levels25
        property vector4d levels26
        property vector4d levels27
        property vector4d levels28
        property vector4d levels29
        property vector4d levels30
        property vector4d levels31
    }
}
