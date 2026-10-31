import QtQuick
import QtTest
import "../hyprland"
import "../package/contents/ui/studio/Schema.js" as Schema

// Apply instantly must save every change, not only the first after a save.
TestCase {
    name: "HyprlandInstantApply"
    when: windowShown
    visible: true
    width: 560
    height: 720
    SettingsPage {
        id: page
        anchors.fill: parent
        // What the shell does: a save comes back as the new saved settings.
        onApply: next => page.savedDraft = Object.assign({}, next)
    }
    function init() {
        const start = {
            showMpris: true,
            liveApply: true,
            sensitivity: 100,
            layoutMode: "classic"
        };
        page.savedDraft = Object.assign({}, start);
        page.draft = Object.assign({}, start);
        verify(!page.pending);
    }
    function test_everyChangeIsSaved() {
        for (let round = 1; round <= 5; ++round) {
            page.setValue("sensitivity", 100 + round);
            tryVerify(() => page.savedDraft.sensitivity === 100 + round, 1000, "round " + round + " was not saved");
            verify(!page.pending);
        }
    }
    function test_burstSavesTheLastValue() {
        page.setValue("sensitivity", 150);
        page.setValue("layoutMode", "hero");
        page.setValue("sensitivity", 175);
        tryVerify(() => page.savedDraft.sensitivity === 175 && page.savedDraft.layoutMode === "hero", 1000);
        verify(!page.pending);
    }
    function test_resetReturnsToWhenTheWindowOpened() {
        page.openDraft = Object.assign({}, page.draft);
        page.setValue("sensitivity", 150);
        tryVerify(() => page.savedDraft.sensitivity === 150, 1000);
        verify(page.canDiscard);
        mouseClick(findChild(page, "discardSettings"));
        compare(page.draft.sensitivity, 100);
        tryVerify(() => page.savedDraft.sensitivity === 100, 1000);
        verify(!page.canDiscard);
    }
    function test_preferencesSaveEvenWithInstantApplyOff() {
        page.setValue("liveApply", false);
        tryVerify(() => page.savedDraft.liveApply === false, 1000);
        page.setValue("sensitivity", 130);
        page.setValue("language", "de");
        tryVerify(() => page.savedDraft.language === "de", 1000);
        compare(page.savedDraft.sensitivity, 100, "Only the preference was saved");
        mouseClick(findChild(page, "discardSettings"));
        compare(page.draft.sensitivity, 100);
        compare(page.draft.language, "de", "Reset keeps the language");
    }
    function test_presetsAndSurpriseKeepPreferences() {
        const defaults = {
            language: "",
            liveApply: true,
            layoutMode: "classic"
        };
        const current = Object.assign({}, defaults, {
            language: "de",
            liveApply: false
        });
        for (const next of [Schema.surprise(defaults, current), Schema.applyPreset(defaults, current, {}, false), Schema.restoreDefaults(defaults, current)]) {
            compare(next.language, "de");
            compare(next.liveApply, false);
        }
        const saved = Schema.changedKeys(defaults, current);
        verify(saved.language === undefined && saved.liveApply === undefined, "A saved preset carries no preferences");
    }
    function test_closeSavesTheLastEditWithoutAsking() {
        page.setValue("sensitivity", 160);
        page.requestClose();
        compare(page.savedDraft.sensitivity, 160);
        verify(!findChild(page, "closePrompt").visible);
    }
    function test_offWaitsForApply() {
        page.setValue("liveApply", false);
        page.savedDraft = Object.assign({}, page.draft);
        page.setValue("sensitivity", 130);
        wait(400);
        compare(page.savedDraft.sensitivity, 100);
        verify(page.pending);
    }
    function test_turningOnSavesWhatIsWaiting() {
        page.setValue("liveApply", false);
        page.savedDraft = Object.assign({}, page.draft);
        page.setValue("sensitivity", 130);
        page.setValue("liveApply", true);
        tryVerify(() => page.savedDraft.sensitivity === 130, 1000);
    }
}
