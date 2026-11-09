import QtQuick
import "../code/ColourStyle.js" as ColourStyle

// The Frosted text edge: a glass panel behind a text block, like a macOS
// widget. The wallpaper underneath is blurred (BackdropBlur), then tinted
// against the ink: light glass under dark text, dark glass under light text.
// A hairline border finishes the edge. Without a wallpaper to sample
// (software renderer, panel popups, other hosts) the tint alone carries it,
// a little stronger.
Item {
    id: panel
    property Item backdrop: null
    property color ink: "#ffffff"
    property real radius: 14
    readonly property bool darkInk: ColourStyle.luminance(ink) <= 0.5
    readonly property bool frosted: glass.available

    BackdropBlur {
        id: glass
        anchors.fill: parent
        sourceItem: panel.backdrop
        strength: 1
        refraction: 0
        specular: false
        radius: panel.radius
    }
    Rectangle {
        objectName: "textPanelTint"
        anchors.fill: parent
        radius: panel.radius
        color: panel.darkInk ? "#ffffff" : "#0b0e12"
        opacity: panel.frosted ? (panel.darkInk ? 0.35 : 0.22) : (panel.darkInk ? 0.6 : 0.42)
    }
    Rectangle {
        anchors.fill: parent
        radius: panel.radius
        color: "transparent"
        border.width: 1
        border.color: panel.darkInk ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(1, 1, 1, 0.15)
    }
}
