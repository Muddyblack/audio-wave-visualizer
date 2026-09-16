import QtQuick
import "../code/WaveMotion.js" as Motion

// Bounded state shared by the GPU and software renderers. Nothing here owns a
// timer: one audio timestamp advances peaks, particles and ripples exactly once.
QtObject {
    id: motion
    property bool active: false
    property bool reducedMotion: false
    property int style: 0
    property real frameTime: 0
    property var bars: []
    property int numBars: 24
    property real maxRange: 1000
    property real width: 0
    property real height: 0
    property real lineWidth: 1.8
    property bool attack: false
    property real energy: 1
    property int randomSeed: 1
    property var _previousLevels: []
    property real beatPulse: 0
    property var peaks: []
    property var particles: []
    property var ripples: []
    property real _lastFrame: -1
    property int _seed: randomSeed
    property bool _destroying: false
    Component.onDestruction: _destroying = true

    function reset() {
        Motion.reset(motion);
    }
    function advance() {
        Motion.advance(motion);
    }

    onFrameTimeChanged: advance()
    onStyleChanged: reset()
    onRandomSeedChanged: reset()
    onNumBarsChanged: reset()
    onWidthChanged: reset()
    onHeightChanged: reset()
    onReducedMotionChanged: reset()
    onActiveChanged: {
        reset();
        if (active)
            // bars/hasAudio are published before the timestamp. Let the whole
            // audio frame arrive so waking cannot advance twice at stale time.
            Qt.callLater(advance);
    }
}
