import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    objectName: "artistInfo"
    required property var view
    property bool expanded: true
    spacing: 8
    Controls.Button {
        Layout.fillWidth: true
        text: (root.expanded ? "▾  " : "▸  ") + qsTr("Song details & credits")
        onClicked: root.expanded = !root.expanded
    }
    Text {
        Layout.fillWidth: true
        visible: root.expanded && !(root.view.configuration?.onlineTrackInfo ?? false)
        text: qsTr("Online information is off. Enable it in Settings → Track info for catalog details and credits.")
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        font.pixelSize: 11
        color: "#bac4d2"
    }
    TrackDetails {
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        visible: root.expanded
        view: root.view
        mode: "artwork"
    }
}
