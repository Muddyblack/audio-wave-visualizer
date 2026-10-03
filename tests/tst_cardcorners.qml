import QtQuick
import QtTest
import "../package/contents/ui" as Shared

TestCase {
    name: "CardCorners"
    when: windowShown
    visible: true
    width: 360
    height: 112
    Rectangle {
        anchors.fill: parent
        color: "black"
    }
    Shared.CardSurface {
        id: card
        anchors.fill: parent
        hasPlayer: true
        artUrl: Qt.resolvedUrl("fixtures/cover-white.ppm")
        configuration: ({
                showMpris: true,
                artBg: true,
                showBg: true,
                bgRadius: 14,
                artBgBlur: 0.5,
                artBgDim: 1,
                artBgTransparency: 1,
                surfaceStyle: "color",
                bgColor: "black"
            })
    }
    function test_dimmedRoundedCoverHasNoBrightCornerRim() {
        if (GraphicsInfo.api === GraphicsInfo.Software)
            skip("The cover alpha mask needs the GPU scene graph");
        tryCompare(findChild(card, "backgroundArtImage"), "status", Image.Ready);
        wait(600);
        const picture = grabImage(card);
        verify(picture.red(180, 56) > 20 && picture.red(180, 56) < 80, "The white cover must be visible and dimmed at the centre");
        for (let y = 0; y < 14; y++) {
            for (let x = 0; x < 14; x++) {
                const brightness = picture.red(x, y) * picture.alpha(x, y) / 255;
                verify(brightness < 100, "Bright cover leaked at " + x + "," + y);
            }
        }
    }
}
