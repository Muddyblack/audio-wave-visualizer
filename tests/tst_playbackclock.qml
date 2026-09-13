import QtQuick
import QtTest
import "../package/contents/ui"

TestCase {
    name: "PlaybackClock"
    when: windowShown

    Component {
        id: playerComponent
        QtObject {
            property real length: 180000000
            property real position: 10000000
        }
    }
    Component {
        id: clockComponent
        PlaybackClock {
            active: false
        }
    }
    property var player
    property var subject

    SignalSpy {
        id: positionSpy
        target: subject
        signalName: "displayedPositionChanged"
    }
    SignalSpy {
        id: secondsSpy
        target: subject
        signalName: "elapsedSecondsChanged"
    }

    function init() {
        player = createTemporaryObject(playerComponent, this);
        subject = createTemporaryObject(clockComponent, this, {
            player: player,
            playing: true
        });
        verify(subject !== null);
        positionSpy.clear();
        secondsSpy.clear();
    }

    function test_hiddenStopsAndCatchesUp() {
        verify(!subject.ticking);
        wait(170);
        compare(positionSpy.count, 0, "Hidden progress must not run a timer");
        subject.anchorMs = Date.now() - 2000;
        subject.active = true;
        verify(subject.displayedPosition >= 12000000);
        verify(subject.ticking);
        tryVerify(() => positionSpy.count > 1);
        subject.active = false;
        positionSpy.clear();
        wait(170);
        compare(positionSpy.count, 0);
    }

    function test_pauseAndResume() {
        subject.active = true;
        subject.playing = false;
        compare(subject.displayedPosition, player.position);
        verify(!subject.ticking);
        positionSpy.clear();
        wait(170);
        compare(positionSpy.count, 0);
        player.position = 30000000;
        compare(subject.displayedPosition, 30000000);
        subject.playing = true;
        verify(subject.ticking);
    }

    function test_signalsUpdateLengthAndSeek() {
        player.length = 240000000;
        compare(subject.lengthValue, 240000000);
        player.length = 0;
        compare(subject.lengthValue, 240000000, "Transient empty metadata keeps the valid length");
        player.length = 240000000;
        player.position = 90000000;
        compare(subject.displayedPosition, 90000000);
        subject.setPosition(120000000);
        compare(subject.progress, 0.5);
        compare(subject.elapsedText, "2:00");
    }

    function test_noLengthOrPlayerDoesNotTick() {
        subject.player = null;
        subject.active = true;
        compare(subject.progress, 0);
        verify(!subject.ticking);
        player.length = 0;
        subject.player = player;
        verify(!subject.ticking);
        player.length = 180000000;
        verify(subject.ticking);
    }

    function test_endStopsAndBackwardSeekRestarts() {
        subject.active = true;
        subject.setPosition(subject.lengthValue);
        verify(!subject.ticking);
        // Even a small backwards seek must restart a clock stopped at the end.
        player.position = subject.lengthValue - 500000;
        verify(subject.ticking);
        subject.anchorMs = Date.now() - 2000;
        subject.tick();
        compare(subject.progress, 1);
        verify(!subject.ticking);
    }

    function test_labelsOnlyChangeAtWholeSeconds() {
        subject.setPosition(10100000);
        subject.setPosition(10500000);
        subject.setPosition(10900000);
        compare(secondsSpy.count, 0);
        compare(subject.elapsedText, "0:10");
        subject.setPosition(11000000);
        compare(secondsSpy.count, 1);
        compare(subject.elapsedText, "0:11");
        compare(subject.totalText, "3:00");
    }

    function test_playerReplacementResynchronizes() {
        const replacement = createTemporaryObject(playerComponent, this, {
            position: 40000000
        });
        subject.player = replacement;
        compare(subject.displayedPosition, 40000000);
        const unknownLength = createTemporaryObject(playerComponent, this, {
            length: 0
        });
        subject.player = unknownLength;
        compare(subject.lengthValue, 0);
        verify(!subject.ticking);
        subject.player = null;
        compare(subject.displayedPosition, 0);
        compare(subject.lengthValue, 0);
    }
}
