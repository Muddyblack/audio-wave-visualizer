import QtQuick
import QtQuick.Controls.Basic as Controls

Controls.ComboBox {
    id: control

    implicitHeight: 34
    font.pixelSize: 12
    leftPadding: 14
    rightPadding: 30

    background: Rectangle {
        radius: 14
        color: "#181825"
        border.width: control.popup.visible || control.activeFocus ? 2 : 1
        border.color: control.popup.visible || control.activeFocus ? "#b4befe" : "#45475a"
        Behavior on border.color {
            ColorAnimation {
                duration: 90
            }
        }
    }

    contentItem: Text {
        leftPadding: control.leftPadding
        rightPadding: control.rightPadding
        text: control.displayText
        color: "#cdd6f4"
        font: control.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Text {
        x: control.width - width - 12
        y: (control.height - height) / 2
        text: "▾"
        color: "#a6adc8"
        font.pixelSize: 10
    }

    popup: Controls.Popup {
        y: control.height + 6
        width: control.width
        implicitHeight: Math.min(contentItem.implicitHeight + 10, 220)
        padding: 5

        background: Rectangle {
            color: "#181825"
            radius: 16
            border.width: 1
            border.color: "#45475a"
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            Controls.ScrollBar.vertical: Controls.ScrollBar {}
        }
    }

    delegate: Controls.ItemDelegate {
        id: entry
        required property var modelData
        required property int index
        width: control.width
        height: 32
        highlighted: control.highlightedIndex === index

        contentItem: Text {
            leftPadding: 12
            text: control.textRole ? entry.modelData[control.textRole] : entry.modelData
            color: "#cdd6f4"
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 10
            color: entry.highlighted ? "#313244" : "transparent"
        }
    }
}
