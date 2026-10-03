import QtQuick
import QtTest
import "../package/contents/ui"
import "../package/contents/code/Layouts.js" as Layouts

TestCase {
    name: "PanelPresentation"
    PanelPresentation {
        id: placement
        cardConfiguration: ({
                layoutMode: "classic",
                showMpris: true
            })
        pillConfiguration: ({
                layoutMode: "pill",
                pillMaxWidth: 300
            })
    }
    function init() {
        placement.displayMode = "adaptive";
        placement.orientation = "normal";
        placement.rightEdge = false;
        placement.vertical = true;
        placement.cardConfiguration = {
            layoutMode: "classic",
            showMpris: true
        };
        placement.availableSize = Qt.size(400, 500);
    }
    function test_roomySidePanelShowsEveryCardThatFits_data() {
        return Layouts.MODES.filter(mode => !["pill", "pillicon"].includes(mode)).map(mode => ({
                    tag: mode,
                    mode
                }));
    }
    function test_roomySidePanelShowsEveryCardThatFits(data) {
        placement.cardConfiguration = {
            layoutMode: data.mode,
            showMpris: true
        };
        const size = Layouts.size(placement.cardConfiguration);
        const floor = ["lyrics", "visualizer"].includes(data.mode) ? 1 : 0.8;
        compare(placement.showCard, size[0] * floor <= 400 && size[1] * floor <= 500);
        compare(placement.configuration.layoutMode, placement.showCard ? data.mode : "pillicon");
    }
    function test_requestsCardHeightBeforeReceivingSpace() {
        placement.availableSize = Qt.size(400, 30);
        verify(placement.canRequestCard);
        compare(placement.preferredSize, [360, 104]);
        verify(!placement.showCard);
        placement.availableSize = Qt.size(400, 104);
        verify(placement.showCard);
        compare(placement.preferredSize, [360, 104]);
    }
    function test_horizontalPanelAndResize() {
        placement.vertical = false;
        placement.availableSize = Qt.size(500, 30);
        verify(!placement.showCard);
        compare(placement.configuration.layoutMode, "pill");
        placement.availableSize = Qt.size(500, 120);
        verify(placement.showCard);
        placement.availableSize = Qt.size(300, 120);
        verify(placement.showCard);
        placement.availableSize = Qt.size(287, 120);
        verify(!placement.showCard);
        compare(placement.preferredSize, [360, 104]);
        placement.availableSize = Qt.size(500, 82);
        verify(!placement.showCard);
        placement.cardConfiguration = {
            layoutMode: "lyrics",
            showMpris: true
        };
        placement.availableSize = Qt.size(379, 400);
        verify(!placement.showCard);
    }
    function test_cardModeShowsCardAtAnySize() {
        placement.displayMode = "card";
        placement.availableSize = Qt.size(120, 30);
        verify(placement.showCard);
        compare(placement.preferredSize, [360, 104]);
    }
    function test_alwaysPillPreservesCompactChoice() {
        placement.displayMode = "pill";
        verify(!placement.showCard);
        compare(placement.preferredSize, [30, 30]);
        placement.vertical = false;
        compare(placement.configuration.layoutMode, "pill");
        compare(placement.preferredSize, [300, 30]);
    }
    function test_automaticSidePillDirection() {
        placement.orientation = "auto";
        placement.availableSize = Qt.size(40, 500);
        verify(!placement.showCard);
        compare(placement.configuration.layoutMode, "pill");
        compare(placement.contentRotation, -90);
        compare(placement.preferredSize, [30, 300]);
        placement.rightEdge = true;
        compare(placement.contentRotation, 90);
    }
    function test_rotatedCardFitsNarrowerPanel() {
        placement.orientation = "auto";
        placement.availableSize = Qt.size(120, 500);
        verify(placement.showCard);
        compare(placement.contentRotation, -90);
        compare(placement.preferredSize, [104, 360]);
        placement.availableSize = Qt.size(400, 500);
        verify(placement.showCard);
        compare(placement.contentRotation, 0);
        placement.orientation = "right";
        compare(placement.contentRotation, 90);
        placement.orientation = "left";
        compare(placement.contentRotation, -90);
        placement.orientation = "normal";
        placement.availableSize = Qt.size(40, 500);
        compare(placement.contentRotation, 0);
        compare(placement.configuration.layoutMode, "pillicon");
    }
}
