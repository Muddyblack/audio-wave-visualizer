import QtQuick
import QtTest
import "../package/contents/ui"

TestCase {
    id: testCase
    name: "ArcProgress"
    when: windowShown
    visible: true
    width: 220
    height: 220
    QtObject {
        id: testPlayer
        property real position: 0
        property real length: 200
        property bool canSeek: true
    }
    Component {
        id: ringComponent
        ArcProgress {
            width: 160
            height: 160
            x: 20
            y: 20
            player: testPlayer
            positionUnitsPerSecond: 1
            cornerRadius: 80
        }
    }
    function test_angularDragAndArtworkHitArea() {
        const ring = createTemporaryObject(ringComponent, testCase);
        const area = findChild(ring, "ringSeekArea");
        verify(ring.circularDial);
        verify(!ring.onBand(80, 80), "Centre clicks belong to the artwork");
        verify(!ring.onBand(0, 0), "Circular corners do not steal artwork clicks");
        mousePress(area, 83, 3);
        mouseMove(area, 162, 83);
        fuzzyCompare(ring.progress, .25, .01);
        mouseMove(area, 83, 162);
        mouseRelease(area, 83, 162);
        fuzzyCompare(testPlayer.position, 100, .1);
        verify(findChild(ring, "arcPlayhead").visible);
        testPlayer.canSeek = false;
        verify(!ring.seekAt(0, 80));
        testPlayer.canSeek = true;
    }
}
