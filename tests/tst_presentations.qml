import QtQuick
import QtTest
import "../package/contents/code/PresentationSettings.js" as Presentations
import "../hyprland/Configuration.js" as Configuration

TestCase {
    name: "PresentationSettings"
    property var defaults
    function initTestCase() {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../package/contents/config/main.xml"), false);
        request.send();
        defaults = Configuration.defaults(request.responseText);
    }
    function test_onlineConsentStaysShared() {
        const source = Object.assign({}, defaults, {
            onlineTrackInfo: false,
            panelAppearance: JSON.stringify({
                onlineTrackInfo: true
            }),
            popupAppearance: JSON.stringify({
                onlineTrackInfo: true
            })
        });
        compare(Presentations.resolve(source, "panel").onlineTrackInfo, false);
        compare(Presentations.resolve(source, "popup").onlineTrackInfo, false);
        const next = Object.assign(Presentations.resolve(source, "popup"), {
            onlineTrackInfo: true
        });
        const saved = Presentations.edit(source, next, "popup");
        compare(saved.onlineTrackInfo, true);
        verify(JSON.parse(saved.popupAppearance).onlineTrackInfo === undefined);
    }
    function test_upgradeKeepsExistingLooks() {
        const source = Object.assign({}, defaults, {
            bgRadius: 4,
            showBg: false,
            visualizerType: 7
        });
        const popup = Presentations.resolve(source, "popup");
        compare(popup.layoutMode, "classic");
        compare(popup.bgRadius, 14);
        compare(popup.surfaceStyle, "glass");
        compare(popup.visualizerType, 7);
        compare(Presentations.resolve(source, "panel").layoutMode, "pill");
        compare(Presentations.resolve(source, "desktop"), source);
    }
    function test_untouchedPillFollowsPopupLook() {
        const pill = Presentations.resolve(defaults, "panel");
        const popup = Presentations.resolve(defaults, "popup");
        // Every design setting matches the card; only the pill's own layout and
        // arrangement choices may differ.
        const different = Object.keys(popup).filter(key => String(pill[key]) !== String(popup[key]));
        compare(different.filter(key => !key.startsWith("pill") && !["layoutMode", "hoverDetails"].includes(key)), []);
        compare(pill.layoutMode, "pill");
        compare(pill.pillContent, defaults.pillContent);
        const synced = Presentations.syncAppearance(defaults, "popup");
        compare(Presentations.resolve(synced, "panel").surfaceStyle, pill.surfaceStyle);
    }
    function test_independentLooksAndSharedCapture() {
        const popup = Object.assign(Presentations.resolve(defaults, "popup"), {
            layoutMode: "orbit",
            bgRadius: 3,
            showBg: false,
            cardShadow: "none",
            visualizerType: 20
        });
        const first = Presentations.edit(defaults, popup, "popup");
        const pillBefore = Presentations.resolve(first, "panel");
        const pill = Object.assign({}, pillBefore, {
            customColor: "#112233",
            inputSource: "monitor-test",
            pillEq: "wave"
        });
        const saved = Presentations.edit(first, pill, "panel");
        const after = Presentations.resolve(saved, "popup");
        compare(after.layoutMode, "orbit");
        compare(after.bgRadius, 3);
        compare(after.showBg, false);
        compare(after.cardShadow, "none");
        compare(after.visualizerType, 20);
        compare(after.customColor, defaults.customColor);
        compare(after.inputSource, "monitor-test");
        compare(Presentations.resolve(saved, "panel").customColor, "#112233");
        compare(saved.customColor, defaults.customColor, "Desktop appearance stays intact");
        verify(JSON.parse(saved.popupAppearance).panelAppearance === undefined);
    }
    function test_nativeColorValuesRoundTrip() {
        const source = Object.assign({}, defaults, {
            customColor: Qt.rgba(1, 0, 0, 1)
        });
        const next = Object.assign(Presentations.resolve(source, "popup"), {
            customColor: "#112233"
        });
        const saved = Presentations.edit(source, next, "popup");
        compare(Presentations.resolve(saved, "popup").customColor, "#112233");
        compare(Presentations.resolve(saved, "panel").customColor, "#ff0000");
    }
    function test_syncCopiesAppearanceAndKeepsLayoutsAndInteraction() {
        const popup = Object.assign(Presentations.resolve(defaults, "popup"), {
            layoutMode: "orbit",
            customColor: "#123456",
            visualizerType: 15,
            progressBarStyle: -1
        });
        const source = Presentations.edit(defaults, popup, "popup");
        const synced = Presentations.syncAppearance(source, "popup");
        const pill = Presentations.resolve(synced, "panel");
        compare(pill.layoutMode, "pill");
        compare(pill.customColor, "#123456");
        compare(pill.visualizerType, 15);
        compare(pill.pillEq, "wave");
        compare(pill.pillProgress, "off");
        compare(pill.progressBarStyle, -1);
        compare(pill.pillControls, Presentations.resolve(source, "panel").pillControls);
        compare(synced.popupAppearance, source.popupAppearance);
        compare(synced.inputSource, source.inputSource);
        const back = Presentations.syncAppearance(synced, "panel");
        compare(Presentations.resolve(back, "popup").layoutMode, "orbit");
        compare(back.panelAppearance, synced.panelAppearance);
    }
    function test_popupBlurDefaultsOnAndPreservesSavedOff() {
        compare(Presentations.resolve(defaults, "popup").compositorGlass, true);
        compare(Presentations.resolve(defaults, "desktop").compositorGlass, defaults.compositorGlass);
        const popup = Object.assign(Presentations.resolve(defaults, "popup"), {
            compositorGlass: false
        });
        const saved = Presentations.edit(defaults, popup, "popup");
        compare(Presentations.resolve(saved, "popup").compositorGlass, false);
        const editedPanel = Presentations.edit(saved, Presentations.resolve(saved, "panel"), "panel");
        compare(Presentations.resolve(editedPanel, "popup").compositorGlass, false);
    }
    function test_invalidStoredSettingsFallBack() {
        const source = Object.assign({}, defaults, {
            popupAppearance: '{"layoutMode":"pill","bgRadius":"bad","inputSource":"wrong"}'
        });
        const popup = Presentations.resolve(source, "popup");
        compare(popup.layoutMode, "classic");
        compare(popup.bgRadius, 14);
        compare(popup.inputSource, defaults.inputSource);
        source.popupAppearance = "broken JSON";
        compare(Presentations.resolve(source, "popup").layoutMode, "classic");
    }
    function test_desktopPresetCannotErasePanelDesigns() {
        const source = Presentations.edit(defaults, Object.assign({}, defaults, {
            layoutMode: "hero"
        }), "popup");
        const next = Presentations.edit(source, defaults, "desktop");
        compare(next.popupAppearance, source.popupAppearance);
        compare(next.panelAppearance, source.panelAppearance);
    }
}
