import QtQuick
import QtQuick.Dialogs
import "../../code/WaveMath.js" as WaveMath

// An editable colour range of any length: a live gradient strip, one chip per
// colour (click to change, × to remove) and a + chip that appends a colour.
// `value` is "#rrggbb,#rrggbb,..." and every edit is reported through activated.
Column {
    id: control
    property string value: ""
    property int minColors: 1
    property int maxColors: 16
    signal activated(string value)

    readonly property var colors: WaveMath.parseColors(value)
    property int editIndex: -1

    function commit(list) {
        control.activated(list.join(","));
    }
    function replaceAt(index, color) {
        const next = colors.slice();
        if (index >= next.length)
            next.push(color);
        else
            next[index] = color;
        commit(next);
    }
    function removeAt(index) {
        if (colors.length <= minColors)
            return;
        const next = colors.slice();
        next.splice(index, 1);
        commit(next);
    }

    spacing: 10

    Row {
        width: parent.width
        height: 10
        clip: true
        Repeater {
            model: Math.max(1, control.colors.length - 1)
            Rectangle {
                required property int index
                width: parent.width / Math.max(1, control.colors.length - 1)
                height: parent.height
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: control.colors[index] ?? "#808080"
                    }
                    GradientStop {
                        position: 1
                        color: control.colors[Math.min(index + 1, control.colors.length - 1)] ?? "#808080"
                    }
                }
            }
        }
    }

    Flow {
        width: parent.width
        spacing: 7

        Repeater {
            model: control.colors
            Item {
                id: chip
                required property int index
                required property var modelData
                width: 26
                height: 26
                Rectangle {
                    anchors.fill: parent
                    radius: 13
                    color: chip.modelData
                    border.width: 1
                    border.color: "#40ffffff"
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        control.editIndex = chip.index;
                        picker.selectedColor = chip.modelData;
                        picker.open();
                    }
                }
                Rectangle {
                    visible: control.colors.length > control.minColors
                    x: parent.width - 10
                    y: -4
                    width: 14
                    height: 14
                    radius: 7
                    color: "#1b1e21"
                    border.width: 1
                    border.color: "#59ffffff"
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: "#e9efe4"
                        font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: control.removeAt(chip.index)
                    }
                }
            }
        }

        Rectangle {
            visible: control.colors.length < control.maxColors
            width: 26
            height: 26
            radius: 13
            color: "transparent"
            border.width: 1
            border.color: "#59ffffff"
            Text {
                anchors.centerIn: parent
                text: "+"
                color: "#e9efe4"
                font.pixelSize: 16
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    control.editIndex = control.colors.length;
                    picker.selectedColor = control.colors[control.colors.length - 1] ?? "#ffffff";
                    picker.open();
                }
            }
        }
    }

    ColorDialog {
        id: picker
        onAccepted: control.replaceAt(control.editIndex, WaveMath.hexOf(selectedColor))
    }
}
