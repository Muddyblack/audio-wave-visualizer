import QtQuick
import QtQuick.Controls as QQC

Text {
    id: root
    property bool secondary: false
    property bool trackUnknown: false
    property string displayTrack: ""
    property string rawTrack: ""
    property string artist: ""
    property string sourceHint: ""

    text: secondary ? (artist !== "" ? artist : sourceHint) : (trackUnknown ? qsTr("No track metadata") : displayTrack)
    opacity: secondary ? 0.6 : (trackUnknown ? 0.75 : 1)
    font.bold: !secondary
    font.italic: secondary ? (artist === "" && sourceHint !== "") : trackUnknown
    font.pixelSize: secondary ? 9 : 11
    elide: Text.ElideRight

    // Keep the original metadata available when the player publishes no title.
    HoverHandler {
        id: rawTrackHover
        enabled: !root.secondary
    }
    QQC.ToolTip.visible: !secondary && rawTrackHover.hovered && trackUnknown && rawTrack !== ""
    QQC.ToolTip.text: rawTrack.length > 160 ? rawTrack.substring(0, 160) + "…" : rawTrack
}
