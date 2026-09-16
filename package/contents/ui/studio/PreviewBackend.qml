import QtQuick
import "../../code/PreviewAudio.js" as PreviewAudio

// Synthetic audio for settings previews: at most 15 Hz while `running`.
// A stopped backend keeps one still frame for static thumbnails.
Item {
    id: backend
    property bool running: true
    property int numBars: 24
    property real maxRange: 1000
    property var bars: []
    property real frameTimeMs: 0
    property bool hasAudio: true
    property bool backendFailed: false
    property string backendCode: ""
    property string backendMessage: ""
    property string backendAction: ""
    property string backendHint: ""
    property bool plasmoidVisible: true
    property real bass: 0
    property real mid: 0
    property real high: 0
    property bool attack: false
    property var stereoSamples: []
    property var previousStereo: []
    property string stereoStatus: ""

    function frame(now) {
        const t = now / 1000;
        const frame = PreviewAudio.bands(t);
        previousStereo = stereoSamples;
        stereoSamples = PreviewAudio.stereo(t);
        bars = Array.from({
            length: numBars
        }, (_, i) => maxRange * PreviewAudio.spectrum(i, numBars, t));
        frameTimeMs = now;
        bass = frame.bass;
        mid = frame.mid;
        high = frame.high;
        attack = frame.attack;
    }

    Timer {
        interval: 67
        running: backend.running && backend.hasAudio && !backend.backendFailed
        repeat: true
        onTriggered: backend.frame(Date.now())
    }
    Component.onCompleted: frame(2375)
}
