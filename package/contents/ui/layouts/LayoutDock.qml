import QtQuick
import QtQuick.Layouts
import ".."

TransportDock {
    positionUnitsPerSecond: view.positionUnitsPerSecond
    required property var view
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: 26
    visible: view.hasPlayer
    configuration: view.configuration
    player: view.player
    isPlaying: view.isPlaying
    controlColor: view.controlColor
    accentColor: view.controlsAccent
    cardHovered: view.cardHovered
}
