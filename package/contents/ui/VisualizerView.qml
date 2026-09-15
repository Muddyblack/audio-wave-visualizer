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
        active: !root.coverPalette && root.shouldShow && root.artUrl !== "" && (root.configuration.accentFromArt || root.configuration.vizColorMode === "cover")
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
    readonly property color textColor: configuration.useSystemText ? systemTextColor : configuration.customTextColor
    readonly property color waveColor: configuration.accentFromArt ? coverAccent : baseWaveColor
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

    onPlayerChanged: {
        artUrl = "";
        _refreshArtUrl();
    }
    onPlayerArtUrlChanged: _refreshArtUrl()
    Component.onCompleted: _refreshArtUrl()

    readonly property bool showMpris: configuration.showMpris
    onShowMprisChanged: _refreshArtUrl()

    Item {
        anchors.fill: parent
        visible: root.shouldShow
        // No clip: text and control shadows may extend beyond the card.

        CardSurface {
            anchors.fill: parent
            configuration: root.configuration
            artUrl: root.artUrl
            hasPlayer: root.hasPlayer
        }

        Loader {
            id: layoutLoader
            anchors.fill: parent
            sourceComponent: ({
                    mirrored: mirroredLayout,
                    inline: inlineLayout,
                    hero: heroLayout,
                    stacked: stackedLayout,
                    poster: posterLayout,
                    strip: stripLayout
                })[root.layoutMode] ?? classicLayout
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
        id: stripLayout
        Layouts.Strip {
            view: root
        }
    }
}
