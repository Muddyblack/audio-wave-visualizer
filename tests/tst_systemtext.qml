import QtQuick
import QtTest
import "../package/contents/ui/text"

TestCase {
    name: "SystemText"

    property real systemPoints
    function initTestCase() {
        systemPoints = SystemText.points;
    }
    function cleanup() {
        SystemText.follow = true;
        SystemText.points = systemPoints;
    }

    function test_followOffKeepsDesignSizes() {
        SystemText.follow = false;
        compare(SystemText.px(11), 11);
        compare(SystemText.px(12, 18), 12);
    }

    function test_titleMatchesTheSystemFont() {
        // 10 pt is 13.3 logical pixels.
        SystemText.points = 10;
        compare(SystemText.px(11), 13);
        compare(SystemText.px(9), 11, "Artist");
        compare(SystemText.px(8), 10, "Times");
    }

    function test_scaleIsBounded() {
        SystemText.points = 72;
        compare(SystemText.px(11), 14, "Fixed-size cards hold no more");
        SystemText.points = 1;
        compare(SystemText.factor, 0.75);
    }

    function test_pixelSizedFontKeepsDesignSizes() {
        SystemText.points = -1;
        compare(SystemText.factor, 1);
    }

    function test_limitCapsFixedChrome() {
        // Even at the largest scale, capped text never exceeds its limit.
        verify(SystemText.px(12, 18) <= 18);
        verify(SystemText.px(8, 10) <= 10);
        // A limit below the design size never shrinks the design size.
        compare(SystemText.px(12, 6) <= 12, true);
    }
}
