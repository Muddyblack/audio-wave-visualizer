import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import "text"

ColumnLayout {
    id: root
    objectName: "playQueue"
    required property var view
    property bool expanded: false
    spacing: 8
    Controls.Button {
        Layout.fillWidth: true
        text: (root.expanded ? "▾  " : "▸  ") + I18n.i18n("Up Next")
        Accessible.name: I18n.i18n("Toggle upcoming tracks")
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
        font.pixelSize: SystemText.px(11)
        wrapMode: Text.Wrap
        text: root.view.samplePlayback ? I18n.i18n("Queue unavailable in preview") : lookup.status === "loading" ? I18n.i18n("Loading queue…") : lookup.status === "unsupported" ? I18n.i18n("This player does not share its queue") : lookup.status === "unknown" ? I18n.i18n("Current track is outside the shared queue") : lookup.status === "error" ? I18n.i18n("Queue unavailable. Check that the player is running and busctl is installed.") : lookup.status === "ready" ? ((lookup.result.tracks ?? []).length ? I18n.i18n("Player playlist order • shuffle may differ") : I18n.i18n("No upcoming tracks")) : ""
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
                    text: (entry.index + 1) + ".  " + (entry.modelData["xesam:title"] || I18n.i18n("Unknown track"))
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: "#eef0ec"
                    font.pixelSize: SystemText.px(12)
                }
                Text {
                    width: parent.width
                    readonly property var artists: entry.modelData["xesam:artist"] ?? []
                    text: Array.isArray(artists) ? artists.join(", ") : String(artists)
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: "#aeb7bc"
                    font.pixelSize: SystemText.px(10)
                }
            }
        }
    }
    Text {
        visible: root.expanded && (lookup.result.total ?? 0) > 50
        text: I18n.i18n("Showing the next 50 tracks")
        color: "#aeb7bc"
        font.pixelSize: SystemText.px(10)
    }
}
