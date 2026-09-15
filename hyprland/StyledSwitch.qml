import QtQuick
import QtQuick.Controls.Basic as Controls

// Material-You-style capsule switch: full-pill track, thumb that grows
// slightly under press and glides (not jumps) between states.
Controls.Switch {
    id: control

    readonly property color trackOn: "#b4befe"
    readonly property color trackOff: "#313244"
    readonly property color thumbOn: "#1e1e2e"
    readonly property color thumbOff: "#a6adc8"

    implicitWidth: 44
    implicitHeight: 26

    indicator: Rectangle {
        x: control.leftPadding
        y: (control.height - height) / 2
        width: 44
        height: 26
        radius: height / 2
        color: control.checked ? control.trackOn : control.trackOff
        border.width: 1
        border.color: control.checked ? control.trackOn : "#45475a"
        Behavior on color {
            ColorAnimation {
                duration: 130
            }
        }

        Rectangle {
            readonly property real size: control.pressed ? 22 : 18
            width: size
            height: size
            radius: size / 2
            y: (parent.height - height) / 2
            x: control.checked ? parent.width - width - 4 : 4
            color: control.checked ? control.thumbOn : control.thumbOff
            Behavior on x {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }

        // A faint glow behind the track on hover, the same "state layer"
        // trick Material uses instead of changing the fill color outright.
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: height / 2
            color: control.checked ? control.trackOn : "#cdd6f4"
            opacity: control.hovered ? (control.pressed ? 0.16 : 0.1) : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                }
            }
        }
    }
}
