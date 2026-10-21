import QtQuick

// A desktop host can retain an old rectangle after a layout change. Keep the
// complete card at its design proportions, including text and input targets.
Item {
    id: frame
    // Reading layouts reflow at the host size instead of shrinking the text.
    property bool fitContents: true
    // Fitted cards grow along the spare axis so the card covers the host and
    // its layout reflows there, instead of leaving empty bands inside it.
    property bool fill: false
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
        readonly property bool grows: frame.fitContents && frame.fill && frame.fitScale > 0
        width: grows ? (frame.sideways ? frame.height : frame.width) / frame.fitScale : frame.fitContents ? frame.designSize.width : frame.sideways ? frame.height : frame.width
        height: grows ? (frame.sideways ? frame.width : frame.height) / frame.fitScale : frame.fitContents ? frame.designSize.height : frame.sideways ? frame.width : frame.height
        x: (frame.width - width) / 2
        y: (frame.height - height) / 2
        scale: frame.fitScale
        rotation: frame.contentRotation
        enabled: frame.fitScale > 0
    }
}
