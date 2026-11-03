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
    function test_wideCoverCropsByDefault() {
        art.artUrl = Qt.resolvedUrl("fixtures/cover-red-blue.ppm");
        tryVerify(() => art.coverReady);
        verify(!art.letterbox, "Whole-cover fitting is opt-in");
        art.artUrl = "";
    }
    function test_wideFormatSetsRatio() {
        compare(art.ratio, 1);
        art.view = {
            configuration: {
                artFormat: "wide"
            }
        };
        compare(art.ratio, 16 / 9);
        art.view = {
            configuration: {
                artFormat: "wide",
                artShape: "circle"
            }
        };
        compare(art.ratio, 1);
        art.view = {
            configuration: {
                artFormat: "wide",
                artShape: "vinyl"
            }
        };
        compare(art.ratio, 1);
        art.view = null;
    }
    function test_edgesFillTheBands() {
        art.view = {
            configuration: {
                artFormat: "squareEdges"
            }
        };
        art.artUrl = Qt.resolvedUrl("fixtures/cover-red-blue.ppm");
        tryVerify(() => art.coverReady && art.letterbox && art.edges);
        // The stretched edge row is only darkened by a quarter (255 -> ~191).
        tryVerify(() => topRed() > 150 && topRed() < 235, 3000, "Bands carry the darkened edge colour");
        art.artUrl = "";
        art.view = null;
    }
    function test_autoOnlyFitsNonSquareArt() {
        art.view = {
            configuration: {
                artFormat: "auto"
            }
        };
        art.artUrl = Qt.resolvedUrl("fixtures/cover-white.ppm");
        tryVerify(() => art.coverReady);
        verify(!art.letterbox, "Square art stays cropped");
        compare(art.ratio, 1);
        art.artUrl = Qt.resolvedUrl("fixtures/cover-red-blue.ppm");
        tryVerify(() => art.ratio > 1.7, 3000, "Wide art switches the cover box to 16:9");
        verify(!art.letterbox, "No padded bands once the box is wide");
        art.artUrl = "";
        art.view = null;
    }
    function test_wideCoverIsShownWhole() {
        art.view = {
            configuration: {
                artFormat: "squareWhole"
            }
        };
        // A 2:1 cover fits its middle band over a dimmed, cropped copy.
        art.artUrl = Qt.resolvedUrl("fixtures/cover-red-blue.ppm");
        tryVerify(() => art.coverReady && art.letterbox);
        tryVerify(() => topRed() > 60 && topRed() < 160, 3000, "Bands above a wide cover are dimmed");
        // Square artwork keeps the full-bleed crop.
        art.artUrl = Qt.resolvedUrl("fixtures/cover-white.ppm");
        tryVerify(() => art.coverReady && !art.letterbox);
        tryVerify(() => topRed() > 200, 3000, "Square covers are not dimmed");
        art.artUrl = "";
        art.view = null;
    }
    function test_stretchKeepsTheWholeImage() {
        art.view = {
            configuration: {
                artFormat: "squareStretch"
            }
        };
        // The fixture is three red columns and one blue one. Cropped, the
        // square shows only red; stretched, the blue quarter reaches the
        // right edge and nothing is dimmed.
        art.artUrl = Qt.resolvedUrl("fixtures/cover-red-blue.ppm");
        tryVerify(() => art.coverReady && art.stretched);
        verify(!art.letterbox);
        compare(art.ratio, 1);
        tryVerify(() => grabImage(this).blue(74, 40) > 200 && grabImage(this).red(74, 40) < 60, 3000, "Blue quarter on the right");
        tryVerify(() => grabImage(this).red(10, 40) > 200, 3000, "Red, undimmed, on the left");
        art.artUrl = Qt.resolvedUrl("fixtures/cover-white.ppm");
        tryVerify(() => art.coverReady && !art.stretched, 3000, "Square art is left alone");
        art.artUrl = "";
        art.view = null;
    }
}
