import QtQuick

// A 10 px MPRIS toggle (shuffle/repeat) drawn from the HTML's 24-unit SVG icon:
// .45 opacity when off, accent colour when on.
Item {
    id: toggle
    property string iconPath: ""
    property bool active: false
    property string areaName: ""
    property color controlColor: "#ffffff"
    property color accentColor: "#ffffff"
    signal toggled

    implicitWidth: 22
    implicitHeight: 22
    scale: toggleArea.pressed ? 0.94 : (toggleArea.containsMouse ? 1.08 : 1.0)
    Behavior on scale {
        NumberAnimation {
            duration: 130
            easing.type: Easing.OutCubic
        }
    }

    Canvas {
        anchors.centerIn: parent
        width: 10
        height: 10
        opacity: toggle.active ? 1 : 0.45
        readonly property var signature: [toggle.active, toggle.controlColor, toggle.accentColor, toggle.iconPath]
        onSignatureChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.scale(width / 24, height / 24);
            ctx.fillStyle = toggle.active ? toggle.accentColor : toggle.controlColor;
            ctx.path = toggle.iconPath;
            ctx.fill();
        }
    }

    MouseArea {
        id: toggleArea
        objectName: toggle.areaName
        anchors.fill: parent
        anchors.margins: -2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.toggled()
    }
}
