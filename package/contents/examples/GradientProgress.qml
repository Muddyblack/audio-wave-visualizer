import QtQuick

Item {
    id: root
    readonly property int apiVersion: 1
    required property var progressBar
    implicitHeight: progressBar.showTimes ? 24 : 10

    Rectangle {
        id: track
        width: parent.width
        height: 6
        radius: 3
        color: Qt.rgba(root.progressBar.textColor.r, root.progressBar.textColor.g, root.progressBar.textColor.b, 0.15)
        Rectangle {
            width: parent.width * root.progressBar.progress
            height: parent.height
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: root.progressBar.startColor
                }
                GradientStop {
                    position: 1
                    color: root.progressBar.endColor
                }
            }
        }
    }
    Text {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        visible: root.progressBar.showTimes
        text: root.progressBar.elapsedText
        color: root.progressBar.textColor
        font.pixelSize: 9
    }
    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.progressBar.showTimes
        text: root.progressBar.timeFormat === "remaining" ? root.progressBar.remainingText : root.progressBar.totalText
        color: root.progressBar.textColor
        font.pixelSize: 9
    }
    MouseArea {
        objectName: "customSeekArea"
        anchors.fill: parent
        enabled: root.progressBar.canSeek
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (width > 0)
                root.progressBar.seekToFraction(mouse.x / width);
        }
    }
}
