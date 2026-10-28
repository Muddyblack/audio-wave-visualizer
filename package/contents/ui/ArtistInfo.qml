import QtQuick
import "studio/Translations.js" as Translations
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import "text"

ColumnLayout {
    id: root
    objectName: "artistInfo"
    required property var view
    property bool expanded: true
    spacing: 8
    Controls.Button {
        Layout.fillWidth: true
        text: (root.expanded ? "▾  " : "▸  ") + (typeof i18n === "function" ? i18n("Song details & credits") : Translations.translate("Song details & credits"))
        onClicked: root.expanded = !root.expanded
    }
    Text {
        Layout.fillWidth: true
        visible: root.expanded && !(root.view.configuration?.onlineTrackInfo ?? false)
        text: (typeof i18n === "function" ? i18n("Online information is off. Enable it in Settings → Track info for catalog details and credits.") : Translations.translate("Online information is off. Enable it in Settings → Track info for catalog details and credits."))
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        font.pixelSize: SystemText.px(11)
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
