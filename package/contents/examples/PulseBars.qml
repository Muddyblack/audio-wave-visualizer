pragma ComponentBehavior: Bound
import QtQuick

// Copy this file into your own permanent style folder and import it in Studio.
Item {
    id: root
    readonly property int apiVersion: 1
    required property var visualizer

    Row {
        anchors.fill: parent
        spacing: 3
        Repeater {
            model: root.visualizer.numBars
            Rectangle {
                required property int index
                width: Math.max(0, (root.width - 3 * (root.visualizer.numBars - 1)) / Math.max(1, root.visualizer.numBars))
                height: Math.max(2, root.height * Math.max(0, Math.min(1, (root.visualizer.bars[index] || 0) / Math.max(1, root.visualizer.maxRange))))
                y: root.visualizer.direction === "down" ? 0 : root.height - height
                radius: width / 2
                color: root.visualizer.waveColor
                opacity: root.visualizer.hasAudio ? 0.55 + 0.45 * root.visualizer.bass : 0.3
            }
        }
    }
}
