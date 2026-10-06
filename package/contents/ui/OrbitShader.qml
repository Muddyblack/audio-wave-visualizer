pragma ComponentBehavior: Bound
import QtQuick
import "../code/WaveMath.js" as WaveMath

// All five orbit styles in one GPU pass; particle simulation stays on audio time.
ShaderEffect {
    id: effect
    required property var orbit
    readonly property size canvasSize: Qt.size(width, height)
    readonly property real halfCount: orbit.half
    readonly property real innerRadius: orbit.geometry().inner
    readonly property real reach: orbit.geometry().reach
    readonly property real ringRotation: orbit.ringRotation
    // Frame timestamps are epoch milliseconds. Bound phases before converting
    // to GPU floats; all ribbon frequencies repeat together every 10π seconds.
    readonly property real timeSeconds: orbit.reducedMotion ? 0 : orbit.seconds % (Math.PI * 10)
    readonly property real style: Math.max(0, ["bars", "wave", "dots", "ribbon", "sparks"].indexOf(orbit.orbitStyle))
    readonly property real lineWidth: orbit.lineWidth
    readonly property real fillAmount: orbit.fillWave ? 1 : 0
    readonly property real glowAmount: orbit.glowWave ? Math.max(0, Math.min(2, orbit.bloom)) : 0
    readonly property real failed: orbit.backendFailed ? 1 : 0
    // The shader holds six stops; longer user ranges are resampled to fit.
    readonly property var stops: WaveMath.limitStops(orbit.colorStops, 6)
    readonly property real colorCount: stops.length
    readonly property real particleCount: Math.min(32, orbit.particles.length)
    readonly property color color0: effect.stops[0] || "#ffffff"
    readonly property color color1: effect.stops[1] || effect.stops[0]
    readonly property color color2: effect.stops[2] || effect.stops[0]
    readonly property color color3: effect.stops[3] || effect.stops[0]
    readonly property color color4: effect.stops[4] || effect.stops[0]
    readonly property color color5: effect.stops[5] || effect.stops[0]
    property vector4d levels0: Qt.vector4d(0, 0, 0, 0)
    property vector4d levels1: Qt.vector4d(0, 0, 0, 0)
    property vector4d levels2: Qt.vector4d(0, 0, 0, 0)
    property vector4d levels3: Qt.vector4d(0, 0, 0, 0)
    property vector4d levels4: Qt.vector4d(0, 0, 0, 0)
    property vector4d levels5: Qt.vector4d(0, 0, 0, 0)
    property vector4d levels6: Qt.vector4d(0, 0, 0, 0)
    property vector4d levels7: Qt.vector4d(0, 0, 0, 0)
    property vector4d levels8: Qt.vector4d(0, 0, 0, 0)
    property vector4d levels9: Qt.vector4d(0, 0, 0, 0)
    property vector4d levels10: Qt.vector4d(0, 0, 0, 0)
    property vector4d levels11: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle0: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle1: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle2: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle3: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle4: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle5: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle6: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle7: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle8: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle9: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle10: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle11: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle12: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle13: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle14: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle15: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle16: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle17: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle18: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle19: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle20: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle21: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle22: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle23: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle24: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle25: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle26: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle27: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle28: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle29: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle30: Qt.vector4d(0, 0, 0, 0)
    property vector4d particle31: Qt.vector4d(0, 0, 0, 0)
    fragmentShader: Qt.resolvedUrl("../shaders/viz_orbit.frag.qsb")
    onVisibleChanged: upload()
    function upload() {
        uploadLevels();
        uploadParticles();
    }
    function uploadLevels() {
        if (!visible)
            return;
        const values = orbit.values();
        for (let i = 0; i < 12; i++) {
            const j = i * 4;
            effect["levels" + i] = Qt.vector4d(values[j] || 0, values[j + 1] || 0, values[j + 2] || 0, values[j + 3] || 0);
        }
    }
    function uploadParticles() {
        if (!visible)
            return;
        for (let i = 0; i < particleCount; i++) {
            const p = orbit.particles[i];
            effect["particle" + i] = Qt.vector4d(Math.cos(p.a) * p.r, Math.sin(p.a) * p.r, p.s, p.life);
        }
    }
    Connections {
        target: effect.orbit
        function onBarsChanged() {
            if (effect.orbit.drawing)
                effect.uploadLevels();
        }
        function onParticlesChanged() {
            effect.uploadParticles();
        }
        function onDrawingChanged() {
            effect.uploadLevels();
        }
        function onMaxRangeChanged() {
            effect.uploadLevels();
        }
        function onHalfChanged() {
            effect.uploadLevels();
        }
    }
    Component.onCompleted: upload()
}
