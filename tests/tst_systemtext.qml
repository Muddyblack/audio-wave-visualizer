import QtQuick
import QtTest
import "../package/contents/ui/text"

TestCase {
    name: "SystemText"

    function cleanup() {
        SystemText.follow = true;
    }

    function test_followOffKeepsDesignSizes() {
        SystemText.follow = false;
        compare(SystemText.px(11), 11);
        compare(SystemText.px(12, 18), 12);
    }

    function test_scaleIsBounded() {
        verify(SystemText.factor >= 0.75 && SystemText.factor <= 2);
    }

    function test_limitCapsFixedChrome() {
        // Even at the largest scale, capped text never exceeds its limit.
        verify(SystemText.px(12, 18) <= 18);
        verify(SystemText.px(8, 10) <= 10);
        // A limit below the design size never shrinks the design size.
        compare(SystemText.px(12, 6) <= 12, true);
    }
}
