import QtQuick

// A small panel row uses the shared seek bar, with labels beside it.
Item {
    id: root
    required property var view
    readonly property int style: bar.style
    readonly property bool showTimes: false
    readonly property bool timeOnly: style === 9
    readonly property bool available: bar.lengthValue > 0
    readonly property bool labels: available && width >= 120 && (view.configuration.showTimes || timeOnly)
    implicitHeight: 9
    Text {
        id: elapsed
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: root.labels
        text: root.timeOnly ? bar.elapsedText + " / " + bar.totalLabel : bar.elapsedText
        color: root.view.textColor
        font.pixelSize: 8
        opacity: 0.8
    }
    Text {
        id: total
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.labels && !root.timeOnly
        text: bar.totalLabel
        color: root.view.textColor
        font.pixelSize: 8
        opacity: 0.65
    }
    LayoutProgress {
        id: bar
        view: root.view
        compact: true
        hideTimes: true
        anchors.fill: parent
        anchors.leftMargin: elapsed.visible ? elapsed.implicitWidth + 5 : 0
        anchors.rightMargin: total.visible ? total.implicitWidth + 5 : 0
        opacity: root.timeOnly ? 0 : 1
        enabled: !root.timeOnly
    }
}
