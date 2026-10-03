import QtQuick
import QtTest
import "../package/contents/ui" as Shared

TestCase {
    id: test
    name: "PopupShadow"
    when: windowShown
    visible: true
    width: 384
    height: 136
    Rectangle {
        anchors.fill: parent
        color: "white"
    }
    Shared.CardSurface {
        anchors.fill: parent
        anchors.margins: 12
        effectMargin: 12
        hasPlayer: true
        configuration: ({
                showMpris: true,
                artBg: false,
                showBg: true,
                bgRadius: 14,
                artBgTransparency: 1,
                surfaceStyle: "color",
                bgColor: "black",
                cardShadow: "lifted"
            })
    }
    function test_shadowFadesBeforeWindowEdge() {
        wait(400);
        const picture = grabImage(test);
        verify(picture.red(192, 125) < 250, "The shadow must actually render below the card");
        for (let x = 0; x < width; x++) {
            verify(picture.red(x, 0) >= 253, "Shadow clipped at the top edge");
            verify(picture.red(x, height - 1) >= 253, "Shadow clipped at the bottom edge");
        }
        for (let y = 0; y < height; y++) {
            verify(picture.red(0, y) >= 253, "Shadow clipped at the left edge");
            verify(picture.red(width - 1, y) >= 253, "Shadow clipped at the right edge");
        }
    }
}
