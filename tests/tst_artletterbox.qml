import QtQuick
import QtTest
import "../package/contents/ui" as Shared

TestCase {
    name: "ArtLetterbox"
    visible: true
    when: windowShown
    width: 100
    height: 100
    Rectangle {
        anchors.fill: parent
        color: "#202020"
    }
    Shared.ArtView {
        id: art
        width: 80
        height: 80
    }
    function topRed() {
        return grabImage(this).red(40, 6);
    }
    function test_wideCoverIsShownWhole() {
        // A 2:1 cover fits its middle band over a dimmed, cropped copy.
        art.artUrl = Qt.resolvedUrl("fixtures/cover-red-blue.ppm");
        tryVerify(() => art.coverReady && art.letterbox);
        tryVerify(() => topRed() > 60 && topRed() < 160, 3000, "Bands above a wide cover are dimmed");
        // Square artwork keeps the full-bleed crop.
        art.artUrl = Qt.resolvedUrl("fixtures/cover-white.ppm");
        tryVerify(() => art.coverReady && !art.letterbox);
        tryVerify(() => topRed() > 200, 3000, "Square covers are not dimmed");
        art.artUrl = "";
    }
}
