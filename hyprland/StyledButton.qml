import QtQuick
import QtQuick.Controls.Basic as Controls

// Material-You pill button: fully rounded, filled for the one prominent
// action on a page (accent: true), tonal/outlined for the rest.
Controls.Button {
    id: control
    property bool accent: false
    property bool danger: false

    implicitHeight: 36
    leftPadding: 20
    rightPadding: 20
    font.pixelSize: 12
    font.bold: accent

    readonly property color baseColor: accent ? "#b4befe" : danger ? "#f38ba8" : "#313244"

    background: Rectangle {
        radius: height / 2
        color: control.baseColor
        border.width: control.accent || control.danger ? 0 : 1
        border.color: "#45475a"

        // Hover/press state layer: a translucent wash of the button's own
        // "on" color rather than swapping the fill, so the pill shape and
        // its border read as one stable surface underneath.
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: control.accent || control.danger ? "#1e1e2e" : "#cdd6f4"
            opacity: control.down ? 0.18 : control.hovered ? 0.1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                }
            }
        }
    }

    contentItem: Text {
        text: control.text
        color: control.accent ? "#1e1e2e" : control.danger ? "#1e1e2e" : "#cdd6f4"
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
