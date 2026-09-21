import QtQuick

// Example custom playback controls. Import through Buttons → Custom button styles.
Item {
    id: root
    readonly property int apiVersion: 1
    required property var buttons
    implicitWidth: 112
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(root.buttons.accentColor.r, root.buttons.accentColor.g, root.buttons.accentColor.b, 0.18)
        border.color: Qt.rgba(root.buttons.accentColor.r, root.buttons.accentColor.g, root.buttons.accentColor.b, 0.5)
    }
    Row {
        anchors.centerIn: parent
        spacing: 4
        Repeater {
            model: ["previous", "togglePlaying", "next"]
            Item {
                required property string modelData
                width: modelData === "togglePlaying" ? 28 : 22
                height: 24
                readonly property bool available: modelData === "previous" ? root.buttons.canGoPrevious : modelData === "next" ? root.buttons.canGoNext : root.buttons.canTogglePlaying
                opacity: available ? 1 : 0.35
                visible: modelData === "togglePlaying" || root.buttons.showSkipButtons
                Text {
                    anchors.centerIn: parent
                    text: parent.modelData === "previous" ? "◀" : parent.modelData === "next" ? "▶" : root.buttons.isPlaying ? "Ⅱ" : "▶"
                    color: parent.modelData === "togglePlaying" ? root.buttons.accentColor : root.buttons.iconColor
                    font.pixelSize: parent.modelData === "togglePlaying" ? 16 : 12
                }
                MouseArea {
                    objectName: "exampleButton_" + parent.modelData
                    anchors.fill: parent
                    enabled: parent.available
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (parent.modelData === "previous")
                            root.buttons.previous();
                        else if (parent.modelData === "next")
                            root.buttons.next();
                        else
                            root.buttons.togglePlaying();
                    }
                }
            }
        }
    }
}
