import QtQuick
import QtQuick.Controls.Basic as Controls
import "Schema.js" as Schema

Item {
    id: navigation
    required property var studio
    Flickable {
        id: scroller
        objectName: "presetTabScroller"
        anchors.fill: parent
        Controls.ScrollBar.horizontal: Controls.ScrollBar {
            policy: Controls.ScrollBar.AsNeeded
        }
        contentWidth: choices.width
        contentHeight: height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Row {
            id: choices
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Repeater {
                model: Schema.PRESET_VIEWS
                StudioButton {
                    required property var modelData
                    text: modelData[1]
                    icon: modelData[2]
                    compact: true
                    primary: modelData[0] === "mine" ? navigation.studio.currentTab === "saved" : navigation.studio.currentTab === "presets" && (navigation.studio.presetFilter === modelData[0] || modelData[0] === "all" && ["favorites", "daily"].indexOf(navigation.studio.presetFilter) === -1)
                    areaName: "presetView_" + modelData[0]
                    onClicked: {
                        navigation.studio.presetFilter = modelData[0];
                        navigation.studio.selectTab(modelData[0] === "mine" ? "saved" : "presets");
                    }
                }
            }
        }
    }
    TabScrollArrow {
        anchors.left: parent.left
        scroller: scroller
        forward: false
        areaName: "presetTabsBack"
        height: 28
        anchors.verticalCenter: parent.verticalCenter
    }
    TabScrollArrow {
        anchors.right: parent.right
        scroller: scroller
        areaName: "presetTabsForward"
        height: 28
        anchors.verticalCenter: parent.verticalCenter
    }
}
