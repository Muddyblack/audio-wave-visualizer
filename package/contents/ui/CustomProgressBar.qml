import QtQuick

CustomStyleLoader {
    id: root
    required property var progressView
    required property var playbackClock
    interfaceName: "progressBar"
    loaderName: "customProgressBarLoader"

    // Use the same playback clock and seek adapter as the built-in bars.
    interfaceObject: QtObject {
        readonly property int apiVersion: 1
        readonly property bool isPlaying: root.progressView.isPlaying
        readonly property bool hasAudio: root.progressView.hasAudio
        readonly property bool active: root.visible && root.progressView.playbackActive
        readonly property bool canSeek: {
            const p = root.progressView.player;
            return !!p && p.canControl !== false && p.canSeek !== false && p.positionSupported !== false && root.playbackClock.lengthValue > 0;
        }
        readonly property real progress: root.playbackClock.progress
        readonly property real position: root.playbackClock.displayedPosition / root.playbackClock.unitsPerSecond
        readonly property real duration: root.playbackClock.lengthValue / root.playbackClock.unitsPerSecond
        readonly property string elapsedText: root.playbackClock.elapsedText
        readonly property string totalText: root.playbackClock.totalText
        readonly property string remainingText: root.playbackClock.remainingText
        readonly property string timeFormat: root.progressView.timeFormat
        readonly property bool showTimes: root.progressView.showTimes
        readonly property bool centerTimes: root.progressView.centerTimes
        readonly property bool reducedMotion: root.progressView.reducedMotion
        readonly property real frameTimeMs: root.progressView.visualFrameTime
        readonly property color textColor: root.progressView.textColor
        readonly property color startColor: root.progressView.pgStartColor
        readonly property color endColor: root.progressView.pgEndColor
        readonly property color waveColor: root.progressView.waveColor
        readonly property string track: root.progressView.track
        readonly property string artist: root.progressView.artist

        function seekToFraction(fraction) {
            return root.playbackClock.seekToFraction(fraction);
        }
    }
}
