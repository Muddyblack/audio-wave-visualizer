import QtQuick
import "studio/Translations.js" as Translations
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
        text: (root.expanded ? "▾  " : "▸  ") + (typeof i18n === "function" ? i18n("Up Next") : Translations.translate("Up Next"))
        Accessible.name: (typeof i18n === "function" ? i18n("Toggle upcoming tracks") : Translations.translate("Toggle upcoming tracks"))
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
        text: root.view.samplePlayback ? (typeof i18n === "function" ? i18n("Queue unavailable in preview") : Translations.translate("Queue unavailable in preview")) : lookup.status === "loading" ? (typeof i18n === "function" ? i18n("Loading queue…") : Translations.translate("Loading queue…")) : lookup.status === "unsupported" ? (typeof i18n === "function" ? i18n("This player does not share its queue") : Translations.translate("This player does not share its queue")) : lookup.status === "unknown" ? (typeof i18n === "function" ? i18n("Current track is outside the shared queue") : Translations.translate("Current track is outside the shared queue")) : lookup.status === "error" ? (typeof i18n === "function" ? i18n("Queue unavailable. Check that the player is running and busctl is installed.") : Translations.translate("Queue unavailable. Check that the player is running and busctl is installed.")) : lookup.status === "ready" ? ((lookup.result.tracks ?? []).length ? (typeof i18n === "function" ? i18n("Player playlist order • shuffle may differ") : Translations.translate("Player playlist order • shuffle may differ")) : (typeof i18n === "function" ? i18n("No upcoming tracks") : Translations.translate("No upcoming tracks"))) : ""
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
                    text: (entry.index + 1) + ".  " + (entry.modelData["xesam:title"] || (typeof i18n === "function" ? i18n("Unknown track") : Translations.translate("Unknown track")))
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
        text: (typeof i18n === "function" ? i18n("Showing the next 50 tracks") : Translations.translate("Showing the next 50 tracks"))
        color: "#aeb7bc"
        font.pixelSize: SystemText.px(10)
    }
}
