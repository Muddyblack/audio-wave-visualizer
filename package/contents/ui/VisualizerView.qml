pragma ComponentBehavior: Bound
import QtQuick
import "layouts" as Layouts
import "../code/Layouts.js" as LayoutSizes

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
    // Plasma supplies ImageColors; other hosts sample a tiny static cover.
    property var coverPalette: null
    readonly property color baseWaveColor: configuration.useSystemAccent ? accentColor : configuration.customColor
    readonly property color coverColor1: coverPalette ? coverPalette.dominant : (coverSampler.item?.primary ?? baseWaveColor)
    readonly property color coverColor2: coverPalette ? coverPalette.dominantContrast : (coverSampler.item?.secondary ?? baseWaveColor)
    readonly property color coverAccent: coverPalette ? coverPalette.highlight : (coverSampler.item?.accent ?? baseWaveColor)
    Loader {
        id: coverSampler
        active: !root.coverPalette && root.shouldShow && root.artUrl !== "" && (root.configuration.accentFromArt || root.configuration.vizColorMode === "cover" || (root.configuration.showBg && (root.configuration.surfaceStyle === "atmosphere" || (root.configuration.surfaceStyle === "liquid" && root.configuration.glassTint === "cover"))))
        sourceComponent: CoverColors {
            source: root.artUrl
            fallback: root.baseWaveColor
        }
    }
    // Zero preserves Plasma's historical unit detection; Quickshell uses seconds.
    property real positionUnitsPerSecond: 0
    // Decorative motion shares audio frames; it must not start its own
    // display-refresh animation loop on every monitor.
    readonly property real visualFrameTime: visualizer.frameTimeMs ?? 0

    readonly property bool shouldShow: hasPlayer || configuration.alwaysVisible
    implicitWidth: (layoutLoader.item as Item)?.implicitWidth ?? 360
    implicitHeight: (layoutLoader.item as Item)?.implicitHeight ?? 104
    readonly property bool hasPlayer: !!player
    property string artist: player?.artist ?? ""
    property string track: player?.track ?? ""
    property string playerArtUrl: player?.artUrl ?? ""
    readonly property string desktopEntry: player?.desktopEntry ?? ""

    // Track information (Plasma PlayerContainer or Quickshell MprisPlayer).
    readonly property string album: player?.album ?? player?.trackAlbum ?? ""
    readonly property var metadata: player?.metadata ?? ({})
    readonly property string genre: {
        const value = metadata["xesam:genre"];
        return Array.isArray(value) ? value.join(", ") : String(value ?? "");
    }
    readonly property int trackNumber: Number(metadata["xesam:trackNumber"] ?? 0) || 0
    readonly property string year: String(metadata["xesam:contentCreated"] ?? "").slice(0, 4)
    readonly property string playerName: player?.identity ?? ""
    readonly property real volume: player && player.volume !== undefined ? player.volume : -1
    readonly property string lengthText: {
        const length = player ? (player.length || player.mprisLength || 0) : 0;
        if (length <= 0)
            return "";
        const units = positionUnitsPerSecond > 0 ? positionUnitsPerSecond : length >= 1000000 ? 1000000 : length >= 10000 ? 1000 : 1;
        const seconds = Math.floor(length / units);
        return Math.floor(seconds / 60) + ":" + String(seconds % 60).padStart(2, "0");
    }
    // Hosts that know every running player set these for the player switcher.
    property int playerCount: hasPlayer ? 1 : 0
    property var switchPlayer: null
    readonly property string lyricLine: lyricsLoader.item?.currentLine ?? ""

    readonly property string detailsMode: !hasPlayer || trackUnknown ? "off" : (configuration.hoverDetails ?? "off")
    readonly property bool flipEnabled: detailsMode === "flip" && layoutMode !== "strip"
    readonly property bool flipped: flipEnabled && cardHovered
    // Tooltip and drawer are shown by the host in a popup outside the card.
    readonly property bool detailsVisible: (detailsMode === "tooltip" || detailsMode === "drawer" || (detailsMode === "flip" && layoutMode === "strip")) && cardHovered
    readonly property string detailsPopupMode: detailsMode === "drawer" ? "drawer" : "tooltip"
    // Solid cards are light: system text and controls switch to dark ink.
    readonly property bool lightCard: configuration.showBg && configuration.surfaceStyle === "solid" && !(configuration.showMpris && configuration.artBg && artUrl !== "") && (configuration.autoContrast ?? true)
    readonly property color textColor: configuration.useSystemText ? (lightCard ? "#1e241d" : systemTextColor) : configuration.customTextColor
    readonly property color waveColor: configuration.accentFromArt ? coverAccent : baseWaveColor
    readonly property color controlColor: configuration.useSystemControls ? (lightCard ? "#1e241d" : "#ffffff") : configuration.customControlColor
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
            return qsTr("Direct YouTube stream");
        if (host !== "")
            return host.replace(/^www\./, "");
        return qsTr("Player published no title");
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

    // Artwork click "zoom" shows the cover large over the card.
    property bool zoomOpen: false
    readonly property bool cardHovered: cardHover.hovered

    // Behaviour (docs/redesign-plan.md §7.5).
    readonly property bool idleMessage: !hasPlayer && (configuration.idleText ?? false)
    readonly property bool pausedPlayer: hasPlayer && !isPlaying
    // Hosts report the power source; battery saver caps frames and drops glow.
    property bool onBattery: false
    readonly property bool batterySaving: onBattery && (configuration.batterySaver ?? false)
    readonly property bool lifted: (configuration.hoverLift ?? false) && cardHovered

    WheelHandler {
        objectName: "volumeWheel"
        enabled: (root.configuration.scrollVolume ?? false) && root.hasPlayer && root.volume >= 0
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const step = event.angleDelta.y / 120 * 0.04;
            if (step === 0 || !root.player)
                return;
            root.player.volume = Math.max(0, Math.min(1, root.volume + step));
            volumeOsd.shown = true;
            volumeHide.restart();
        }
    }
    Timer {
        id: volumeHide
        interval: 1100
        onTriggered: volumeOsd.shown = false
    }
    // Vertical volume bar right of the card while scrolling.
    Rectangle {
        id: volumeOsd
        objectName: "volumeOsd"
        property bool shown: false
        x: root.width + 12
        y: root.height * 0.08
        width: 6
        height: root.height * 0.84
        radius: 6
        color: Qt.rgba(0, 0, 0, 0x77 / 255)
        border.color: Qt.rgba(1, 1, 1, 0x26 / 255)
        border.width: 1
        clip: true
        opacity: shown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height * Math.max(0, root.volume)
            color: root.waveColor
        }
    }

    HoverHandler {
        id: cardHover
    }

    Loader {
        id: lyricsLoader
        active: (root.configuration.showLyrics ?? false) && root.hasPlayer && !root.trackUnknown
        sourceComponent: LyricsSource {
            player: root.player
            isPlaying: root.isPlaying
            track: root.displayTrack
            artist: root.artist
            album: root.album
            positionUnitsPerSecond: root.positionUnitsPerSecond
            visualFrameTime: root.visualFrameTime
        }
    }

    onPlayerChanged: {
        zoomOpen = false;
        artUrl = "";
        _refreshArtUrl();
    }
    onPlayerArtUrlChanged: _refreshArtUrl()
    Component.onCompleted: _refreshArtUrl()

    readonly property bool showMpris: configuration.showMpris
    onShowMprisChanged: _refreshArtUrl()

    Item {
        id: front
        anchors.fill: parent
        visible: root.shouldShow
        // No clip: text and control shadows may extend beyond the card.
        // The flip turns each face separately and swaps them halfway;
        // backface visibility is unreliable with effects and canvases.
        opacity: Math.abs(frontTurn.angle) < 90 ? 1 : 0
        transform: (root.flipEnabled ? [frontTurn] : []).concat((root.configuration.hoverLift ?? false) ? [liftScale, liftShift] : [])
        Scale {
            id: liftScale
            origin.x: front.width / 2
            origin.y: front.height / 2
            xScale: root.lifted ? 1.01 : 1
            yScale: xScale
            Behavior on xScale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }
        Translate {
            id: liftShift
            y: root.lifted ? -3 : 0
            Behavior on y {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }
        Rotation {
            id: frontTurn
            origin.x: front.width / 2
            origin.y: front.height / 2
            axis.x: 0
            axis.y: 1
            axis.z: 0
            angle: root.flipped ? -180 : 0
            Behavior on angle {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.InOutCubic
                }
            }
        }

        CardSurface {
            anchors.fill: parent
            configuration: root.configuration
            artUrl: root.artUrl
            hasPlayer: root.hasPlayer
            accentColor: root.waveColor
            coverColor1: root.coverColor1
            coverColor2: root.coverColor2
            bass: root.visualizer.bass ?? 0
        }

        Loader {
            id: layoutLoader
            objectName: "layoutLoader"
            anchors.fill: parent
            // Dim the content (not the card) while paused.
            opacity: (root.configuration.dimWhenPaused ?? false) && root.pausedPlayer ? 0.55 : 1
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                }
            }
            sourceComponent: ({
                    mirrored: mirroredLayout,
                    inline: inlineLayout,
                    hero: heroLayout,
                    stacked: stackedLayout,
                    poster: posterLayout,
                    strip: stripLayout,
                    orbit: orbitLayout
                })[root.layoutMode] ?? classicLayout
        }

        Rectangle {
            objectName: "artZoom"
            anchors.fill: parent
            radius: root.configuration.bgRadius
            color: Qt.rgba(0.02, 0.02, 0.03, 0.9)
            opacity: root.zoomOpen ? 1 : 0
            // Visible from the moment it opens, so it can be closed mid-fade.
            visible: root.zoomOpen || opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 12
                ArtView {
                    objectName: "zoomArt"
                    width: Math.max(0, Math.min(parent.parent.height - 16, 220))
                    height: width
                    artUrl: root.artUrl
                    desktopEntry: root.desktopEntry
                    fallbackIcon: root.fallbackIcon
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(60, Math.min(220, parent.parent.width - parent.parent.height - 28))
                    Text {
                        width: parent.width
                        text: root.displayTrack
                        color: root.textColor
                        font.pixelSize: 13
                        font.bold: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: root.artist
                        color: root.textColor
                        opacity: 0.7
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
            }
            MouseArea {
                objectName: "artZoomArea"
                anchors.fill: parent
                enabled: root.zoomOpen
                onClicked: root.zoomOpen = false
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.flipEnabled && root.shouldShow
        sourceComponent: Item {
            id: backFace
            objectName: "flipBack"
            opacity: Math.abs(backTurn.angle) < 90 ? 1 : 0
            transform: Rotation {
                id: backTurn
                origin.x: backFace.width / 2
                origin.y: backFace.height / 2
                axis.x: 0
                axis.y: 1
                axis.z: 0
                angle: root.flipped ? 0 : 180
                Behavior on angle {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.InOutCubic
                    }
                }
            }
            CardMaterial {
                anchors.fill: parent
                material: root.configuration.showBg && ["liquid", "solid", "atmosphere"].indexOf(root.configuration.surfaceStyle) !== -1 ? root.configuration.surfaceStyle : "glass"
                radius: root.configuration.bgRadius
                cover1: root.coverColor1
                cover2: root.coverColor2
            }
            TrackDetails {
                anchors.fill: parent
                view: root
                mode: "back"
            }
        }
    }

    readonly property string layoutMode: LayoutSizes.mode(configuration)

    Component {
        id: classicLayout
        Layouts.Classic {
            view: root
        }
    }
    Component {
        id: mirroredLayout
        Layouts.Classic {
            view: root
            mirrored: true
        }
    }
    Component {
        id: inlineLayout
        Layouts.Inline {
            view: root
        }
    }
    Component {
        id: heroLayout
        Layouts.Hero {
            view: root
        }
    }
    Component {
        id: stackedLayout
        Layouts.Stacked {
            view: root
        }
    }
    Component {
        id: posterLayout
        Layouts.Poster {
            view: root
        }
    }
    Component {
        id: orbitLayout
        Layouts.Orbit {
            view: root
        }
    }
    Component {
        id: stripLayout
        Layouts.Strip {
            view: root
        }
    }
}
