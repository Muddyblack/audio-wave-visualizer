import QtQuick 2.15
import QtQuick.Controls as QQC
import QtQuick.Layouts 1.1
import QtQuick.Effects

Item {
    id: root

    required property var configuration
    required property var visualizer
    property var player: null
    property bool isPlaying: false
    property color accentColor: "#b4befe"
    property color systemTextColor: "#cdd6f4"
    property string defaultFontFamily: Qt.application.font.family
    property Component fallbackIcon
    // Zero preserves Plasma's historical unit detection; Quickshell uses seconds.
    property real positionUnitsPerSecond: 0
    // Decorative motion shares audio frames; it must not start its own
    // display-refresh animation loop on every monitor.
    readonly property real visualFrameTime: visualizer.frameTimeMs ?? 0
    onVisualFrameTimeChanged: {
        if (positionClock.active && root.isPlaying)
            positionClock.tick();
    }

    readonly property bool shouldShow: hasPlayer || configuration.alwaysVisible
    implicitWidth: configuration.showMpris ? 360 : 200
    implicitHeight: configuration.showMpris ? 104 : 84
    readonly property bool hasPlayer: !!player
    property string artist: player?.artist ?? ""
    property string track: player?.track ?? ""
    property string playerArtUrl: player?.artUrl ?? ""
    readonly property string desktopEntry: player?.desktopEntry ?? ""
    readonly property color textColor: configuration.useSystemText ? systemTextColor : configuration.customTextColor
    readonly property color waveColor: configuration.useSystemAccent ? accentColor : configuration.customColor
    readonly property color controlColor: configuration.useSystemControls ? "#ffffff" : configuration.customControlColor
    readonly property color pgStartColor: configuration.useSystemControls ? accentColor : controlColor
    readonly property color pgEndColor: configuration.useSystemControls ? "#ffffff" : controlColor

    // Well-behaved sources (Spotify, a normal youtube.com tab, tagged local
    // files) publish xesam:title and never reach any of this. What follows is
    // only for the ones that publish nothing: a browser tab pointed straight at a
    // CDN link, mpv on a `yt-dlp -g` URL, a proxy that strips the page. Plasma
    // then falls back to the URL cut at its last slash, and since googlevideo
    // links carry an unencoded "mime=video/mp4" that reaches us as a 300-char
    // query fragment ("mp4&rqh=1&gir=yes&clen=…").
    readonly property string displayTrack: _prettifyTrack(track)
    readonly property bool trackUnknown: hasPlayer && displayTrack === ""
    readonly property string sourceHint: trackUnknown ? _sourceHint(track) : ""

    // A name worth putting on the card, or "" when there is none. Never invents
    // a title — an unusable value becomes the "no metadata" state instead.
    function _prettifyTrack(raw) {
        const s = (raw || "").trim();
        if (s === "")
            return "";

        const urlParts = s.match(/^[a-z][a-z0-9+.-]*:\/\/([^/?#]*)([^?#]*)/i);
        const isPath = !urlParts && s.startsWith("/");
        // Leftover key=value&key=value soup. Real titles don't look like this.
        const isDebris = s.indexOf("&") !== -1 && (s.match(/[a-z0-9_]+=[^&]*/gi) || []).length >= 3;
        if (!urlParts && !isPath && !isDebris)
            return s;
        if (isDebris && !urlParts)
            return "";

        let name = urlParts ? urlParts[2] : s.split("?")[0];
        try {
            name = decodeURIComponent(name);
        } catch (e) {
            // malformed %-escape: keep the raw form
        }
        name = (name.split("/").filter(part => part !== "").pop() || "").replace(/\.[a-z0-9]{1,5}$/i, "").replace(/[_+]+/g, " ").trim();
        // A filename carries information; a generic stream endpoint does not.
        return /^(videoplayback|playback|stream|index|master|manifest|playlist)$/i.test(name) ? "" : name;
    }

    // Shown under "No track metadata" so the card still says where the sound is
    // coming from.
    function _sourceHint(raw) {
        const s = (raw || "").trim();
        const host = (s.match(/^[a-z][a-z0-9+.-]*:\/\/([^/?#]*)/i) || ["", ""])[1].toLowerCase();
        // googlevideo params survive even when the host got chopped off
        if (host.endsWith("googlevideo.com") || /(^|&)(itag|clen|gir|lmt|fvip|ratebypass|sparams)=/i.test(s))
            return "Direct YouTube stream";
        if (host !== "")
            return host.replace(/^www\./, "");
        return "Player published no title";
    }

    property string artUrl: ""

    // When the album art is already shown big as the card background, the small
    // square thumbnail on the left is redundant — hide it so the controls dock
    // gets the room instead. Falls back to showing the thumb if there's no art
    // yet (so art-bg mode without loaded art doesn't look empty).
    readonly property bool artIsBackground: root.configuration.showBg && root.configuration.artBg && artUrl !== ""

    function _refreshArtUrl() {
        const p = root.player;
        if (!p || !root.configuration.showMpris) {
            artUrl = "";
            return;
        }
        const url = root.playerArtUrl;
        if (url !== "")
            artUrl = url;
    }

    onPlayerChanged: {
        artUrl = "";
        _refreshArtUrl();
    }
    onPlayerArtUrlChanged: _refreshArtUrl()
    Component.onCompleted: _refreshArtUrl()

    readonly property bool showMpris: configuration.showMpris
    onShowMprisChanged: _refreshArtUrl()

    Item {
        id: container
        anchors.fill: parent
        visible: root.shouldShow
        // No clip — clipping cuts off text when background card is enabled

        // ── Background card source (rendered offscreen, used by backgroundCardEffect) ──
        // Art image source — must be a sibling, not child of backgroundCard
        Image {
            id: bgArtImg
            anchors.fill: parent
            source: (root.configuration.showMpris && root.configuration.artBg) ? root.artUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: false
        }

        Rectangle {
            id: backgroundCard
            anchors.fill: parent
            visible: false
            radius: root.configuration.bgRadius
            color: "transparent"
            clip: true

            // Crisp art fill — light blur keeps the cover clearly recognizable
            // (premium "bold cover" look) while still softening hard detail so
            // the wave/text read on top. Brighter + saturated vs the old heavy
            // frosted treatment.
            MultiEffect {
                anchors.fill: parent
                source: bgArtImg
                blurEnabled: true
                // User-controlled blur (0 = crisp cover, 1 = heavy frost).
                blur: root.configuration.artBgBlur
                blurMax: 48
                saturation: 0.85
                opacity: (root.configuration.artBg && bgArtImg.status === Image.Ready) ? 1.0 : 0.0
                Behavior on blur {
                    NumberAnimation {
                        duration: 250
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 400
                    }
                }
            }

            // Whether the album art is actually being used as the fill right now.
            property bool artMode: root.configuration.artBg && bgArtImg.status === Image.Ready

            // Solid-colour fill — ONLY when not in art mode (art mode has its
            // own image fill above). Kept as its own rectangle (no gradient on
            // it) so there's never a color↔gradient conflict on a single
            // Rectangle, which was painting the whole card black.
            //
            // While idle (no MPRIS player at all — nothing to show art or a
            // custom colour for) fall back to a soft glass tint instead of the
            // raw configured bgColor, which otherwise defaults to near-black
            // and reads as a dead solid box. This mirrors the dock's default
            // glass look and keeps the idle state looking clean rather than
            // just "off". Once a player appears, the user's configured
            // background (colour or art) takes over as before.
            Rectangle {
                anchors.fill: parent
                visible: !backgroundCard.artMode
                color: root.hasPlayer ? root.configuration.bgColor : Qt.rgba(1, 1, 1, 0.06)
            }

            // NOTE: the art-darkness scrim is intentionally NOT here. backgroundCard
            // is visible:false and used only as a texture source for
            // backgroundCardEffect, so changing a child's opacity inside it does
            // not re-trigger the MultiEffect's texture capture (blur works because
            // it's a live property on the effect pipeline; child opacity does not).
            // The scrim lives in the live scene on top of the effect instead —
            // see `artScrim` below.

            // Border on top
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: root.configuration.bgRadius
                border.color: Qt.rgba(1, 1, 1, 0.12)
                border.width: 1
            }
        }

        MultiEffect {
            id: backgroundCardEffect
            anchors.fill: parent
            source: backgroundCard
            visible: root.configuration.showBg

            // Round the whole composited card (art + tint + border) in one pass.
            maskEnabled: true
            maskSource: cardRoundMask

            // Background card transparency — art + blur fade together as one layer.
            // Wave, text and controls remain fully opaque on top.
            opacity: root.configuration.artBgTransparency
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        // Rounded-rectangle alpha mask for backgroundCardEffect. Rendered to a
        // texture (layer.enabled) so the MultiEffect can sample it; never shown.
        Rectangle {
            id: cardRoundMask
            anchors.fill: parent
            radius: root.configuration.bgRadius
            color: "black"
            visible: false
            layer.enabled: true
        }

        // Art-darkness scrim — LIVE in the scene (not inside the captured
        // backgroundCard source), so its opacity reacts instantly to the slider.
        // A plain Rectangle's own rounded gradient fill stays inside its corners
        // (the earlier corner-leak only affected clipped CHILDREN), so radius +
        // antialiasing is enough here without a separate mask pass.
        Rectangle {
            id: artScrim
            anchors.fill: parent
            antialiasing: true
            radius: root.configuration.bgRadius
            visible: root.configuration.showBg && root.configuration.artBg && bgArtImg.status === Image.Ready
            // 0 = art fully visible · 1 = strongly dimmed for readability.
            // Also inherits the background transparency so it fades with the card.
            opacity: root.configuration.artBgDim * root.configuration.artBgTransparency
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(0, 0, 0, 0.72)
                }
                GradientStop {
                    position: 0.5
                    color: Qt.rgba(0, 0, 0, 0.85)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0, 0, 0, 0.98)
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.configuration.showBg ? 10 : 0
            anchors.rightMargin: root.configuration.showBg ? 10 : 0
            anchors.topMargin: root.configuration.showBg ? 4 : 0
            anchors.bottomMargin: 0
            spacing: root.configuration.showMpris ? 12 : 0

            // ── Album art and controls ────────────────────────────────────────
            ColumnLayout {
                id: artColumn
                spacing: 4
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                visible: root.configuration.showMpris

                // When the thumbnail is hidden (art-bg mode) the dock is the only
                // child and floats dead-centre. This flexible spacer pushes it
                // toward the lower third so it sits over the darker part of the
                // scrim and lines up better with the track text beside it.
                Item {
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1
                    visible: !artBox.visible
                }

                Item {
                    id: artBox
                    // Hidden when the art is already the card background (redundant),
                    // unless the user opts to keep the sharp thumbnail layered over
                    // the blurred/darkened background (artBgKeepThumb).
                    visible: root.configuration.showArtThumb && (!root.artIsBackground || root.configuration.artBgKeepThumb)
                    Layout.fillHeight: true
                    Layout.maximumHeight: 72
                    Layout.preferredWidth: visible ? Math.min(artBox.height, 72) : 0
                    Layout.maximumWidth: 72
                    Layout.alignment: Qt.AlignHCenter
                    width: Math.min(height, 72)

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: Qt.rgba(1, 1, 1, 0.05)
                        border.color: Qt.rgba(1, 1, 1, 0.18)
                        border.width: 1
                    }

                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: root.fallbackIcon
                        width: root.desktopEntry !== "" ? parent.width * 0.72 : parent.width * 0.45
                        height: width
                        opacity: root.desktopEntry !== "" ? 0.70 : 0.35
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }

                    Image {
                        id: artImg
                        anchors.fill: parent
                        source: root.configuration.showMpris ? root.artUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: false
                    }

                    Rectangle {
                        id: artMask
                        anchors.fill: parent
                        radius: 10
                        visible: false
                        layer.enabled: true
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: artImg
                        maskEnabled: true
                        maskSource: artMask
                        opacity: (artImg.status === Image.Ready || artImg.status === Image.Loading) ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 400
                            }
                        }
                    }
                }

                // ── Glassy transport dock ─────────────────────────────────────
                Item {
                    id: controlDock
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 88
                    Layout.preferredHeight: 26
                    visible: root.hasPlayer

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        // Darker, cleaner glass: a deeper translucent base reads as
                        // a single calm surface against busy album art, instead of
                        // the milky look a light tint gives over a bright cover.
                        color: root.configuration.useSystemDockBg ? Qt.rgba(0, 0, 0, 0.28) : root.configuration.customDockBgColor
                        border.color: Qt.rgba(1, 1, 1, 0.16)
                        border.width: 1

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.rgba(0, 0, 0, 0.35)
                            shadowOpacity: 0.35
                            shadowBlur: 0.25
                            shadowVerticalOffset: 1
                        }

                        // Soft top highlight — the glassy sheen catching light.
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            anchors.topMargin: 1
                            height: 1
                            radius: 0.5
                            color: Qt.rgba(1, 1, 1, 0.18)
                        }
                    }

                    RowLayout {
                        id: controlRow
                        anchors.centerIn: parent
                        spacing: 2

                        // Previous Button
                        Item {
                            id: prevBtn
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            scale: prevArea.pressed ? 0.94 : (prevArea.containsMouse ? 1.07 : 1.0)
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 130
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Canvas {
                                id: prevIcon
                                anchors.centerIn: parent
                                width: 12
                                height: 12
                                opacity: prevArea.containsMouse ? 1.0 : 0.78
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.fillStyle = root.controlColor;
                                    ctx.beginPath();
                                    ctx.moveTo(10, 1.5);
                                    ctx.lineTo(1.5, 6);
                                    ctx.lineTo(10, 10.5);
                                    ctx.closePath();
                                    ctx.fill();
                                }
                                Connections {
                                    target: root
                                    function onControlColorChanged() {
                                        prevIcon.requestPaint();
                                    }
                                }
                            }
                            MouseArea {
                                id: prevArea
                                objectName: "prevArea"
                                anchors.fill: parent
                                anchors.margins: -2
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const p = root.player;
                                    if (!p || p.canGoPrevious === false)
                                        return;
                                    if (p.previous)
                                        p.previous();
                                    else if (p.Previous)
                                        p.Previous();
                                }
                            }
                        }

                        // Play/Pause Button
                        Item {
                            id: playBtn
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 22
                            scale: playArea.pressed ? 0.94 : (playArea.containsMouse ? 1.06 : 1.0)
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 130
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Canvas {
                                id: playIcon
                                anchors.centerIn: parent
                                width: 12
                                height: 12
                                opacity: playArea.containsMouse ? 1.0 : 0.86
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.fillStyle = root.controlColor;
                                    if (root.isPlaying) {
                                        // Draw two vertical pause bars
                                        ctx.fillRect(2, 1, 3.5, 10);
                                        ctx.fillRect(6.5, 1, 3.5, 10);
                                    } else {
                                        // Draw play triangle
                                        ctx.beginPath();
                                        ctx.moveTo(2.5, 1);
                                        ctx.lineTo(10.5, 6);
                                        ctx.lineTo(2.5, 11);
                                        ctx.closePath();
                                        ctx.fill();
                                    }
                                }
                                Connections {
                                    target: root
                                    function onIsPlayingChanged() {
                                        playIcon.requestPaint();
                                    }
                                    function onControlColorChanged() {
                                        playIcon.requestPaint();
                                    }
                                }
                            }
                            MouseArea {
                                id: playArea
                                objectName: "playArea"
                                anchors.fill: parent
                                anchors.margins: -2
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const p = root.player;
                                    if (!p || p.canTogglePlaying === false)
                                        return;
                                    if (p.togglePlaying)
                                        p.togglePlaying();
                                    else if (p.playPause)
                                        p.playPause();
                                    else if (p.PlayPause)
                                        p.PlayPause();
                                    else if (root.isPlaying)
                                        (p.pause || p.Pause || function () {})();
                                    else
                                        (p.play || p.Play || function () {})();
                                }
                            }
                        }

                        // Next Button
                        Item {
                            id: nextBtn
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            scale: nextArea.pressed ? 0.94 : (nextArea.containsMouse ? 1.07 : 1.0)
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 130
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Canvas {
                                id: nextIcon
                                anchors.centerIn: parent
                                width: 12
                                height: 12
                                opacity: nextArea.containsMouse ? 1.0 : 0.78
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.fillStyle = root.controlColor;
                                    ctx.beginPath();
                                    ctx.moveTo(2, 1.5);
                                    ctx.lineTo(10.5, 6);
                                    ctx.lineTo(2, 10.5);
                                    ctx.closePath();
                                    ctx.fill();
                                }
                                Connections {
                                    target: root
                                    function onControlColorChanged() {
                                        nextIcon.requestPaint();
                                    }
                                }
                            }
                            MouseArea {
                                id: nextArea
                                objectName: "nextArea"
                                anchors.fill: parent
                                anchors.margins: -2
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const p = root.player;
                                    if (!p || p.canGoNext === false)
                                        return;
                                    if (p.next)
                                        p.next();
                                    else if (p.Next)
                                        p.Next();
                                }
                            }
                        }
                    }
                }

                // Smaller counter-spacer: with the top spacer ~2x this, the dock
                // settles in the lower third rather than hard against the bottom.
                Item {
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1
                    Layout.maximumHeight: 10
                    visible: !artBox.visible
                }
            }

            // ── Waveform + text ───────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Waveform {
                    id: wave
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.maximumHeight: 44
                    bars: root.visualizer.bars
                    numBars: root.visualizer.numBars
                    maxRange: root.visualizer.maxRange
                    hasAudio: root.visualizer.hasAudio
                    backendFailed: root.visualizer.backendFailed
                    waveColor: root.waveColor
                    textColor: root.textColor
                    lineWidth: root.configuration.lineWidth
                    fillWave: root.configuration.fillWave
                    glowWave: root.configuration.glowWave
                    visualizerType: root.configuration.visualizerType

                    // Backend down: say what broke and what to type, instead of
                    // drawing a flat line that looks exactly like silence.
                    Column {
                        anchors.centerIn: parent
                        width: parent.width
                        spacing: 0
                        visible: root.visualizer.backendFailed

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.pixelSize: 10
                            color: root.textColor
                            opacity: 0.8
                            text: root.visualizer.backendMessage
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideMiddle
                            // Monospace only when the line is literally a
                            // command to type.
                            font.family: root.visualizer.backendCode === "no-cava" ? "monospace" : root.defaultFontFamily
                            font.pixelSize: 9
                            color: root.textColor
                            opacity: 0.55
                            text: root.visualizer.backendAction
                            visible: text !== ""
                        }

                        QQC.ToolTip.visible: hoverHandler.hovered
                        QQC.ToolTip.text: root.visualizer.backendMessage + "\n" + root.visualizer.backendHint
                        HoverHandler {
                            id: hoverHandler
                        }
                    }
                }

                // ── Seekable progress pulse ──────────────────────────────────
                Item {
                    id: progressBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: progressBar.pbStyle === 4 ? 28 : 18
                    Layout.topMargin: 1
                    Layout.bottomMargin: 1

                    // Visible only if we have a player and a valid track length
                    visible: root.hasPlayer && lengthValue > 0
                    opacity: visible ? 1.0 : 0.0

                    readonly property int pbStyle: root.configuration.progressBarStyle ?? 0

                    readonly property real lengthValue: positionClock.lengthValue
                    readonly property real progress: positionClock.progress
                    readonly property int progressPixel: Math.round(positionClock.progress * progressTrack.width)
                    readonly property bool animateDecorations: root.isPlaying && root.visualizer.hasAudio && positionClock.active
                    readonly property real sweep: {
                        if (!animateDecorations)
                            return -0.35;
                        const phase = Math.min(1, (root.visualFrameTime % 1730) / 1450);
                        return -0.35 + 1.7 * (0.5 - 0.5 * Math.cos(Math.PI * phase));
                    }

                    PlaybackClock {
                        id: positionClock
                        objectName: "positionClock"
                        unitScale: root.positionUnitsPerSecond
                        // Audio frames tick the clock while the waveform moves.
                        // A slow fallback keeps silent playback/time labels correct.
                        updateInterval: 1000
                        player: root.player
                        playing: root.isPlaying
                        track: root.track
                        active: progressBar.visible && progressBar.width > 0 && progressBar.height > 0 && root.visualizer.plasmoidVisible
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 180
                        }
                    }

                    // ── Style 4 — Android Waveform seekbar ───────────────────
                    Canvas {
                        id: waveformSeek
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        height: parent.height - 10
                        visible: progressBar.pbStyle === 4
                        antialiasing: true
                        renderStrategy: Canvas.Cooperative

                        // seeded pseudo-random waveform heights, unique per track
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
                            // hash track title for a stable seed
                            let seed = 0;
                            const s = root.track + root.artist;
                            for (let c = 0; c < s.length; c++)
                                seed = (seed * 31 + s.charCodeAt(c)) >>> 0;
                            const heights = [];
                            for (let i = 0; i < n; i++) {
                                seed = (seed * 1664525 + 1013904223) >>> 0;
                                const r = (seed >>> 16) / 65535;
                                // shape: taper at edges, random in middle
                                const pos = n > 1 ? i / (n - 1) : 0;
                                const taper = Math.sin(pos * Math.PI);
                                heights.push(0.15 + r * 0.85 * taper);
                            }
                            barHeights = heights;
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
                        readonly property int playheadPx: visible ? Math.round(progressBar.progress * width) : 0
                        readonly property bool showPlayhead: visible && progressBar.progress > 0 && progressBar.progress < 1
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
                            if (barHeights.length === 0)
                                return;
                            const gap = 2;
                            const barW = 3;
                            const n = barHeights.length;
                            const h = height;
                            const playheadX = playheadPx;
                            const playedColor = Qt.rgba(root.waveColor.r, root.waveColor.g, root.waveColor.b, 0.90);
                            const unplayedColor = Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.25);

                            for (let i = 0; i < n; i++) {
                                const x = i * (barW + gap);
                                const played = (x + barW / 2) < playheadX;
                                const bh = played ? Math.max(2, barHeights[i] * h) : Math.max(2, barHeights[i] * h * 0.45);
                                const y = (h - bh) / 2;

                                ctx.fillStyle = played ? playedColor : unplayedColor;

                                const r = barW / 2;
                                ctx.beginPath();
                                if (bh > r * 2) {
                                    ctx.moveTo(x + r, y);
                                    ctx.arc(x + r, y + r, r, Math.PI, 0);
                                    ctx.lineTo(x + barW, y + bh - r);
                                    ctx.arc(x + r, y + bh - r, r, 0, Math.PI);
                                    ctx.closePath();
                                } else {
                                    ctx.arc(x + r, y + bh / 2, r, 0, Math.PI * 2);
                                }
                                ctx.fill();
                            }

                            // playhead line
                            if (showPlayhead) {
                                ctx.fillStyle = Qt.rgba(root.controlColor.r, root.controlColor.g, root.controlColor.b, 0.95);
                                const phX = playheadX - 1;
                                ctx.fillRect(phX, 0, 2, h);
                            }
                        }
                    }

                    Rectangle {
                        id: progressTrack
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: progressBar.pbStyle === 1 ? 4 : 2
                        visible: progressBar.pbStyle !== 4
                        height: progressBar.pbStyle === 1 ? 1 : progressBar.pbStyle === 2 ? (pbArea.containsMouse ? 6 : 4) : progressBar.pbStyle === 3 ? (pbArea.containsMouse ? 8 : 6) : (pbArea.containsMouse ? 5 : 3)
                        radius: height / 2
                        color: progressBar.pbStyle === 1 ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.06) : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12)
                        border.color: Qt.rgba(1, 1, 1, 0.10)
                        border.width: progressBar.pbStyle === 1 ? 0 : 1

                        Behavior on height {
                            NumberAnimation {
                                duration: 150
                            }
                        }

                        Item {
                            id: progressFillClip
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            // A subpixel playhead change does not need a new frame.
                            width: progressBar.progressPixel
                            clip: true
                            // Style 0,2,3 — gradient fill
                            Rectangle {
                                anchors.fill: parent
                                radius: progressTrack.radius
                                visible: progressBar.pbStyle !== 1
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
                                    shadowOpacity: progressBar.pbStyle === 2 ? (root.isPlaying ? 0.65 : 0.35) : (root.isPlaying ? 0.38 : 0.18)
                                    shadowBlur: progressBar.pbStyle === 2 ? 0.45 : 0.28
                                }
                            }

                            // Style 1 — flat solid fill (Ultra Minimal)
                            Rectangle {
                                anchors.fill: parent
                                radius: progressTrack.radius
                                visible: progressBar.pbStyle === 1
                                color: Qt.rgba(root.pgStartColor.r, root.pgStartColor.g, root.pgStartColor.b, 0.75)
                            }

                            Rectangle {
                                width: Math.max(18, progressTrack.width * 0.22)
                                height: parent.height
                                radius: parent.height / 2
                                x: (progressFillClip.width + width) * progressBar.sweep - width
                                opacity: (root.isPlaying && progressBar.pbStyle !== 1 && progressBar.pbStyle !== 3) ? 0.72 : 0.0
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
                            width: progressBar.pbStyle === 2 ? (pbArea.containsMouse ? 10 : 8) : (pbArea.containsMouse ? 8 : 6)
                            height: width
                            radius: width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, progressBar.progressPixel - width / 2))
                            color: Qt.rgba(root.controlColor.r, root.controlColor.g, root.controlColor.b, root.isPlaying ? 0.95 : 0.68)
                            opacity: (progressBar.pbStyle !== 1 && progressBar.pbStyle !== 3 && progressBar.pbStyle !== 4 && progressBar.progress > 0) ? 1.0 : 0.0
                            layer.enabled: progressBar.pbStyle !== 1 && progressBar.pbStyle !== 3
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: root.pgStartColor
                                shadowOpacity: progressBar.pbStyle === 2 ? (root.isPlaying ? 0.75 : 0.42) : (root.isPlaying ? 0.55 : 0.22)
                                shadowBlur: progressBar.pbStyle === 2 ? 0.60 : 0.40
                            }

                            scale: progressBar.animateDecorations && (progressBar.pbStyle === 0 || progressBar.pbStyle === 2) ? 1.05 - 0.13 * Math.cos(2 * Math.PI * (root.visualFrameTime % 1400) / 1400) : 1
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        text: positionClock.elapsedText
                        color: root.textColor
                        opacity: 0.50
                        font.pixelSize: 8
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        text: positionClock.totalText
                        color: root.textColor
                        opacity: 0.50
                        font.pixelSize: 8
                    }

                    MouseArea {
                        id: pbArea
                        objectName: "pbArea"
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: mouse => {
                            const p = root.player;
                            if (!p || p.canSeek === false || p.positionSupported === false)
                                return;
                            const len = p.length || p.mprisLength || 0;
                            if (!len)
                                return;
                            const ratio = progressTrack.width > 0 ? positionClock.clamp((mouse.x - progressTrack.x) / progressTrack.width, 0, 1) : 0;
                            const newPos = ratio * len;
                            positionClock.setPosition(newPos);

                            // Robust seek implementation for different MPRIS layers
                            if (typeof p.position !== "undefined" && p.canSeek !== false) {
                                p.position = newPos;
                            } else if (typeof p.SetPosition === "function") {
                                p.SetPosition(newPos);
                            } else if (typeof p.setPosition === "function") {
                                p.setPosition(newPos);
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    text: root.trackUnknown ? "No track metadata" : root.displayTrack
                    color: root.textColor
                    opacity: root.trackUnknown ? 0.75 : 1
                    font.bold: true
                    font.italic: root.trackUnknown
                    font.pixelSize: 11
                    elide: Text.ElideRight

                    // The raw value is the only clue when someone reports "it
                    // shows nothing" — one hover away beats putting it on the card.
                    HoverHandler {
                        id: rawTrackHover
                    }
                    QQC.ToolTip.visible: rawTrackHover.hovered && root.trackUnknown && root.track !== ""
                    QQC.ToolTip.text: root.track.length > 160 ? root.track.substring(0, 160) + "…" : root.track
                }

                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    text: root.artist !== "" ? root.artist : root.sourceHint
                    color: root.textColor
                    opacity: 0.6
                    font.pixelSize: 9
                    font.italic: root.artist === "" && root.sourceHint !== ""
                    elide: Text.ElideRight
                }
            }
        }
    }
}
