import QtQuick

// The same validated local-QML loader used by visualizers and progress bars.
CustomStyleLoader {
    id: root
    required property var dock
    interfaceName: "buttons"
    loaderName: "customButtonsLoader"

    interfaceObject: QtObject {
        readonly property int apiVersion: 1
        readonly property bool isPlaying: root.dock.isPlaying
        readonly property bool active: root.dock.visible && !root.dock.hiddenUntilHover
        readonly property bool canTogglePlaying: root.dock.canTogglePlaying
        readonly property bool canGoPrevious: root.dock.canGoPrevious
        readonly property bool canGoNext: root.dock.canGoNext
        readonly property bool canShuffle: root.dock.canShuffle
        readonly property bool canRepeat: root.dock.canLoop
        readonly property bool shuffleOn: root.dock.shuffleOn
        readonly property bool repeatOn: root.dock.loopOn
        readonly property bool repeatTrack: root.dock.loopTrack
        readonly property bool showSkipButtons: root.dock.showSkip
        readonly property bool showShuffleRepeat: root.dock.showExtras
        readonly property bool reducedMotion: root.dock.configuration.reducedMotion ?? false
        readonly property color iconColor: root.dock.controlColor
        readonly property color accentColor: root.dock.accentColor

        function previous() {
            return root.dock.previous();
        }
        function togglePlaying() {
            return root.dock.togglePlaying();
        }
        function next() {
            return root.dock.next();
        }
        function toggleShuffle() {
            return root.dock.toggleShuffle();
        }
        function cycleRepeat() {
            return root.dock.cycleLoop();
        }
    }
}
