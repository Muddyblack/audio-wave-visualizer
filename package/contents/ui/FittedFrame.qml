import QtQuick

// A desktop host can retain an old rectangle after a layout change. Keep the
// complete card at its design proportions, including text and input targets.
Item {
    id: frame
    property size designSize: Qt.size(360, 104)
    default property alias content: canvas.data
    readonly property real fitScale: designSize.width > 0 && designSize.height > 0 ? Math.max(0, Math.min(width / designSize.width, height / designSize.height)) : 0
    implicitWidth: designSize.width
    implicitHeight: designSize.height

    Item {
        id: canvas
        objectName: "fittedCanvas"
        width: frame.designSize.width
        height: frame.designSize.height
        anchors.centerIn: parent
        scale: frame.fitScale
        enabled: frame.fitScale > 0
    }
}
