import QtQuick 2.15
import QtQuick.Effects
import "../code/WaveMath.js" as WaveMath
import "../code/WaveDraw.js" as WaveDraw
import "../code/ClassicWaveDraw.js" as ClassicWaveDraw

Canvas {
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
    property real visualFrameTime: 0
    property real bass: 0
    property real mid: 0
    property real high: 0
    property real beatPulse: 0
    property var stereoSamples: []
    property var previousStereo: []
    property real energy: 1
    property bool reducedMotion: false
    property string vizDirection: "up"
    property string vizColorMode: "solid"
    property string vizPalette: "aurora"
    property bool hueReactive: false
    property real bloom: 1
    property real ribbonCurvature: 1
    property real ribbonFullness: 1
    property color coverColor1: "#b4befe"
    property color coverColor2: "#b4befe"
    property var peaks: []
    property var particles: []
    property var ripples: []
    property bool edgeFade: false
    readonly property var colorStops: WaveMath.colorStops(waveColor, vizColorMode, vizPalette, coverColor1, coverColor2, hueReactive, hueReactive && !reducedMotion ? high : .5, !reducedMotion && (hueReactive || vizColorMode === "rainbow") ? visualFrameTime / 1000 : 0, reducedMotion)
    readonly property bool _colored: vizColorMode !== "solid" || hueReactive
    readonly property color _mainColor: _colored ? colorStops[0] : waveColor
    readonly property int _sampleCount: WaveMath.count(numBars, width, visualizerType)

    antialiasing: true
    renderStrategy: Canvas.Cooperative
    // Flip the finished texture to preserve its antialiasing.
    transform: Scale {
        origin.y: wave.height / 2
        yScale: wave.vizDirection === "down" && (wave.visualizerType === 1 || wave.visualizerType === 6 || wave.visualizerType === 7 || wave.visualizerType === 8) ? -1 : 1
    }

    // Match the system monitor's chart pipeline: rasterize the geometry once,
    // then blur its combined texture on the GPU. Canvas shadowBlur performs a
    // separate CPU image blur for every stroke, bar and dot in every frame.
    // Qt's software scene graph cannot render MultiEffect; keep the waveform
    // visible there without falling back to those expensive CPU shadows.
    layer.enabled: visualizerType < 6 && glowWave && bloom > 0 && hasAudio && !backendFailed && GraphicsInfo.api !== GraphicsInfo.Software
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: wave._mainColor
        shadowOpacity: 1.0
        shadowBlur: 1.0
        blurMax: 8 * Math.max(0, Math.min(2, wave.bloom))
        autoPaddingEnabled: false
    }

    // A palette change, not an audio frame, creates these colors. In the dot
    // styles this avoids hundreds of QColor conversions per second.
    readonly property color _idleColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.35)
    property var _drawCache: ({})

    function repaint() {
        if (visible)
            requestPaint();
    }

    function invalidateGradients() {
        _drawCache.fillAbove = null;
        _drawCache.fillBelow = null;
        repaint();
    }

    onBarsChanged: {
        if (hasAudio && !backendFailed)
            repaint();
    }
    onHasAudioChanged: repaint()
    onBackendFailedChanged: repaint()
    onWaveColorChanged: invalidateGradients()
    onTextColorChanged: {
        if (!hasAudio)
            repaint();
    }
    onNumBarsChanged: repaint()
    onMaxRangeChanged: repaint()
    onLineWidthChanged: repaint()
    onFillWaveChanged: repaint()
    onGlowWaveChanged: repaint()
    onVisualizerTypeChanged: repaint()
    onVisibleChanged: repaint()
    onWidthChanged: repaint()
    onHeightChanged: invalidateGradients()
    onAvailableChanged: invalidateGradients()
    onColorStopsChanged: invalidateGradients()
    onVizColorModeChanged: repaint()
    onBloomChanged: repaint()
    onRibbonCurvatureChanged: repaint()
    onRibbonFullnessChanged: repaint()
    onReducedMotionChanged: repaint()
    onBassChanged: {
        if (hasAudio && !backendFailed && (visualizerType === 11 || visualizerType === 13 || visualizerType >= 15))
            repaint();
    }
    onMidChanged: {
        if (hasAudio && !backendFailed && visualizerType >= 15 && !reducedMotion)
            repaint();
    }
    onHighChanged: {
        if (hasAudio && !backendFailed && visualizerType >= 15)
            repaint();
    }
    onEnergyChanged: {
        if (hasAudio && !backendFailed && (visualizerType === 11 || visualizerType === 13 || visualizerType >= 15))
            repaint();
    }
    onVisualFrameTimeChanged: {
        if (hasAudio && !backendFailed && !reducedMotion && (visualizerType === 9 || visualizerType === 10 || visualizerType === 11 || visualizerType === 13 || visualizerType >= 15))
            repaint();
    }
    onPeaksChanged: {
        if (hasAudio && !backendFailed && visualizerType === 6)
            repaint();
    }
    onParticlesChanged: {
        if (hasAudio && !backendFailed && (visualizerType === 14 || visualizerType === 21))
            repaint();
    }
    onRipplesChanged: {
        if (hasAudio && !backendFailed && visualizerType >= 15)
            repaint();
    }

    onEdgeFadeChanged: repaint()
    onBeatPulseChanged: repaint()
    onStereoSamplesChanged: repaint()
    onPreviousStereoChanged: repaint()

    onPaint: {
        const ctx = getContext("2d");
        paintFrame(ctx);
        // Poster texture: fade both sides like the HTML's CSS mask.
        if (edgeFade) {
            ctx.save();
            ctx.globalCompositeOperation = "destination-in";
            const fade = ctx.createLinearGradient(0, 0, width, 0);
            fade.addColorStop(0, Qt.rgba(0, 0, 0, 0));
            fade.addColorStop(0.14, Qt.rgba(0, 0, 0, 1));
            fade.addColorStop(0.86, Qt.rgba(0, 0, 0, 1));
            fade.addColorStop(1, Qt.rgba(0, 0, 0, 0));
            ctx.fillStyle = fade;
            ctx.fillRect(0, 0, width, height);
            ctx.restore();
        }
    }

    function paintFrame(ctx) {
        ctx.reset();
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        const mid = height / 2;
        const n = _sampleCount;
        const vtype = visualizerType;

        // Backend down: the label above carries the explanation,
        // so leave the canvas empty instead of striping the text
        // with the idle line.
        if (backendFailed)
            return;

        // ── Idle line (all visualizer types) ──────────────────
        if (!hasAudio) {
            ctx.lineWidth = 1.2;
            ctx.strokeStyle = _idleColor;
            ctx.beginPath();
            ctx.moveTo(2, mid);
            ctx.lineTo(width - 2, mid);
            ctx.stroke();
            return;
        }

        if (vtype >= 6) {
            WaveDraw.draw(ctx, {
                width: width,
                height: height,
                type: vtype,
                lineWidth: lineWidth,
                levels: WaveMath.levels(bars, n, maxRange),
                stops: colorStops,
                colorMode: vizColorMode,
                hueShifted: hueReactive && !reducedMotion && (Math.sin(visualFrameTime / 1000 * .15) * 20 + (high - .5) * 14) !== 0,
                time: visualFrameTime / 1000,
                reducedMotion: reducedMotion,
                bass: bass,
                mid: wave.mid,
                high: high,
                energy: energy,
                beatPulse: reducedMotion ? 0 : beatPulse,
                stereoSamples: stereoSamples,
                previousStereo: previousStereo,
                fill: fillWave,
                glow: glowWave,
                bloom: bloom,
                curvature: ribbonCurvature,
                fullness: ribbonFullness,
                peaks: peaks,
                particles: particles,
                ripples: ripples
            });
            return;
        }
        ClassicWaveDraw.draw(ctx, {
            width: width,
            height: height,
            type: vtype,
            lineWidth: lineWidth,
            levels: WaveMath.levels(bars, n, maxRange, _drawCache),
            stops: colorStops,
            colored: _colored,
            fill: fillWave
        }, _drawCache);
    }
}
