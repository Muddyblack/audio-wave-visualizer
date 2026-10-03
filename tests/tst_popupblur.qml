import QtQuick
import QtTest
import org.kde.plasma.core as PlasmaCore
import "../package/contents/ui"

TestCase {
    name: "PopupBlur"
    when: windowShown
    visible: true
    width: 400
    height: 200
    PlasmaCore.Dialog {
        id: popup
        backgroundHints: blur.ready ? PlasmaCore.Dialog.StandardBackground : PlasmaCore.Dialog.NoBackground
        location: PlasmaCore.Types.Floating
        mainItem: Rectangle {
            width: 384
            height: 128
            color: "transparent"
        }
    }
    PopupBlur {
        id: blur
        dialog: popup
        enabledBlur: true
        maskPath: Qt.resolvedUrl("fixtures/popup-blur-mask.svg").toString().replace(/^file:\/\//, "")
    }
    function test_maskWithoutThemePaintOrMargins() {
        failOnWarning(/TypeError|ReferenceError|Binding loop/);
        tryCompare(blur, "ready", true);
        popup.visible = true;
        wait(100);
        compare(blur.frame.opacity, 0);
        compare(blur.frame.enabledBorders, 0);
        compare(blur.frame.imagePath, blur.maskPath);
        compare(blur.frame.fixedMargins.left, 0);
        compare(popup.width, 384);
        compare(popup.height, 128);
        const pixels = grabImage(popup.contentItem);
        compare(pixels.alpha(192, 64), 0, "Native frame must not paint over the custom card");
        // QRegion is opaque in QML, but its diagnostic representation includes
        // exact bounds. The compositor must exclude the 12px transparent margin.
        verify(String(blur.frame.mask).includes("12,12 360x104"), String(blur.frame.mask));
        for (let i = 0; i < 10; ++i) {
            popup.visible = false;
            popup.visible = true;
            blur.refresh();
            compare(blur.frame.imagePath, blur.maskPath);
            compare(blur.frame.opacity, 0);
        }
        blur.enabledBlur = false;
        compare(popup.backgroundHints, PlasmaCore.Dialog.NoBackground);
        blur.enabledBlur = true;
        tryCompare(popup, "backgroundHints", PlasmaCore.Dialog.StandardBackground);
        compare(blur.frame.imagePath, blur.maskPath);
        popup.visible = false;
    }
}
