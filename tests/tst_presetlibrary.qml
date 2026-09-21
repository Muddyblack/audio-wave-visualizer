import QtQuick
import QtTest
import QtCore
import "../package/contents/ui/studio" as Studio

TestCase {
    id: testCase
    name: "PresetLibrary"
    when: windowShown
    visible: true
    width: 120
    height: 80
    readonly property string path: StandardPaths.writableLocation(StandardPaths.TempLocation) + "/audio-wave-library-test-" + Date.now() + ".ini"

    Studio.PresetLibrary {
        id: first
        filePath: testCase.path
        active: false
    }
    Studio.PresetLibrary {
        id: second
        filePath: testCase.path
        active: false
    }

    function init() {
        first.clear();
        second.refresh();
    }
    function test_sharedAcrossInstances() {
        first.setFavorites(["glass"]);
        first.setPresets([
            {
                id: "saved-1",
                name: "My look",
                settings: {
                    titleSize: 14
                }
            }
        ]);
        compare(first.favorites, ["glass"]);
        const request = new XMLHttpRequest();
        request.open("GET", "file://" + first.resolvedPath, false);
        request.send();
        verify(request.responseText.includes("glass"), "Saved library must reach disk before another widget reads it");
        second.refresh();
        compare(second.favorites, ["glass"]);
        compare(second.presets.length, 1);
        compare(second.presets[0].name, "My look");
    }
    function test_legacyImportsOnceAndDoesNotResurrectDeletedLook() {
        const oldFavorites = '["glass","old-1"]';
        const oldPresets = '[{"id":"old-1","name":"Old look","settings":{"titleSize":14}}]';
        first.migrate(oldFavorites, oldPresets);
        compare(first.presets.length, 1);
        first.setPresets([]);
        first.setFavorites([]);
        first.migrate(oldFavorites, oldPresets);
        compare(first.presets.length, 0);
        compare(first.favorites.length, 0);
        second.refresh();
        compare(second.presets.length, 0);
    }
}
