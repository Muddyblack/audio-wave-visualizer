pragma ComponentBehavior: Bound
import QtQuick

// Monospace, slash-drawn spectrum inspired by plaintop's ASCII load bars:
// square glyph columns, no fills, no rounded corners.
// Copy this file into your own permanent style folder and import it in Studio.
Item {
    id: root
    readonly property int apiVersion: 1
    required property var visualizer

    readonly property string glyph: "/"
    readonly property int rowCount: 14

    Row {
        anchors.fill: parent
        spacing: 2

        Repeater {
            model: root.visualizer.numBars

            Item {
                id: cell
                required property int index

                readonly property real level: Math.max(0, Math.min(1, (root.visualizer.bars[index] || 0) / Math.max(1, root.visualizer.maxRange)))
                readonly property int filled: root.visualizer.hasAudio ? Math.max(1, Math.round(level * root.rowCount)) : 1
                readonly property real rowHeight: root.height / root.rowCount

                width: Math.max(1, (root.width - 2 * (root.visualizer.numBars - 1)) / Math.max(1, root.visualizer.numBars))
                height: root.height

                Column {
                    id: stack
                    width: cell.width
                    anchors.top: root.visualizer.direction === "down" ? parent.top : undefined
                    anchors.bottom: root.visualizer.direction === "down" ? undefined : parent.bottom

                    Repeater {
                        model: cell.filled
                        Text {
                            required property int index
                            text: root.glyph
                            font.family: "monospace"
                            font.pixelSize: Math.max(6, cell.rowHeight * 0.85)
                            width: stack.width
                            horizontalAlignment: Text.AlignHCenter
                            color: root.visualizer.waveColor
                            opacity: root.visualizer.hasAudio ? 0.9 : 0.3
                        }
                    }
                }
            }
        }
    }
}
