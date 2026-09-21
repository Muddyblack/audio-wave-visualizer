pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "../code/ColourStyle.js" as ColourStyle
import "../code/ProgressDraw.js" as ProgressDraw

Item {
    id: root
    property var player: null
    property bool isPlaying: false
    property bool hasAudio: false
    property bool playbackActive: true
    property string customProgressBar: ""
    readonly property bool customReady: custom.ready
    readonly property string customError: custom.error
    property int style: 0
    property string track: ""
    property string artist: ""
    property color textColor: "#ffffff"
    property color waveColor: "#ffffff"
    property color controlColor: "#ffffff"
    property var colorStops: []
    function colorAt(position) {
        return ColourStyle.sample(colorStops.length ? colorStops : [waveColor], position);
    }
    onColorStopsChanged: {
        if (waveformSeek.visible)
            waveformSeek.requestPaint();
        if (lineSeek.visible)
            lineSeek.requestPaint();
    }
    property color pgStartColor: "#ffffff"
    property color pgEndColor: "#ffffff"
    property real positionUnitsPerSecond: 0
    property var peaks: []
    property var chapters: []
    property real wheelSeekSeconds: 5
    property bool seekHover: true
    property bool seekGestures: true
    property bool reactiveProgress: true
    property real bass: 0
    property real energyPulse: 0
    readonly property real transientPulse: reactiveProgress && !reducedMotion && hasAudio && playbackActive ? Math.max(0, Math.min(1, energyPulse + bass * .25)) : 0
    property real visualFrameTime: 0
    property bool reducedMotion: false
    property bool showTimes: true
    property string timeFormat: "total"
    property bool centerTimes: false
    // Layouts hide the bar while another element (the cover ring) shows progress.
    property bool suppressed: false
    // Heights follow the HTML `.pb` variants, with and without time labels.
    implicitHeight: customReady ? Math.max(9, Math.min(28, custom.preferredHeight || 18)) : style === 9 ? 12 : style === 4 ? (showTimes ? 28 : 19) : style === 5 || style === 7 ? (showTimes ? 18 : 11) : (showTimes ? 18 : 9)
    readonly property string elapsedText: positionClock.elapsedText
    readonly property string totalLabel: timeFormat === "remaining" ? positionClock.remainingText : positionClock.totalText

    // Audio frames advance playback; the clock retains its slow silent fallback.
    onVisualFrameTimeChanged: {
        if (positionClock.active && root.isPlaying)
            positionClock.tick();
    }

    // Visible only if we have a player and a valid track length
    visible: !root.suppressed && !!root.player && lengthValue > 0
    opacity: visible ? 1.0 : 0.0

    readonly property int pbStyle: root.style === 10 ? 0 : root.style

    readonly property real lengthValue: positionClock.lengthValue
    readonly property real progress: pbArea.scrubbing ? pbArea.fraction : positionClock.progress
    readonly property int progressPixel: Math.round(root.progress * progressTrack.width)
    readonly property bool animateDecorations: root.isPlaying && root.hasAudio && positionClock.active
    readonly property real sweep: {
        if (!animateDecorations)
            return -0.35;
        const phase = Math.min(1, (root.visualFrameTime % 1730) / 1450);
        return -0.35 + 1.7 * (0.5 - 0.5 * Math.cos(Math.PI * phase));
    }

    CustomProgressBar {
        id: custom
        anchors.fill: parent
        sourceUrl: root.customProgressBar
        progressView: root
        playbackClock: positionClock
    }

    PlaybackClock {
        id: positionClock
        objectName: "positionClock"
        unitScale: root.positionUnitsPerSecond
        // Audio frames tick the clock while the waveform moves.
        // A slow fallback keeps silent playback/time labels correct.
        updateInterval: positionClock.loopEnabled && positionClock.validLoop ? 50 : 1000
        player: root.player
        playing: root.isPlaying
        track: root.track
        active: root.visible && root.width > 0 && root.height > 0 && root.playbackActive
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 180
        }
    }

    // ── Style 4 — Android Waveform seekbar ───────────────────
    Canvas {
        id: waveformSeek
        objectName: "waveformSeek"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 1
        height: 18
        visible: !root.customReady && (root.pbStyle === 4)
        antialiasing: true
        renderStrategy: Canvas.Cooperative

        // Seeded decorative waveform heights, unique per track.
        property var barHeights: []
        property int numBars: 0
        property string waveformKey: ""

        function buildWaveform() {
            const w = width;
            if (!visible || w <= 0)
                return;
            const gap = 2;
            const barW = 3;
            const n = Math.floor(w / (barW + gap));
            const key = root.track + "\u0000" + root.artist;
            if (n === numBars && barHeights.length === n && waveformKey === key)
                return;
            numBars = n;
            waveformKey = key;
            barHeights = ProgressDraw.seedHeights(root.track + root.artist, n);
            requestPaint();
        }

        Component.onCompleted: buildWaveform()
        onWidthChanged: buildWaveform()
        onHeightChanged: {
            if (visible)
                requestPaint();
        }
        onVisibleChanged: {
            if (visible) {
                buildWaveform();
                requestPaint();
            }
        }
        Connections {
            target: root
            function onTrackChanged() {
                waveformSeek.buildWaveform();
            }
            function onArtistChanged() {
                waveformSeek.buildWaveform();
            }
            function onWaveColorChanged() {
                if (waveformSeek.visible)
                    waveformSeek.requestPaint();
            }
            function onTextColorChanged() {
                if (waveformSeek.visible)
                    waveformSeek.requestPaint();
            }
            function onControlColorChanged() {
                if (waveformSeek.visible)
                    waveformSeek.requestPaint();
            }
        }
        // Repaint when the playhead reaches a new pixel, not on
        // every 50 ms position tick: bars only change colour as
        // the playhead passes them, and on a three-minute track
        // it moves under 2 px a second.
        readonly property int playheadPx: visible ? Math.round(root.progress * width) : 0
        readonly property bool showPlayhead: visible && root.progress > 0 && root.progress < 1
        onPlayheadPxChanged: {
            if (visible)
                requestPaint();
        }
        onShowPlayheadChanged: {
            if (visible)
                requestPaint();
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ProgressDraw.draw(ctx, {
                width: width,
                height: height,
                style: 4,
                playhead: playheadPx,
                heights: barHeights,
                showPlayhead: showPlayhead,
                waveColor: root.waveColor,
                textColor: root.textColor,
                controlColor: root.controlColor,
                stops: root.colorStops
            });
        }
    }

    // ── Styles 5 (Squiggle) and 7 (Dotted) ──
    Canvas {
        id: lineSeek
        objectName: "lineSeek"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 10
        visible: !root.customReady && (root.pbStyle === 5 || root.pbStyle === 7)
        antialiasing: true
        renderStrategy: Canvas.Cooperative

        // The HTML eases the amplitude each frame; a one-shot transition on
        // play/pause gives the same settle without a permanent animation loop.
        property real amplitude: root.pbStyle === 5 && root.isPlaying && !root.reducedMotion ? 2.2 : 0
        Behavior on amplitude {
            NumberAnimation {
                duration: 450
                easing.type: Easing.OutQuad
            }
        }
        // The wave phase rides audio frames, and only while it is visible.
        readonly property real phase: visible && root.pbStyle === 5 && amplitude > 0 ? root.visualFrameTime / 1000 : 0
        readonly property int playheadPx: visible ? Math.round(root.progress * width) : 0

        function repaint() {
            if (visible)
                requestPaint();
        }
        onAmplitudeChanged: repaint()
        onPhaseChanged: repaint()
        onPlayheadPxChanged: repaint()
        onWidthChanged: repaint()
        onVisibleChanged: repaint()
        Connections {
            target: root
            function onStyleChanged() {
                lineSeek.repaint();
            }
            function onWaveColorChanged() {
                lineSeek.repaint();
            }
            function onTextColorChanged() {
                lineSeek.repaint();
            }
            function onControlColorChanged() {
                lineSeek.repaint();
            }
            function onPgStartColorChanged() {
                lineSeek.repaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ProgressDraw.draw(ctx, {
                width: width,
                height: height,
                style: root.pbStyle,
                playhead: playheadPx,
                amplitude: amplitude,
                time: phase,
                startColor: root.pgStartColor,
                waveColor: root.waveColor,
                textColor: root.textColor,
                controlColor: root.controlColor,
                stops: root.colorStops
            });
        }
    }

    Rectangle {
        id: progressTrack
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: root.pbStyle === 1 ? 4 : root.pbStyle === 8 ? 3 : 2
        visible: !root.customReady && root.pbStyle !== 4 && root.pbStyle !== 5 && root.pbStyle !== 7 && root.pbStyle !== 9
        height: root.transientPulse * 2 + (root.pbStyle === 1 ? 1 : root.pbStyle === 2 || root.pbStyle === 6 ? (pbArea.containsMouse ? (root.pbStyle === 6 ? 5 : 6) : 4) : root.pbStyle === 3 ? (pbArea.containsMouse ? 8 : 6) : root.pbStyle === 8 ? (pbArea.containsMouse ? 6 : 5) : (pbArea.containsMouse ? 5 : 3))
        radius: height / 2
        color: root.pbStyle === 6 ? "transparent" : root.pbStyle === 1 ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.06) : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12)
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: root.pbStyle === 1 || root.pbStyle === 6 ? 0 : 1

        Behavior on height {
            NumberAnimation {
                duration: 150
            }
        }

        // Style 6 — Segmented: 7 px segments, 2 px gaps; the track's rounded
        // ends clip its first and last segment as the HTML background does.
        readonly property int segmentCount: Math.ceil(width / 9)
        Repeater {
            model: root.pbStyle === 6 ? progressTrack.segmentCount : 0
            Rectangle {
                required property int index
                readonly property real segmentEnd: Math.min(progressTrack.width, index * 9 + 7)
                x: index * 9
                width: Math.max(0, segmentEnd - x)
                height: progressTrack.height
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.18)
                topLeftRadius: index === 0 ? progressTrack.radius : 0
                bottomLeftRadius: topLeftRadius
                topRightRadius: segmentEnd >= progressTrack.width ? progressTrack.radius : 0
                bottomRightRadius: topRightRadius
            }
        }

        Item {
            id: progressFillClip
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            // A subpixel playhead change does not need a new frame.
            width: root.progressPixel
            clip: true
            // Style 0,2,3 — gradient fill
            Rectangle {
                anchors.fill: parent
                radius: progressTrack.radius
                visible: !root.colorStops.length && root.pbStyle !== 1 && root.pbStyle !== 6 && root.pbStyle !== 8
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(root.pgStartColor.r, root.pgStartColor.g, root.pgStartColor.b, 0.62)
                    }
                    GradientStop {
                        position: 0.65
                        color: Qt.rgba(root.pgStartColor.r, root.pgStartColor.g, root.pgStartColor.b, 0.95)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(root.pgEndColor.r, root.pgEndColor.g, root.pgEndColor.b, 0.82)
                    }
                }
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: root.pgStartColor
                    shadowOpacity: root.pbStyle === 2 ? (root.isPlaying ? 0.65 : 0.35) : (root.isPlaying ? 0.38 : 0.18)
                    shadowBlur: root.pbStyle === 2 ? 0.45 : 0.28
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: progressTrack.radius
                visible: root.colorStops.length > 0 && root.pbStyle !== 6
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: root.colorAt(0)
                    }
                    GradientStop {
                        position: 0.2
                        color: root.colorAt(0.2)
                    }
                    GradientStop {
                        position: 0.4
                        color: root.colorAt(0.4)
                    }
                    GradientStop {
                        position: 0.6
                        color: root.colorAt(0.6)
                    }
                    GradientStop {
                        position: 0.8
                        color: root.colorAt(0.8)
                    }
                    GradientStop {
                        position: 1
                        color: root.colorAt(1)
                    }
                }
            }

            // Style 1 — flat solid fill (Ultra Minimal)
            Rectangle {
                anchors.fill: parent
                radius: progressTrack.radius
                visible: !root.colorStops.length && root.pbStyle === 1
                color: Qt.rgba(root.pgStartColor.r, root.pgStartColor.g, root.pgStartColor.b, 0.75)
            }

            // Style 8 — Capsule: solid fill without glow.
            Rectangle {
                anchors.fill: parent
                radius: progressTrack.radius
                visible: !root.colorStops.length && root.pbStyle === 8
                color: root.pgStartColor
            }

            // Style 6 — Segmented fill, square-ended like the HTML fill.
            Repeater {
                model: root.pbStyle === 6 ? progressTrack.segmentCount : 0
                Rectangle {
                    required property int index
                    x: index * 9
                    width: 7
                    height: progressTrack.height
                    color: root.colorStops.length ? root.colorAt(x / Math.max(1, root.progressPixel)) : root.pgStartColor
                }
            }

            Rectangle {
                width: Math.max(18, progressTrack.width * 0.22)
                height: parent.height
                radius: parent.height / 2
                x: (progressFillClip.width + width) * root.sweep - width
                opacity: (root.isPlaying && (root.pbStyle === 0 || root.pbStyle === 2)) ? 0.72 : 0.0
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(root.controlColor.r, root.controlColor.g, root.controlColor.b, 0.0)
                    }
                    GradientStop {
                        position: 0.50
                        color: Qt.rgba(root.controlColor.r, root.controlColor.g, root.controlColor.b, 0.78)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(root.controlColor.r, root.controlColor.g, root.controlColor.b, 0.0)
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                    }
                }
            }
        }

        Rectangle {
            width: root.pbStyle === 2 ? (pbArea.containsMouse ? 10 : 8) : (pbArea.containsMouse ? 8 : 6)
            height: width
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(parent.width - width, root.progressPixel - width / 2))
            color: Qt.rgba(root.controlColor.r, root.controlColor.g, root.controlColor.b, root.isPlaying ? 0.95 : 0.68)
            opacity: ((root.pbStyle === 0 || root.pbStyle === 2) && root.progress > 0) ? 1.0 : 0.0
            layer.enabled: root.pbStyle === 0 || root.pbStyle === 2
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: root.pgStartColor
                shadowOpacity: root.pbStyle === 2 ? (root.isPlaying ? 0.75 : 0.42) : (root.isPlaying ? 0.55 : 0.22)
                shadowBlur: Math.min(1, (root.pbStyle === 2 ? 0.60 : 0.40) + root.transientPulse * .3)
            }

            scale: root.transientPulse * .25 + (root.animateDecorations && (root.pbStyle === 0 || root.pbStyle === 2) ? 1.05 - 0.13 * Math.cos(2 * Math.PI * (root.visualFrameTime % 1400) / 1400) : 1)
        }

        // Style 8 — white capsule knob with a small drop shadow.
        Rectangle {
            objectName: "capsuleKnob"
            visible: !root.colorStops.length && root.pbStyle === 8
            width: 16
            height: 9
            radius: 4.5
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(parent.width - width, root.progressPixel - width / 2))
            color: "#ffffff"
            border.width: 0.5
            border.color: Qt.rgba(0, 0, 0, 0x22 / 255)
            // The software scene graph cannot draw MultiEffect; keep the knob there.
            layer.enabled: visible && GraphicsInfo.api !== GraphicsInfo.Software
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#000000"
                shadowOpacity: 0.4
                shadowBlur: 0.25
                shadowVerticalOffset: 1
            }
        }
    }

    Text {

        renderType: Text.CurveRendering ?? Text.QtRendering
        objectName: "elapsedTimeLabel"
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        visible: !root.customReady && root.showTimes && root.pbStyle !== 9
        text: positionClock.elapsedText
        color: root.textColor
        opacity: 0.50
        font.pixelSize: 8
    }

    Text {

        renderType: Text.CurveRendering ?? Text.QtRendering
        objectName: "totalTimeLabel"
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: !root.customReady && root.showTimes && root.pbStyle !== 9
        text: root.totalLabel
        color: root.textColor
        opacity: 0.50
        font.pixelSize: 8
    }

    // Style 9 — Time only: "1:31 / 3:58", always shown, centred with centred text.
    Row {
        objectName: "timeOnlyRow"
        visible: !root.customReady && (root.pbStyle === 9)
        anchors.top: parent.top
        anchors.left: root.centerTimes ? undefined : parent.left
        anchors.horizontalCenter: root.centerTimes ? parent.horizontalCenter : undefined
        spacing: 4
        opacity: 0.65

        Row {
            Text {
                renderType: Text.CurveRendering ?? Text.QtRendering
                objectName: "timeOnlyElapsed"
                text: positionClock.elapsedText
                color: root.textColor
                font.pixelSize: 9
            }
            Text {
                renderType: Text.CurveRendering ?? Text.QtRendering
                text: " /"
                color: root.textColor
                opacity: 0.6
                font.pixelSize: 9
            }
        }
        Text {
            renderType: Text.CurveRendering ?? Text.QtRendering
            objectName: "timeOnlyTotal"
            text: root.totalLabel
            color: root.textColor
            font.pixelSize: 9
        }
    }

    // Short pulse along the played track, driven entirely by the audio clock.
    Rectangle {
        visible: !root.customReady && root.transientPulse > .02
        x: Math.max(0, root.progressPixel - width)
        y: pbArea.trackCenter - height / 2
        width: Math.min(root.progressPixel, 8 + 22 * root.transientPulse)
        height: 4 + 7 * root.transientPulse
        radius: height / 2
        color: root.waveColor
        opacity: root.transientPulse * .22
    }
    SeekInteraction {
        id: pbArea
        anchors.fill: parent
        visible: !root.customReady
        enabled: !root.customReady
        clock: positionClock
        chapters: root.chapters
        accentColor: root.waveColor
        textColor: root.textColor
        wheelStep: root.wheelSeekSeconds
        hoverTips: root.seekHover
        gestures: root.seekGestures
        reducedMotion: root.reducedMotion
        trackCenter: root.pbStyle === 4 ? 10 : progressTrack.y + progressTrack.height / 2
    }
}
