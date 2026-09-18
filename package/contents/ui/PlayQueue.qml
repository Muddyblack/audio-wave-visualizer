import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    objectName: "playQueue"
    required property var view
    property bool expanded: false
    spacing: 8
    Controls.Button {
        Layout.fillWidth: true
        text: (root.expanded ? "▾  " : "▸  ") + qsTr("Up Next")
        Accessible.name: qsTr("Toggle upcoming tracks")
        onClicked: root.expanded = !root.expanded
    }
    MediaLookup {
        id: lookup
        mode: "queue"
        commandSourceComponent: root.view.visualizer.commandSourceComponent ?? null
        payload: Object.assign({}, root.view.playerSelector, {
            track: root.view.trackIdentity
        })
        active: root.expanded && root.visible && !root.view.samplePlayback && root.view.hasPlayer
    }
    Timer {
        interval: 5000
        repeat: true
        running: lookup.active
        onTriggered: lookup.refresh()
    }
    Text {
        Layout.fillWidth: true
        visible: root.expanded
        color: "#aeb7bc"
        font.pixelSize: 11
        wrapMode: Text.Wrap
        text: root.view.samplePlayback ? qsTr("Queue unavailable in preview") : lookup.status === "loading" ? qsTr("Loading queue…") : lookup.status === "unsupported" ? qsTr("This player does not share its queue") : lookup.status === "unknown" ? qsTr("Current track is outside the shared queue") : lookup.status === "error" ? qsTr("Queue unavailable. Check that the player is running and busctl is installed.") : lookup.status === "ready" ? ((lookup.result.tracks ?? []).length ? qsTr("Player playlist order • shuffle may differ") : qsTr("No upcoming tracks")) : ""
    }
    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(180, contentHeight)
        visible: root.expanded
        clip: true
        model: lookup.result.tracks ?? []
        Controls.ScrollBar.vertical: Controls.ScrollBar {}
        delegate: Item {
            id: entry
            required property var modelData
            required property int index
            width: ListView.view.width
            height: 42
            Column {
                width: parent.width - 12
                Text {
                    width: parent.width
                    text: (entry.index + 1) + ".  " + (entry.modelData["xesam:title"] || qsTr("Unknown track"))
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: "#eef0ec"
                    font.pixelSize: 12
                }
                Text {
                    width: parent.width
                    readonly property var artists: entry.modelData["xesam:artist"] ?? []
                    text: Array.isArray(artists) ? artists.join(", ") : String(artists)
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: "#aeb7bc"
                    font.pixelSize: 10
                }
            }
        }
    }
    Text {
        visible: root.expanded && (lookup.result.total ?? 0) > 50
        text: qsTr("Showing the next 50 tracks")
        color: "#aeb7bc"
        font.pixelSize: 10
    }
}
