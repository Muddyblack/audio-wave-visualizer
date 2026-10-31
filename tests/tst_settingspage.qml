import QtQuick
import QtTest
import "../hyprland"
import "../hyprland/Configuration.js" as Configuration

TestCase {
    name: "HyprlandSettingsPage"
    when: windowShown
    visible: true
    width: 560
    height: 720
    SettingsPage {
        id: page
        anchors.fill: parent
        screenNames: ["DP-1", "HDMI-A-1"]
    }
    SignalSpy {
        id: applied
        target: page
        signalName: "apply"
    }
    SignalSpy {
        id: closed
        target: page
        signalName: "close"
    }
    function initTestCase() {
        failOnWarning(/undefined|TypeError|ReferenceError|Binding loop/);
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../package/contents/config/main.xml"), false);
        request.send();
        const shipped = Configuration.defaults(request.responseText);
        page.defaults = shipped;
        page.draft = Object.assign({}, shipped, {
            liveApply: false,
            widgetWidth: 360,
            widgetHeight: 104,
            verticalPosition: 0.6,
            monitor: "",
            desktopLayer: true,
            pauseWhenCovered: true,
            waveColor: "#b4befe",
            textColor: "#cdd6f4"
        });
        page.savedDraft = page.draft;
    }
    function test_discardKeepsSettingsOpen() {
        applied.clear();
        closed.clear();
        page.savedDraft = Object.assign({}, page.draft, {
            sensitivity: 130,
            detailFields: ["player", "album"]
        });
        page.draft = Object.assign({}, page.savedDraft);
        const button = findChild(page, "discardSettings");
        verify(button !== null);
        verify(button.visible);
        verify(!button.enabled);
        page.setValue("sensitivity", 175);
        page.setValue("detailFields", ["title"]);
        verify(button.enabled);
        mouseClick(button);
        compare(page.draft.sensitivity, 130);
        compare(page.draft.detailFields, ["player", "album"]);
        verify(!button.enabled);
        compare(applied.count, 0);
        compare(closed.count, 0);
    }

    function test_draftChangesRequireApplyAndButtonsWork() {
        page.setValue("monitor", "all");
        page.setValue("sensitivity", 175);
        page.setValue("detailFields", ["player", "album"]);
        page.setValue("layoutMode", "poster");
        compare(applied.count, 0);
        mouseClick(findChild(page, "applySettings"));
        compare(applied.count, 1);
        compare(applied.signalArguments[0][0].monitor, "all");
        compare(applied.signalArguments[0][0].sensitivity, 175);
        compare(applied.signalArguments[0][0].detailFields, ["player", "album"]);
        compare(applied.signalArguments[0][0].layoutMode, "poster");
        page.setValue("language", "de");
        mouseClick(findChild(page, "resetToDefaults"));
        compare(page.draft.sensitivity, page.defaults.sensitivity);
        compare(page.draft.language, "de", "Defaults keeps the language");
        compare(applied.count, 1, "Defaults edits the draft until Apply");
        page.setValue("language", "");
        page.setValue("sensitivity", 111);
        mouseClick(findChild(page, "closeSettings"));
        compare(closed.count, 0, "Unsaved changes ask first");
        const prompt = findChild(page, "closePrompt");
        verify(prompt.visible);
        mouseClick(findChild(page, "promptCancel"));
        verify(!prompt.visible);
        compare(closed.count, 0);
        mouseClick(findChild(page, "closeSettings"));
        verify(prompt.visible);
        applied.clear();
        mouseClick(findChild(page, "promptApply"));
        compare(applied.count, 1);
        compare(applied.signalArguments[0][0].sensitivity, 111);
        compare(closed.count, 1);
        page.savedDraft = page.draft;
        mouseClick(findChild(page, "closeSettings"));
        verify(!prompt.visible, "Nothing unsaved closes straight away");
        compare(closed.count, 2);
        page.setValue("sensitivity", 112);
        mouseClick(findChild(page, "closeSettings"));
        mouseClick(findChild(page, "promptDiscard"));
        compare(closed.count, 3);
        page.draft = Object.assign({}, page.savedDraft);
    }
    function test_previewAccentIsIncludedWhenApplied() {
        applied.clear();
        page.setValue("useSystemAccent", true);
        page.setValue("accentFromArt", true);
        page.setValue("vizColorMode", "solid");
        verify(waitForRendering(page));
        const swatch = findChild(page, "previewAccent_f5b26b");
        verify(swatch !== null);
        mouseClick(swatch);
        compare(page.draft.customColor, "#f5b26b");
        compare(page.draft.useSystemAccent, false);
        compare(page.draft.accentFromArt, false);
        compare(applied.count, 0, "Choosing an accent edits the draft until Apply");
        compare(swatch.border.width, 2);
        const preview = findChild(page, "previewWidget");
        verify(Qt.colorEqual(preview.waveColor, "#f5b26b"));
        mouseClick(findChild(page, "applySettings"));
        compare(applied.count, 1);
        const saved = applied.signalArguments[0][0];
        compare(saved.customColor, "#f5b26b");
        compare(saved.useSystemAccent, false);
        compare(saved.accentFromArt, false);
        page.setValue("useSystemAccent", true);
        compare(swatch.border.width, 0, "The indicator follows the configured source");
    }

    function test_tabsSwitchSections() {
        compare(page.currentTabIndex, 0);
        const tab1 = findChild(page, "presetView_mine");
        verify(tab1 !== null);
        mouseClick(tab1);
        compare(page.currentTabIndex, 1);

        const tab3 = findChild(page, "mainTab_appearance");
        verify(tab3 !== null);
        mouseClick(tab3);
        compare(page.currentTabIndex, 2);

        const buttonsTab = findChild(page, "subTab_buttons");
        verify(buttonsTab !== null);
        mouseClick(buttonsTab);
        compare(page.currentTabIndex, 4);

        const tab0 = findChild(page, "mainTab_presets");
        verify(tab0 !== null);
        mouseClick(tab0);
        compare(page.currentTabIndex, 0);
    }
}
