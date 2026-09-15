import QtQuick

// Progress style 10: a conic ring around the cover (HTML `.artwrap .rg`).
// The owner places it 4 px outside the artwork; the band is 2 px wide.
Item {
    id: ring
    property var player: null
    property bool isPlaying: false
    property bool playbackActive: true
    property string track: ""
    property real positionUnitsPerSecond: 0
    property real visualFrameTime: 0
    property color accentColor: "#ffffff"
    property real cornerRadius: 14
    property real band: 2
    readonly property real progress: clock.progress

    onVisualFrameTimeChanged: {
        if (clock.active && ring.isPlaying)
            clock.tick();
    }

    PlaybackClock {
        id: clock
        objectName: "ringClock"
        unitScale: ring.positionUnitsPerSecond
        updateInterval: 1000
        player: ring.player
        playing: ring.isPlaying
        track: ring.track
        active: ring.visible && ring.width > 0 && ring.height > 0 && ring.playbackActive
    }

    Canvas {
        id: ringCanvas
        objectName: "ringCanvas"
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative
        // Half a degree of sweep is below a pixel on the ring; skip smaller ticks.
        readonly property int sweepStep: ring.visible ? Math.round(ring.progress * 720) : 0

        function repaint() {
            if (ring.visible)
                requestPaint();
        }
        onSweepStepChanged: repaint()
        onWidthChanged: repaint()
        onHeightChanged: repaint()
        onVisibleChanged: repaint()
        Connections {
            target: ring
            function onAccentColorChanged() {
                ringCanvas.repaint();
            }
            function onCornerRadiusChanged() {
                ringCanvas.repaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width, h = height;
            const band = ring.band;
            if (w <= band * 2 || h <= band * 2)
                return;
            const r = Math.min(ring.cornerRadius, w / 2, h / 2);
            const inner = Math.max(0, r - band);
            const start = -Math.PI / 2;
            const end = start + sweepStep / 720 * Math.PI * 2;
            const reach = w + h;
            ctx.fillRule = Qt.OddEvenFill;

            function wedge(from, to, color) {
                if (to <= from)
                    return;
                ctx.save();
                ctx.beginPath();
                ctx.moveTo(w / 2, h / 2);
                ctx.arc(w / 2, h / 2, reach, from, to, false);
                ctx.closePath();
                ctx.clip();
                ctx.beginPath();
                ctx.roundedRect(0, 0, w, h, r, r);
                ctx.roundedRect(band, band, w - band * 2, h - band * 2, inner, inner);
                ctx.fillStyle = color;
                ctx.fill();
                ctx.restore();
            }
            wedge(start, end, ring.accentColor);
            wedge(end, start + Math.PI * 2, Qt.rgba(1, 1, 1, 0x26 / 255));
        }
    }
}
