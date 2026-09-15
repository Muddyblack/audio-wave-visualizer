import QtQuick
import QtQuick.Effects

Item {
    id: root
    property string artUrl: ""
    property string desktopEntry: ""
    property Component fallbackIcon

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(1, 1, 1, 0.05)
        border.color: Qt.rgba(1, 1, 1, 0.18)
        border.width: 1
    }

    Loader {
        anchors.centerIn: parent
        sourceComponent: root.fallbackIcon
        width: root.desktopEntry !== "" ? parent.width * 0.72 : parent.width * 0.45
        height: width
        opacity: root.desktopEntry !== "" ? 0.70 : 0.35
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
    }

    Image {
        id: artImg
        anchors.fill: parent
        source: root.artUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
    }

    Rectangle {
        id: artMask
        anchors.fill: parent
        radius: 10
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent
        source: artImg
        maskEnabled: true
        maskSource: artMask
        opacity: (artImg.status === Image.Ready || artImg.status === Image.Loading) ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 400
            }
        }
    }
}
