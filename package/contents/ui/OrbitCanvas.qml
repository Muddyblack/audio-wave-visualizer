import QtQuick
import "../code/WaveMath.js" as WaveMath
import "../code/OrbitDraw.js" as OrbitDraw
import "../code/OrbitMotion.js" as OrbitMotion

// Orbit layout ring: the visualizer drawn in polar coordinates around the
// cover. Decorative motion (rotation, ribbon wobble, sparks) rides audio
// frames; sparks are capped at 32 and advance once per audio timestamp.
Item {
    id: orbit
    property bool shaderEnabled: false

    property var bars: []
    property real maxRange: 1000
    property int numBars: 24
    property bool hasAudio: false
    property bool backendFailed: false
    property real visualFrameTime: 0
    property real high: 0
    property color waveColor: "#ffffff"
    property color coverColor1: waveColor
    property color coverColor2: waveColor
    property string vizColorMode: "solid"
    property string vizPalette: "aurora"
    property bool hueReactive: false
    property real lineWidth: 1.8
    property bool fillWave: false
    property bool glowWave: true
    property real bloom: 1
    property bool reducedMotion: false
    property string orbitStyle: "bars"
    property real orbitReach: 1
    property bool orbitRotate: true
    // (cover + ring allowance) / box, as the HTML's data-r.
    property real coverRatio: 0.38
    property var particles: []
    property real _lastFrame: -1
    property int _seed: 1

    readonly property int half: Math.max(12, Math.min(48, numBars))
    readonly property real seconds: visualFrameTime / 1000
    readonly property real ringRotation: orbitRotate && !reducedMotion ? (seconds * 0.2) % (Math.PI * 2) : 0
    readonly property bool sparks: orbitStyle === "sparks" && !reducedMotion
    readonly property bool drawing: visible && hasAudio && !backendFailed
    readonly property var colorStops: WaveMath.colorStops(waveColor, vizColorMode, vizPalette, coverColor1, coverColor2, hueReactive, hueReactive && !reducedMotion ? high : 0.5, !reducedMotion && (hueReactive || vizColorMode === "rainbow") ? seconds : 0, reducedMotion)

    function values() {
        return OrbitMotion.values(orbit);
    }
    function geometry() {
        return OrbitMotion.geometry(orbit);
    }
    function advance() {
        OrbitMotion.advance(orbit);
    }

    function repaint() {
        if (visible && painter.item)
            painter.item.requestPaint();
    }

    onVisualFrameTimeChanged: {
        advance();
        if (drawing && (ringRotation !== 0 || orbitStyle === "ribbon" || sparks))
            repaint();
    }
    onBarsChanged: {
        if (drawing)
            repaint();
    }
    onSparksChanged: advance()
    onDrawingChanged: {
        advance();
        repaint();
    }
    onParticlesChanged: repaint()
    onMaxRangeChanged: repaint()
    onHalfChanged: repaint()
    onWidthChanged: repaint()
    onHeightChanged: repaint()
    onOrbitStyleChanged: repaint()
    onOrbitReachChanged: repaint()
    onCoverRatioChanged: repaint()
    onColorStopsChanged: repaint()
    onLineWidthChanged: repaint()
    onFillWaveChanged: repaint()
    onGlowWaveChanged: repaint()
    onBloomChanged: repaint()

    Loader {
        id: painter
        anchors.fill: parent
        active: !orbit.shaderEnabled
        sourceComponent: Canvas {
            antialiasing: true
            renderStrategy: Canvas.Cooperative
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                if (orbit.backendFailed)
                    return;
                const g = orbit.geometry();
                OrbitDraw.draw(ctx, {
                    width: width,
                    height: height,
                    R: g.inner,
                    reach: g.reach,
                    style: orbit.orbitStyle,
                    values: orbit.values(),
                    rot: orbit.ringRotation,
                    t: orbit.reducedMotion ? 0 : orbit.seconds,
                    stops: orbit.colorStops,
                    lineWidth: orbit.lineWidth,
                    fill: orbit.fillWave,
                    glow: orbit.glowWave ? Math.max(0, Math.min(2, orbit.bloom)) : 0,
                    particles: orbit.particles
                });
            }
        }
    }
}
