pragma ComponentBehavior: Bound
import QtQuick

Flow {
    id: root
    property var badges: []
    property color textColor: "#eef0ec"
    spacing: 4
    visible: badges.length > 0
    Repeater {
        model: root.badges
        Rectangle {
            required property string modelData
            width: label.implicitWidth + 10
            height: label.implicitHeight + 4
            radius: 4
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
            Text {
                id: label
                anchors.centerIn: parent
                text: parent.modelData
                textFormat: Text.PlainText
                color: root.textColor
                font.pixelSize: 9
            }
        }
    }
}
