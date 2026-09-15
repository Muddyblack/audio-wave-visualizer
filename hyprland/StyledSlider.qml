import QtQuick
import QtQuick.Controls.Basic as Controls

Controls.Slider {
    id: control

    implicitHeight: 24

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.availableWidth
        height: 6
        radius: height / 2
        color: "#313244"

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: "#b4befe"
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        readonly property real size: control.pressed ? 20 : 17
        width: size
        height: size
        radius: size / 2
        color: "#b4befe"
        border.width: 2
        border.color: "#1e1e2e"
        Behavior on width {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 12
            height: width
            radius: width / 2
            color: "#cdd6f4"
            opacity: control.hovered ? (control.pressed ? 0.16 : 0.1) : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                }
            }
        }
    }
}
