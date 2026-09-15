import QtQuick
import QtQuick.Layouts
import ".."

TransportDock {
    required property var view
    Layout.preferredWidth: 88
    Layout.preferredHeight: 26
    visible: view.hasPlayer
    configuration: view.configuration
    player: view.player
    isPlaying: view.isPlaying
    controlColor: view.controlColor
}
