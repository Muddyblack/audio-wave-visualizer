import QtQuick

// A desktop host can retain an old rectangle after a layout change. Keep the
// complete card at its design proportions, including text and input targets.
Item {
    id: frame
    // Reading layouts reflow at the host size instead of shrinking the text.
    property bool fitContents: true
    property int contentRotation: 0
    readonly property bool sideways: Math.abs(contentRotation) % 180 === 90
    property size designSize: Qt.size(360, 104)
    default property alias content: canvas.data
    readonly property real fitScale: !fitContents ? 1 : designSize.width > 0 && designSize.height > 0 ? Math.max(0, Math.min(width / (sideways ? designSize.height : designSize.width), height / (sideways ? designSize.width : designSize.height))) : 0
    implicitWidth: sideways ? designSize.height : designSize.width
    implicitHeight: sideways ? designSize.width : designSize.height

    Item {
        id: canvas
        objectName: "fittedCanvas"
        width: frame.fitContents ? frame.designSize.width : frame.sideways ? frame.height : frame.width
        height: frame.fitContents ? frame.designSize.height : frame.sideways ? frame.width : frame.height
        x: (frame.width - width) / 2
        y: (frame.height - height) / 2
        scale: frame.fitScale
        rotation: frame.contentRotation
        enabled: frame.fitScale > 0
    }
}
