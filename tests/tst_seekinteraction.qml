import QtQuick
import QtTest
import "../package/contents/ui"

TestCase {
    id: testCase
    name: "SeekInteraction"
    when: windowShown
    visible: true
    width: 500
    height: 350
    QtObject {
        id: testPlayer
        property real length: 200
        property real position: 50
        property bool canSeek: true
        property bool canControl: true
    }
    Component {
        id: progressComponent
        ProgressBar {
            width: 300
            y: 90
            player: testPlayer
            positionUnitsPerSecond: 1
            showTimes: false
            track: "first"
        }
    }
    property var bar
    property var area
    property var interaction
    property var clock
    function init() {
        testPlayer.canSeek = true;
        testPlayer.position = 50;
        bar = createTemporaryObject(progressComponent, testCase);
        verify(bar);
        area = findChild(bar, "pbArea");
        interaction = area.parent;
        clock = findChild(bar, "positionClock");
        failOnWarning(/TypeError|ReferenceError|Binding loop/);
    }
    function test_hoverNeverSeeksAndShowsTimeDelta() {
        mouseMove(area, 150, 5);
        compare(testPlayer.position, 50);
        verify(findChild(bar, "ghostPlayhead").visible);
        compare(interaction.targetSeconds, 100);
        verify(interaction.hoverText.indexOf("1:40") >= 0);
        verify(interaction.hoverText.indexOf("+0:50") >= 0);
    }
    function test_doubleClickJumpsFromCurrentPosition() {
        mouseDoubleClickSequence(area, 275, 5, Qt.LeftButton);
        tryCompare(testPlayer, "position", 60);
        wait(450);
        compare(testPlayer.position, 60, "The pending single click must not fire after a double click");
        mouseDoubleClickSequence(area, 20, 5, Qt.LeftButton);
        tryCompare(testPlayer, "position", 50);
    }
    function test_singleClickAndWheelClamp() {
        mouseClick(area, 75, 5);
        tryCompare(testPlayer, "position", 50);
        mouseClick(area, 150, 5);
        compare(testPlayer.position, 100);
        mouseWheel(area, 150, 5, 0, 120);
        compare(testPlayer.position, 105);
        bar.wheelSeekSeconds = 2;
        mouseWheel(area, 150, 5, 0, -120);
        compare(testPlayer.position, 103);
        clock.seekRelative(1000);
        compare(testPlayer.position, 200);
        clock.seekRelative(-1000);
        compare(testPlayer.position, 0);
        testPlayer.canSeek = false;
        verify(!clock.seekRelative(5));
        compare(testPlayer.position, 0);
    }
    function test_fineScrubIncrementsAndCommit() {
        mousePress(area, 150, 5);
        mouseMove(area, 180, 105);
        compare(interaction.speed, .25);
        fuzzyCompare(interaction.fraction, .525, .001);
        compare(testPlayer.position, 50, "Dragging previews before committing");
        mouseRelease(area, 180, 105);
        fuzzyCompare(testPlayer.position, 105, .2);
        wait(450);
        fuzzyCompare(testPlayer.position, 105, .2);
    }
    function test_trackChangeCancelsPendingClickAndLoop() {
        mouseClick(area, 280, 5);
        clock.loopStart = .1;
        clock.loopEnd = .2;
        clock.loopEnabled = true;
        bar.track = "second";
        compare(clock.loopEnabled, false);
        compare(clock.loopStart, -1);
        wait(450);
        compare(testPlayer.position, 50);
    }
    function test_loopRewindsOnlyWhenPlayingAndActive() {
        clock.loopStart = .1;
        clock.loopEnd = .3;
        clock.loopEnabled = true;
        clock.setPosition(65);
        clock.checkLoop();
        compare(testPlayer.position, 50);
        bar.isPlaying = true;
        clock.setPosition(65);
        clock.checkLoop();
        compare(testPlayer.position, 20);
        testPlayer.position = 65;
        clock.checkLoop();
        compare(testPlayer.position, 65, "A delayed acknowledgement cannot cause a seek storm");
        clock._lastLoopSeek = 0;
        clock.active = false;
        clock.checkLoop();
        compare(testPlayer.position, 65);
    }
    function test_chaptersSnapButDraggingRemainsPrecise() {
        bar.chapters = [
            {
                start: 0,
                title: "Intro"
            },
            {
                start: 80,
                title: "Drop"
            }
        ];
        mouseMove(area, 150, 5);
        compare(interaction.chapterTitle, "Drop");
        mouseClick(area, 150, 5);
        compare(testPlayer.position, 80);
    }
    function test_realPeaksReplaceSyntheticHeights() {
        bar.style = 4;
        const canvas = findChild(bar, "waveformSeek");
        tryVerify(() => canvas.numBars > 0);
        verify(canvas.barHeights.every(v => v === 0));
        bar.peaks = Array.from({
            length: 128
        }, (_, i) => i < 64 ? .1 : 1);
        tryVerify(() => canvas.barHeights[0] === .1);
        compare(canvas.barHeights[canvas.barHeights.length - 1], 1);
        bar.peaks = [];
        verify(canvas.barHeights.every(v => v === 0));
    }
    function test_waveformGeometryDoesNotChangeAtPlayhead() {
        bar.style = 4;
        bar.peaks = Array(128).fill(.8);
        const canvas = findChild(bar, "waveformSeek");
        testPlayer.position = 0;
        wait(80);
        const unplayed = grabImage(canvas);
        testPlayer.position = testPlayer.length;
        wait(80);
        const played = grabImage(canvas);
        let before = 0, after = 0;
        for (let y = 0; y < canvas.height; y++) {
            if (unplayed.alpha(1, y) > 30)
                before++;
            if (played.alpha(1, y) > 30)
                after++;
        }
        verify(before > 5);
        compare(after, before, "The playhead must not alter the displayed dynamics");
    }
    function test_pulsesRespectReducedMotion() {
        bar.hasAudio = true;
        bar.bass = .8;
        bar.energyPulse = .5;
        verify(bar.transientPulse > .5);
        bar.reducedMotion = true;
        compare(bar.transientPulse, 0);
    }
}
