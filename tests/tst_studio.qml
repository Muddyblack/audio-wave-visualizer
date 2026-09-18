import QtQuick
import QtTest
import QtCore
import "../package/contents/ui/studio" as Studio
import "../package/contents/ui/studio/Schema.js" as Schema
import "../hyprland/Configuration.js" as Configuration

TestCase {
    id: testCase
    name: "Studio"
    when: windowShown
    visible: true
    width: 1200
    height: 820
    property var defaults
    readonly property string libraryPath: StandardPaths.writableLocation(StandardPaths.TempLocation) + "/audio-wave-studio-test-" + Date.now() + ".ini"

    Studio.Studio {
        id: studio
        anchors.fill: parent
        libraryPath: testCase.libraryPath
        env: "hypr"
        onEdited: next => draft = next
    }
    Studio.SamplePlayer {
        id: liveArtPlayer
        artUrl: Qt.resolvedUrl("fixtures/cover-red-blue.ppm").toString()
    }

    function tabIndex(id) {
        return Schema.TABS.findIndex(tab => tab.id === id);
    }

    function initTestCase() {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../package/contents/config/main.xml"), false);
        request.send();
        defaults = Object.assign(Configuration.defaults(request.responseText), {
            monitor: "",
            verticalPosition: 0.6,
            hAnchor: "center",
            widgetWidth: 360,
            widgetHeight: 104,
            desktopLayer: true,
            pauseWhenCovered: true
        });
    }
    function init() {
        failOnWarning(/undefined|TypeError|ReferenceError|Binding loop/);
        testCase.width = 1200;
        testCase.height = 820;
        studio.visible = true;
        studio.presetFilter = "all";
        studio.defaults = defaults;
        studio.draft = Object.assign({}, defaults);
        studio.presetLibrary.clear();
        studio.query = "";
        studio.currentTabIndex = 0;
        studio.keepColors = false;
        studio.livePreview = false;
        studio.liveVisualizer = null;
        studio.livePlayer = null;
    }

    function test_navigationStaysAboveScrolledSettings() {
        studio.selectTab("viz");
        verify(waitForRendering(studio));
        const nav = findChild(studio, "appearanceNavigation");
        const before = nav.mapToItem(studio, 0, 0).y;
        const body = findChild(studio, "studioBody");
        body.contentY = 120;
        compare(nav.mapToItem(studio, 0, 0).y, before);
        verify(body.y >= nav.y + nav.height);
    }

    function test_favoritesAndDailyCopiesSurviveApplyingLooks() {
        studio.toggleFavorite("glass");
        studio.saveDaily();
        studio.toggleFavorite(studio.daily.id);
        studio.applyLook(Schema.PRESETS[1].s);
        verify(studio.favorites.indexOf("glass") !== -1);
        verify(studio.favorites.indexOf(studio.daily.id) !== -1);
        studio.saveDaily();
        compare(studio.userPresetList().length, 1);
        studio.removeUserPreset(0);
        verify(studio.favorites.indexOf(studio.daily.id) === -1);
        verify(studio.favorites.indexOf("glass") !== -1);
    }
    function test_legacyWidgetLibraryMovesToSharedStorage() {
        const old = Object.assign({}, defaults, {
            favoritePresets: '["glass"]',
            userPresets: '[{"id":"old-look","name":"Old look","settings":{"titleSize":14}}]'
        });
        studio.draft = old;
        compare(studio.favorites, ["glass"]);
        compare(studio.userPresetList()[0].name, "Old look");
        studio.presetLibrary.setPresets([]);
        studio.draft = Object.assign({}, defaults);
        studio.draft = old;
        compare(studio.userPresetList().length, 0, "Stale widget data must not restore a deleted look");
    }

    function test_presetsKeepPlacementAndOptionallyColours() {
        studio.draft = Object.assign({}, defaults, {
            verticalPosition: 0.3,
            customColor: "#123456",
            useSystemAccent: false,
            titleSize: 15
        });
        studio.applyLook(Schema.PRESETS.find(p => p.id === "glass").s);
        compare(studio.draft.surfaceStyle, "glass");
        compare(studio.draft.showBg, true);
        compare(studio.draft.verticalPosition, 0.3, "Placement is never part of a look");
        compare(studio.draft.titleSize, 11, "Other keys return to the defaults");
        compare(studio.draft.useSystemAccent, true);
        studio.keepColors = true;
        studio.draft = Object.assign({}, studio.draft, {
            useSystemAccent: false,
            customColor: "#123456"
        });
        studio.applyLook(Schema.PRESETS.find(p => p.id === "neon").s);
        compare(studio.draft.customColor, "#123456", "Keep my colours");
        verify(Schema.matchesPreset(defaults, Object.assign({}, defaults), Schema.PRESETS[0]), "Classic is the defaults");
    }

    function test_customStylePickers_data() {
        return [
            {
                tag: "visualizer",
                tab: "viz",
                key: "customVisualizer",
                file: "PulseBars.qml",
                loader: "customVisualizerLoader"
            },
            {
                tag: "progress",
                tab: "controls",
                key: "customProgressBar",
                file: "GradientProgress.qml",
                loader: "customProgressBarLoader"
            },
            {
                tag: "buttons",
                tab: "buttons",
                key: "customButtons",
                file: "MinimalButtons.qml",
                loader: "customButtonsLoader"
            }
        ];
    }
    function test_customStylePickers(data) {
        studio.currentTabIndex = tabIndex(data.tab);
        const picker = findChild(studio, "customStylePicker_" + data.key);
        verify(picker !== null);
        verify(!picker.expanded);
        verify(picker.implicitHeight <= 32, "Unused custom styles should occupy one compact row");
        const url = Qt.resolvedUrl("../package/contents/examples/" + data.file).toString();
        picker.importFile(url);
        compare(studio.draft[data.key], url);
        verify(picker.expanded);
        tryVerify(() => {
            const loader = findChild(picker, data.loader);
            return loader && loader.status === Loader.Ready;
        });
        picker.select("");
        compare(studio.draft[data.key], "");
        compare(picker.library.length, 1);
        picker.select(url);
        picker.removeSelected();
        compare(picker.library.length, 0);
    }

    function test_pickerValuesMapToStoredKeys() {
        const layout = Schema.SECTIONS.find(s => s.title === "Arrangement").rows[0];
        studio.update(Schema.rowPatch(layout, "compact"));
        compare(studio.draft.showMpris, false);
        compare(Schema.rowValue(layout, studio.draft), "compact");
        studio.update(Schema.rowPatch(layout, "hero"));
        compare(studio.draft.showMpris, true);
        compare(studio.draft.layoutMode, "hero");
        const cover = Schema.PRESETS.find(p => p.id === "cover");
        compare(cover.s.artBg, true);
        verify(cover.s.surfaceStyle === undefined);
        compare(Schema.PRESETS.find(p => p.id === "cd").s.detailFields, ["album", "track", "genre", "format"]);
    }

    function test_searchFindsRowsAcrossTabs() {
        studio.query = "bloom";
        waitForRendering(studio);
        const bloom = findChild(studio, "row_bloom");
        verify(bloom !== null && bloom.visible, "Rows from other tabs match");
        compare(findChild(studio, "row_numBars"), null, "Unmatched sections create no rows");
        verify(studio.anyResults);
        studio.query = "zzzz-nothing";
        verify(!studio.anyResults);
        studio.query = "";
    }
    function test_lyricsSettingsAndSavedLook() {
        studio.currentTabIndex = tabIndex("lyrics");
        verify(studio.currentTabIndex >= 0);
        waitForRendering(studio);
        verify(findChild(studio, "row_lyricsMode") !== null);
        const row = Schema.SECTIONS.find(section => section.tab === "lyrics").rows[0];
        studio.update(Schema.rowPatch(row, "full", studio.draft));
        compare(studio.draft.layoutMode, "lyrics");
        verify(studio.draft.showLyrics);
        waitForRendering(studio);
        verify(findChild(studio, "row_lyricsFontSize") !== null);
        studio.update({
            lyricsFontSize: 32,
            lyricsFollow: false,
            lyricsOffset: -1.5
        });
        studio.saveUserPreset("Reading");
        const settings = studio.userPresetList()[0].settings;
        compare(settings.lyricsFontSize, 32);
        compare(settings.lyricsFollow, false);
        compare(settings.lyricsOffset, -1.5);
        compare(Schema.rowPatch(row, "off", {
            layoutMode: "orbit"
        }).layoutMode, "orbit");
    }

    function test_tileAndSwitchUpdateDraft() {
        studio.currentTabIndex = tabIndex("viz");
        waitForRendering(studio);
        const tile = findChild(studio, "tile_visualizerType_7");
        verify(tile !== null);
        mouseClick(tile);
        compare(studio.draft.visualizerType, 7);
        studio.query = "";
        mouseClick(findChild(studio, "subTab_card"));
        compare(studio.currentTabIndex, tabIndex("card"));
        waitForRendering(studio);
        verify(findChild(studio, "row_showBg") !== null);
    }

    function test_userPresetsSaveAndImport() {
        studio.update({
            titleSize: 14,
            verticalPosition: 0.2
        });
        studio.saveUserPreset("Big text");
        const list = studio.userPresetList();
        compare(list.length, 1);
        compare(list[0].name, "Big text");
        compare(list[0].settings.titleSize, 14);
        verify(list[0].settings.verticalPosition === undefined, "Placement is not saved");
        const imported = Schema.importPreset('{"name":"Shared","settings":{"layoutMode":"compact","monitor":"DP-1","bogus":1}}', defaults);
        compare(imported.name, "Shared");
        compare(imported.settings.showMpris, false);
        verify(imported.settings.monitor === undefined && imported.settings.bogus === undefined);
        studio.addUserPreset(imported);
        compare(studio.userPresetList().length, 2);
        studio.removeUserPreset(0);
        compare(studio.userPresetList()[0].name, "Shared");
    }

    function test_glassBlurIsAdjustableAndSaved() {
        studio.currentTabIndex = tabIndex("card");
        studio.update({
            showBg: true,
            artBg: false,
            surfaceStyle: "glass"
        });
        verify(waitForRendering(studio));
        verify(findChild(studio, "row_glassBlur").visible);
        studio.update({
            glassBlur: 0.27
        });
        studio.saveUserPreset("Light frost");
        compare(studio.userPresetList()[0].settings.glassBlur, 0.27);
        studio.update({
            glassBlur: 0
        });
        compare(studio.draft.glassBlur, 0);
        studio.applyLook(studio.userPresetList()[0].settings);
        compare(studio.draft.glassBlur, 0.27);
    }

    function test_glassColourOptionsAreAvailable() {
        studio.selectTab("card");
        studio.update({
            showBg: true,
            artBg: false,
            surfaceStyle: "glass",
            glassTint: "custom"
        });
        verify(waitForRendering(studio));
        verify(findChild(studio, "row_glassTint").visible);
        verify(findChild(studio, "row_glassTintColor").visible);
        studio.update({
            glassTintColor: "#123456"
        });
        studio.saveUserPreset("Blue glass");
        compare(studio.userPresetList()[0].settings.glassTintColor, "#123456");
        studio.update({
            surfaceStyle: "liquid"
        });
        verify(findChild(studio, "row_glassTintColor").visible);
        studio.update({
            surfaceStyle: "solid"
        });
        const customRow = findChild(studio, "row_glassTintColor");
        verify(customRow === null || !customRow.visible);
    }

    function test_renameSavedPreset() {
        studio.saveUserPreset("Original");
        const before = studio.userPresetList()[0];
        studio.currentTabIndex = tabIndex("saved");
        verify(waitForRendering(studio));
        const tile = findChild(studio, "userPreset_0");
        mouseClick(findChild(tile, "renamePresetButton"));
        verify(tile.renaming);
        const input = findChild(tile, "renamePresetInput");
        compare(input.text, "Original");
        input.text = "  Evening glass  ";
        keyClick(Qt.Key_Return);
        const after = studio.userPresetList()[0];
        compare(after.name, "Evening glass");
        compare(after.id, before.id);
        compare(JSON.stringify(after.settings), JSON.stringify(before.settings));
        verify(!studio.renameUserPreset(0, "   "));
        verify(!studio.renameUserPreset(9, "Missing"));
        mouseClick(findChild(tile, "renamePresetButton"));
        input.text = "Discard this";
        keyClick(Qt.Key_Escape);
        compare(studio.userPresetList()[0].name, "Evening glass");
        verify(!tile.renaming);
    }

    function test_allTabsRender_data() {
        return Schema.TABS.map((tab, index) => ({
                    tag: tab.id,
                    index: index
                }));
    }

    function test_allTabsRender(data) {
        studio.currentTabIndex = data.index;
        verify(waitForRendering(studio));
        verify(studio.anyResults);
    }

    function test_shuffleRepeatSettingAndPreview() {
        studio.currentTabIndex = tabIndex("buttons");
        verify(waitForRendering(studio));
        const row = findChild(studio, "row_showShuffleRepeat");
        const body = findChild(studio, "studioBody");
        body.contentY = row.mapToItem(body.contentItem, 0, 0).y - body.height + row.height;
        verify(waitForRendering(studio));
        mouseClick(findChild(studio, "switch_showShuffleRepeat"));
        compare(studio.draft.showShuffleRepeat, true);
        const preview = findChild(studio, "previewWidget");
        verify(waitForRendering(studio));
        mouseClick(findChild(preview, "shuffleArea"));
        compare(preview.player.shuffle, true);
        mouseClick(findChild(preview, "repeatArea"));
        compare(preview.player.loopState, 2);
        mouseClick(findChild(preview, "repeatArea"));
        compare(preview.player.loopState, 1);
        verify(findChild(preview, "repeatAreaBadge").visible);
    }

    function test_wrappedTabsAreReachable_data() {
        return [
            {
                tag: "normal",
                width: 1200
            },
            {
                tag: "narrow",
                width: 440
            }
        ];
    }
    function test_wrappedTabsAreReachable(data) {
        testCase.width = data.width;
        verify(waitForRendering(studio));
        const tabs = findChild(studio, "studioTabs");
        compare(tabs.height, 36, "Main navigation always stays on one line");
        if (data.width === 440) {
            const mainScroller = findChild(studio, "mainTabScroller");
            const nextMain = findChild(studio, "mainTabsForward");
            verify(nextMain.visible, "Overflowed main tabs show a forward control");
            mouseClick(nextMain);
            verify(mainScroller.contentX > 0);
            verify(findChild(studio, "mainTabsBack").visible);
            mainScroller.contentX = 0;
        }
        for (const entry of Schema.MAIN_TABS) {
            const tab = findChild(studio, "mainTab_" + entry.id);
            verify(tab !== null);
            const scroller = findChild(studio, "mainTabScroller");
            scroller.contentX = Math.max(0, Math.min(tab.x, scroller.contentWidth - scroller.width));
            verify(waitForRendering(studio));
            mouseClick(tab);
            compare(studio.currentGroup, entry.id);
        }
        if (data.width === 440) {
            studio.selectTab("presets");
            const presetScroller = findChild(studio, "presetTabScroller");
            const nextPreset = findChild(studio, "presetTabsForward");
            verify(nextPreset.visible, "Overflowed preset tabs show a forward control");
            mouseClick(nextPreset);
            verify(presetScroller.contentX > 0);
            verify(findChild(studio, "presetTabsBack").visible);
        }
        studio.selectTab("viz");
        if (data.width === 440) {
            const appearanceScroller = findChild(studio, "appearanceScroller");
            const nextAppearance = findChild(studio, "appearanceTabsForward");
            verify(nextAppearance.visible, "Overflowed appearance tabs show a forward control");
            mouseClick(nextAppearance);
            verify(appearanceScroller.contentX > 0);
            verify(findChild(studio, "appearanceTabsBack").visible);
            appearanceScroller.contentX = 0;
        }
        for (const id of Schema.APPEARANCE_TABS) {
            const tab = findChild(studio, "subTab_" + id);
            verify(tab !== null);
            const scroller = findChild(studio, "appearanceScroller");
            scroller.contentX = Math.max(0, Math.min(tab.parent.x, scroller.contentWidth - scroller.width));
            verify(waitForRendering(studio));
            mouseClick(tab);
            compare(studio.currentTab, id);
        }
        verify(findChild(studio, "studioBody").y >= tabs.y + tabs.height);
    }

    function test_smallSettingsWindow() {
        testCase.width = 590;
        testCase.height = 448;
        verify(waitForRendering(studio));
        const body = findChild(studio, "studioBody");
        const toggle = findChild(studio, "previewOptionsToggle");
        verify(toggle.visible);
        verify(body.height >= 140, "Small dialogs must leave room for settings below fixed navigation");
        const preview = findChild(studio, "previewWidget");
        verify(preview.scale >= 0.6, "Collapsed options leave a readable live preview");
        const collapsedHeight = body.height;
        mouseClick(toggle);
        verify(waitForRendering(studio));
        verify(body.height < collapsedHeight);
        mouseClick(toggle);
        verify(waitForRendering(studio));
        compare(body.height, collapsedHeight);
        studio.currentTabIndex = tabIndex("audio");
        verify(waitForRendering(studio));
        verify(studio.anyResults);
    }

    function test_resizeDoesNotBounceAcrossBreakpoints() {
        const preview = findChild(studio, "studioPreviewPane");
        testCase.width = 900;
        testCase.height = 700;
        verify(!studio.wide && !studio.compact);
        testCase.width = 1045;
        verify(studio.wide);
        testCase.width = 1000;
        verify(studio.wide, "Small width changes keep the side by side layout");
        testCase.width = 950;
        verify(!studio.wide);
        testCase.height = 615;
        verify(studio.compact);
        const compactHeight = preview.height;
        testCase.height = 640;
        verify(studio.compact, "Small height changes keep compact controls");
        verify(Math.abs(preview.height - compactHeight) < 16, "The preview height changes smoothly while resizing");
        testCase.height = 665;
        verify(!studio.compact);
    }

    function test_savedLooksHaveTheirOwnSubpage_data() {
        return [
            {
                tag: "narrow",
                width: 540
            },
            {
                tag: "wide",
                width: 1200
            }
        ];
    }

    function test_savedLooksHaveTheirOwnSubpage(data) {
        testCase.width = data.width;
        studio.presetFilter = "adaptive";
        verify(waitForRendering(studio));
        const looks = findChild(studio, "section_presets_0");
        const saved = findChild(studio, "section_saved_1");
        verify(!saved.visible, "My presets is a subpage of Presets");

        const builtIn = findChild(studio, "preset_halo");
        verify(builtIn.visible);
        verify(builtIn.mapToItem(looks, 0, builtIn.height).y <= looks.height);
        studio.saveUserPreset("My look");
        mouseClick(findChild(studio, "presetView_mine"));
        verify(waitForRendering(studio));
        verify(saved.visible && !looks.visible);
        compare(findChild(studio, "preset_halo"), null);
        const tile = findChild(studio, "userPreset_0");
        const name = findChild(studio, "userPresetName");
        verify(tile !== null);
        verify(tile.mapToItem(saved, 0, tile.height).y <= name.mapToItem(saved, 0, 0).y, "Save controls must follow the saved thumbnail");
        verify(name.mapToItem(saved, 0, name.height).y <= saved.height);
    }

    function test_fillControlMatchesRendererSupport_data() {
        const cases = [];
        for (let type = 0; type < Schema.VIZ.length; type++) {
            cases.push({
                tag: Schema.VIZ[type],
                layout: "stacked",
                type: type,
                orbitStyle: "wave",
                supported: [0, 6, 10, 18].indexOf(type) !== -1
            });
        }
        for (const style of Schema.ORBITS) {
            for (const type of [0, 1]) {
                cases.push({
                    tag: "Orbit " + style + " with type " + type,
                    layout: "orbit",
                    type: type,
                    orbitStyle: style.toLowerCase(),
                    supported: style === "Wave"
                });
            }
        }
        return cases;
    }

    function test_fillControlMatchesRendererSupport(data) {
        studio.currentTabIndex = tabIndex("viz");
        studio.draft = Object.assign({}, defaults, {
            layoutMode: data.layout,
            visualizerType: data.type,
            orbitStyle: data.orbitStyle,
            fillWave: false
        });
        verify(waitForRendering(studio));
        const row = findChild(studio, "row_fillWave");
        compare(row !== null && row.visible, data.supported);
        compare(studio.draft.fillWave, false, "Changing styles preserves the fill preference");
    }

    function test_colourControlsLiveTogether() {
        studio.currentTabIndex = tabIndex("viz");
        verify(waitForRendering(studio));
        compare(findChild(studio, "row_vizColorMode"), null);
        studio.currentTabIndex = tabIndex("colors");
        verify(waitForRendering(studio));
        verify(findChild(studio, "row_waveSrc").visible);
        verify(findChild(studio, "row_vizColorMode").visible);
        verify(findChild(studio, "row_bloom").visible);
    }

    function test_positionLivesUnderBehaviourOnlyOnHyprland() {
        compare(tabIndex("place"), -1);
        studio.currentTabIndex = tabIndex("behavior");
        verify(waitForRendering(studio));
        const monitor = findChild(studio, "row_monitor");
        verify(monitor !== null && monitor.visible);
        studio.env = "kde";
        verify(waitForRendering(studio));
        compare(findChild(studio, "row_monitor"), null);
        studio.env = "hypr";
    }

    function test_tileGridReservesItsHeight() {
        studio.currentTabIndex = tabIndex("viz");
        verify(waitForRendering(studio));
        const gridRow = findChild(studio, "row_visualizerType");
        const lastTile = findChild(studio, "tile_visualizerType_15");
        const nextRow = findChild(studio, "row_lineWidth");
        verify(lastTile.mapToItem(gridRow, 0, lastTile.height).y <= gridRow.height);
        verify(nextRow.y >= gridRow.y + gridRow.height);
    }

    function test_hiddenStudioStopsPreviewClocks() {
        const preview = findChild(studio, "previewWidget");
        verify(preview !== null);
        studio.visible = false;
        tryCompare(studio.backend, "running", false);
        tryCompare(preview.visualizer, "running", false);
        const tileTime = studio.backend.frameTimeMs;
        const stageTime = preview.visualizer.frameTimeMs;
        wait(160);
        compare(studio.backend.frameTimeMs, tileTime);
        compare(preview.visualizer.frameTimeMs, stageTime);
        studio.visible = true;
        tryCompare(preview.visualizer, "running", true);
    }

    function test_draftLoadsAfterCreation() {
        const fresh = Qt.createComponent("../package/contents/ui/studio/Studio.qml");
        const view = createTemporaryObject(fresh, testCase, {
            width: 1200,
            height: 820,
            libraryPath: testCase.libraryPath
        });
        verify(view !== null);
        compare(findChild(view, "previewWidget"), null);
        view.defaults = defaults;
        view.draft = Object.assign({}, defaults);
        const preview = findChild(view, "previewWidget");
        verify(preview !== null);
        compare(preview.configuration.showMpris, defaults.showMpris);
        const glass = findChild(view, "preset_glass");
        verify(glass !== null);
        compare(glass.settings.titleSize, defaults.titleSize);
        compare(glass.settings.surfaceStyle, "glass");
    }

    function test_previewRendersTheDraft() {
        const preview = findChild(studio, "previewWidget");
        verify(preview !== null);
        studio.update({
            layoutMode: "poster"
        });
        compare(preview.configuration.layoutMode, "poster");
        compare(preview.implicitHeight, 112);
    }
    function test_previewCanSwitchBetweenSampleAndLiveSource() {
        const preview = findChild(studio, "previewWidget");
        const sampleBackend = preview.visualizer;
        verify(preview.samplePlayback);
        studio.liveVisualizer = studio.backend;
        studio.livePlayer = studio.samplePlayer;
        studio.liveIsPlaying = true;
        const liveButton = findChild(studio, "livePreviewButton");
        verify(liveButton.visible);
        mouseClick(liveButton);
        verify(studio.livePreview, "Live audio button should select the live source");
        compare(preview.visualizer, studio.backend);
        compare(preview.player, studio.samplePlayer);
        verify(!preview.samplePlayback);
        verify(!sampleBackend.running, "Synthetic preview stops while live audio is selected");
        studio.livePreview = false;
        compare(preview.visualizer, sampleBackend);
        verify(preview.samplePlayback);
    }
    function test_shapeTilesFollowLiveArtwork() {
        studio.selectTab("art");
        const art = findChild(studio, "shapePreviewArtwork");
        verify(art !== null);
        const sampleUrl = studio.samplePlayer.artUrl;
        compare(art.artUrl, sampleUrl);
        const liveUrl = liveArtPlayer.artUrl;
        studio.liveVisualizer = studio.backend;
        studio.livePlayer = liveArtPlayer;
        studio.livePreview = true;
        compare(art.artUrl, liveUrl);
        studio.livePreview = false;
        compare(art.artUrl, sampleUrl);
    }
}
