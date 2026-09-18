import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    objectName: "artistInfo"
    required property var view
    property bool expanded: false
    spacing: 8
    Controls.Button {
        Layout.fillWidth: true
        text: (root.expanded ? "▾  " : "▸  ") + qsTr("Artist & album info")
        onClicked: root.expanded = !root.expanded
    }
    MediaLookup {
        id: lookup
        mode: "info"
        payload: ({
                artist: root.view.artist,
                album: root.view.album
            })
        commandSourceComponent: root.view.visualizer.commandSourceComponent ?? null
        active: root.expanded && root.visible && !root.view.samplePlayback && root.view.artist !== ""
    }
    Text {
        Layout.fillWidth: true
        visible: root.expanded
        color: "#eef0ec"
        font.pixelSize: 12
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        text: [root.view.album, lookup.result.year || root.view.year, (lookup.result.genres ?? []).join(", ") || root.view.genre].filter(Boolean).join(" · ")
    }
    Text {
        Layout.fillWidth: true
        visible: root.expanded
        color: "#cbd2d6"
        font.pixelSize: 12
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        text: root.view.samplePlayback ? qsTr("Information lookup unavailable in preview") : !root.view.artist ? qsTr("No artist metadata") : lookup.status === "loading" ? qsTr("Looking up MusicBrainz and Wikipedia…") : lookup.result.summary || (lookup.status === "error" ? qsTr("Could not reach the information services.") : qsTr("No matching artist summary found."))
    }
    Controls.Button {
        visible: root.expanded && lookup.status === "error"
        text: qsTr("Retry")
        onClicked: lookup.reset()
    }
    Controls.Button {
        visible: root.expanded && !!lookup.result.artistUrl
        text: qsTr("Wikipedia • CC BY-SA • source & history")
        onClicked: Qt.openUrlExternally(lookup.result.artistUrl)
    }
    Controls.Button {
        visible: root.expanded && !!lookup.result.albumUrl
        text: qsTr("Album on MusicBrainz")
        onClicked: Qt.openUrlExternally(lookup.result.albumUrl)
    }
}
