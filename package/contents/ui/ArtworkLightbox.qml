import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls

// A separate transient window lets even a small panel icon show a useful cover.
Window {
    id: lightbox
    required property var view
    objectName: "artZoom"
    transientParent: view.Window.window
    flags: Qt.Tool
    color: "#111416"
    title: view.displayTrack
    width: Math.min(460, Screen.desktopAvailableWidth > 0 ? Screen.desktopAvailableWidth - 40 : 460)
    height: Math.min(560, Screen.desktopAvailableHeight > 0 ? Screen.desktopAvailableHeight - 60 : 560)
    visible: view.zoomOpen && view.visible && view.shouldShow
    onClosing: view.zoomOpen = false

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: lightbox.view.zoomOpen = false
        MouseArea {
            objectName: "artZoomArea"
            anchors.fill: parent
            onClicked: lightbox.view.zoomOpen = false
        }
        Controls.ScrollView {
            id: scroll
            anchors.fill: parent
            anchors.margins: 24
            anchors.topMargin: 40
            clip: true
            contentWidth: availableWidth
            ColumnLayout {
                spacing: 14
                width: scroll.availableWidth
                ArtView {
                    objectName: "zoomArt"
                    Layout.preferredWidth: Math.max(0, Math.min(lightbox.width - 48, lightbox.height - 250))
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment: Qt.AlignHCenter
                    artUrl: lightbox.view.artUrl
                    desktopEntry: lightbox.view.desktopEntry
                    fallbackIcon: lightbox.view.fallbackIcon
                }
                Text {
                    Layout.fillWidth: true
                    textFormat: Text.PlainText
                    text: lightbox.view.displayTrack
                    color: "#eff0f1"
                    font.pixelSize: 16
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    textFormat: Text.PlainText
                    text: lightbox.view.artist
                    color: "#aeb7bc"
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                FormatBadges {
                    Layout.fillWidth: true
                    badges: lightbox.view.formatBadges ?? []
                }
                PlayQueue {
                    Layout.fillWidth: true
                    view: lightbox.view
                }
                ArtistInfo {
                    Layout.fillWidth: true
                    view: lightbox.view
                }
            }
        }
        Controls.ToolButton {
            anchors.top: parent.top
            anchors.right: parent.right
            text: "×"
            Accessible.name: qsTr("Close artwork")
            onClicked: lightbox.view.zoomOpen = false
        }
    }
}
