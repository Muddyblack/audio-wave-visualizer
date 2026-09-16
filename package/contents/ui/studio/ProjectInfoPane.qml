import QtQuick
import QtQuick.Effects
import "Theme.js" as Theme
import "ProjectInfo.js" as Project

Column {
    id: info
    required property var studio
    property var counts: ({})
    property var requests: []
    property bool requested: false
    readonly property bool onlineEnabled: studio.onScreen
    spacing: 18

    function loadCounts() {
        if (!onlineEnabled || requested)
            return;
        requested = true;
        Project.statistics.forEach(function (stat) {
            const request = new XMLHttpRequest();
            info.requests.push(request);
            request.open("GET", stat.url);
            request.onreadystatechange = function () {
                if (request.readyState !== XMLHttpRequest.DONE || request.status !== 200)
                    return;
                const value = Project.count(request.responseText);
                if (value) {
                    const next = Object.assign({}, info.counts);
                    next[stat.id] = value;
                    info.counts = next;
                }
            };
            request.send();
        });
        timeout.restart();
    }
    function cancelRequests() {
        requests.forEach(function (request) {
            request.onreadystatechange = null;
            request.abort();
        });
        requests = [];
    }
    onOnlineEnabledChanged: if (onlineEnabled)
        loadCounts()
    Component.onCompleted: loadCounts()
    Component.onDestruction: cancelRequests()
    Timer {
        id: timeout
        interval: 8000
        onTriggered: info.cancelRequests()
    }

    Row {
        width: parent.width
        spacing: 14
        Image {
            width: 64
            height: 64
            source: Qt.resolvedUrl("../../../icon.png")
            sourceSize.width: 128
            sourceSize.height: 128
            fillMode: Image.PreserveAspectFit
            Accessible.name: "Plasma Audio Visualizer project icon"
        }
        Text {
            width: parent.width - 78
            anchors.verticalCenter: parent.verticalCenter
            text: Project.name
            wrapMode: Text.WordWrap
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }
    }
    Row {
        width: parent.width
        spacing: 14
        Rectangle {
            width: 40
            height: 40
            radius: 20
            color: Theme.sunk
            layer.enabled: avatar.status === Image.Ready
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    color: "white"
                    layer.enabled: true
                    visible: false
                }
            }
            Text {
                anchors.centerIn: parent
                text: "M"
                color: Theme.brand
                font.pixelSize: 20
                visible: avatar.status !== Image.Ready
            }
            Image {
                id: avatar
                anchors.fill: parent
                source: info.onlineEnabled ? Project.avatar : ""
                sourceSize.width: 128
                sourceSize.height: 128
                asynchronous: true
                visible: status === Image.Ready
            }
        }
        StudioButton {
            anchors.verticalCenter: parent.verticalCenter
            text: "Created by " + Project.author + " ↗"
            compact: true
            onClicked: Qt.openUrlExternally(Project.profile)
        }
    }
    Text {
        width: parent.width
        text: "An open-source music visualizer for Plasma and Hyprland. Explore the project, get updates, or help improve it."
        wrapMode: Text.WordWrap
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }
    Flow {
        width: parent.width
        spacing: 8
        Repeater {
            model: Project.links
            StudioButton {
                required property var modelData
                text: modelData[0] + " ↗"
                compact: true
                onClicked: Qt.openUrlExternally(modelData[1])
            }
        }
    }
    Flow {
        width: parent.width
        spacing: 16
        visible: Object.keys(info.counts).length > 0
        Repeater {
            model: Project.statistics
            Column {
                required property var modelData
                visible: !!info.counts[modelData.id]
                spacing: 4
                Text {
                    text: info.counts[parent.modelData.id] || ""
                    color: Theme.text
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                }
                Text {
                    text: parent.modelData.label
                    color: Theme.muted
                    font.pixelSize: 11
                }
            }
        }
    }
    Text {
        width: parent.width
        text: "Enjoying the visualizer? A star on GitHub helps others discover it. Thank you for supporting the project."
        wrapMode: Text.WordWrap
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }
    StudioButton {
        text: "Star on GitHub ↗"
        icon: "M12 3l2.8 5.7 6.2.9-4.5 4.4 1.1 6.2-5.6-3-5.6 3 1.1-6.2L3 9.6l6.2-.9z"
        primary: true
        onClicked: Qt.openUrlExternally(Project.repository)
    }
    Text {
        width: parent.width
        text: "Have a design idea? Open an issue — I might add it. A sketch, mockup, or annotated screenshot helps explain what you have in mind."
        wrapMode: Text.WordWrap
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }
    StudioButton {
        text: "Suggest a design ↗"
        compact: true
        onClicked: Qt.openUrlExternally(Project.repository + "/issues/new")
    }
}
