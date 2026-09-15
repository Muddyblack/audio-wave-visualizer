import QtQuick
import QtQuick.Controls.Basic as Controls

Controls.TextField {
    id: control

    implicitHeight: 34
    leftPadding: 14
    rightPadding: 14
    color: "#cdd6f4"
    placeholderTextColor: "#6c7086"
    font.pixelSize: 12
    selectionColor: "#585b70"
    selectedTextColor: "#cdd6f4"

    background: Rectangle {
        radius: 14
        color: "#181825"
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? "#b4befe" : "#45475a"
        Behavior on border.color {
            ColorAnimation {
                duration: 90
            }
        }
    }
}
