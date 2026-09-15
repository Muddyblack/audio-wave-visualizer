import QtQuick
import QtQuick.Layouts
import ".."

// Player chip, title, artist, album and lyric line at the configured size and
// alignment. Layouts scale them like the HTML (for example Stacked uses title
// ×1.6 and artist ×1.05).
ColumnLayout {
    id: root
    objectName: "layoutTexts"
    required property var view
    property real titleFactor: 1
    property real artistSize: 0.82
    property real albumSize: 0.72
    property real lyricSize: 0.78
    property int sourceSize: 7
    // Orbit always centres its texts.
    property int alignmentOverride: -1
    readonly property var cfg: view.configuration
    readonly property int alignment: alignmentOverride >= 0 ? alignmentOverride : cfg.textAlign === "center" ? Text.AlignHCenter : cfg.textAlign === "right" ? Text.AlignRight : Text.AlignLeft
    readonly property int layoutAlignment: alignment === Text.AlignHCenter ? Qt.AlignHCenter : alignment === Text.AlignRight ? Qt.AlignRight : Qt.AlignLeft
    readonly property real ts: cfg.titleSize ?? 11
    // Titles over 26 characters scroll (14 s loop, 12 % pause) on the audio clock.
    readonly property bool marquee: (cfg.marquee ?? false) && !(cfg.reducedMotion ?? false) && view.displayTrack.length > 26
    readonly property real marqueeOffset: {
        if (!marquee)
            return 0;
        const phase = (view.visualFrameTime % 14000) / 14000;
        return phase < 0.12 ? 0 : (phase - 0.12) / 0.88 * (title.implicitWidth + 40);
    }
    spacing: 0

    RowLayout {
        objectName: "sourceRow"
        visible: ((root.cfg.showSource ?? false) || (root.cfg.showPlayerSwitch ?? false)) && root.view.hasPlayer
        Layout.alignment: root.layoutAlignment
        Layout.bottomMargin: 3
        Layout.maximumWidth: root.width
        spacing: 5
        opacity: 0.65

        Rectangle {
            implicitWidth: 5
            implicitHeight: 5
            radius: 2.5
            color: root.view.waveColor
        }
        Text {
            objectName: "sourceChip"
            Layout.fillWidth: true
            text: root.view.playerName.toUpperCase()
            color: root.view.textColor
            font.pixelSize: root.sourceSize
            font.letterSpacing: 1.3
            elide: Text.ElideRight
        }
        Rectangle {
            visible: root.cfg.showPlayerSwitch ?? false
            implicitWidth: switchLabel.implicitWidth + 10
            implicitHeight: switchLabel.implicitHeight
            radius: 6
            color: Qt.rgba(1, 1, 1, 0x1a / 255)
            Text {
                id: switchLabel
                objectName: "playerSwitchLabel"
                anchors.centerIn: parent
                text: root.view.playerCount + " ▾"
                color: root.view.textColor
                font.pixelSize: root.sourceSize
                font.letterSpacing: 0.5
            }
            MouseArea {
                objectName: "playerSwitchArea"
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof root.view.switchPlayer === "function")
                        root.view.switchPlayer();
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: title.implicitHeight
        clip: root.marquee

        TrackText {
            id: title
            x: root.marquee ? -root.marqueeOffset : 0
            width: root.marquee ? implicitWidth : parent.width
            elide: root.marquee ? Text.ElideNone : Text.ElideRight
            titleSize: root.ts
            sizeFactor: root.titleFactor
            horizontalAlignment: root.marquee ? Text.AlignLeft : root.alignment
            displayTrack: root.view.displayTrack
            trackUnknown: root.view.trackUnknown
            rawTrack: root.view.track
            color: root.view.textColor
        }
        TrackText {
            visible: root.marquee
            x: title.x + title.implicitWidth + 40
            titleSize: root.ts
            sizeFactor: root.titleFactor
            displayTrack: root.view.displayTrack
            trackUnknown: root.view.trackUnknown
            rawTrack: root.view.track
            color: root.view.textColor
        }
    }

    TrackText {
        Layout.fillWidth: true
        secondary: true
        titleSize: root.ts
        sizeFactor: root.artistSize / 0.82
        horizontalAlignment: root.alignment
        artist: root.view.artist
        sourceHint: root.view.sourceHint
        color: root.view.textColor
    }

    Text {
        objectName: "albumLine"
        Layout.fillWidth: true
        Layout.topMargin: 1
        visible: (root.cfg.showAlbum ?? false) && root.view.album !== ""
        text: root.view.album + (root.view.year !== "" ? " · " + root.view.year : "")
        horizontalAlignment: root.alignment
        color: root.view.textColor
        opacity: 0.4
        font.pixelSize: Math.max(1, Math.round(root.ts * root.albumSize))
        elide: Text.ElideRight
    }

    Text {
        objectName: "lyricLine"
        Layout.fillWidth: true
        Layout.topMargin: 1
        visible: (root.cfg.showLyrics ?? false) && root.view.lyricLine !== ""
        text: root.view.lyricLine
        horizontalAlignment: root.alignment
        color: root.view.waveColor
        opacity: 0.9
        font.italic: true
        font.pixelSize: Math.max(1, Math.round(root.ts * root.lyricSize))
        elide: Text.ElideRight
    }
}
