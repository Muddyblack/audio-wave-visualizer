import QtQuick

// Sample tracks for the settings previews; no connection to real playback.
QtObject {
    readonly property var tracks: ["Slow Tide", "Evening Light", "Homeward"]
    property int trackIndex: 0
    readonly property string sampleTrack: tracks[trackIndex]
    property string track: sampleTrack
    property string artist: "Wren & Hollow"
    property string album: "Low Light"
    property string identity: "Music"
    property string artUrl: Qt.resolvedUrl("../../../icon.png").toString()
    property string desktopEntry: ""
    property real length: 238
    property real position: 91
    property real volume: 0.6
    property bool canSeek: false
    property bool shuffle: false
    property int loopState: 0
    property var metadata: ({
            "xesam:genre": ["Ambient"],
            "xesam:trackNumber": 4 + trackIndex,
            "xesam:contentCreated": "2024"
        })
    function previous() {
        trackIndex = (trackIndex + tracks.length - 1) % tracks.length;
        position = 0;
    }
    function next() {
        trackIndex = (trackIndex + 1) % tracks.length;
        position = 0;
    }
    function togglePlaying() {
    }
}
