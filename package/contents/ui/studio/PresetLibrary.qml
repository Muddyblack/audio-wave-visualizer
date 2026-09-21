import QtQuick
import QtCore
import "Schema.js" as Schema

// One library for every widget instance owned by this user. Legacy per-widget
// values are imported once, so deleting a preset does not revive stale copies.
Item {
    id: library
    property string filePath: ""
    property bool active: true
    readonly property string resolvedPath: String(filePath || StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/audio-wave-visualizer-presets.ini").replace(/^file:\/\//, "")
    property string favoritesText: "[]"
    property string presetsText: "[]"
    property string importedText: "[]"
    readonly property var favorites: Schema.favoriteIds(favoritesText)
    readonly property var presets: Schema.parseUserPresets(presetsText)

    Settings {
        id: store
        location: "file://" + library.resolvedPath
    }
    Component.onCompleted: refresh()

    function fingerprint(text) {
        let hash = 2166136261;
        for (let i = 0; i < text.length; i++) {
            hash ^= text.charCodeAt(i);
            hash = Math.imul(hash, 16777619);
        }
        return text.length + ":" + (hash >>> 0).toString(16);
    }
    function setFavorites(ids) {
        favoritesText = JSON.stringify(ids);
        store.setValue("favoritePresets", favoritesText);
        store.sync();
    }
    function setPresets(list) {
        presetsText = JSON.stringify(list);
        store.setValue("userPresets", presetsText);
        store.sync();
    }
    function refresh() {
        store.sync();
        favoritesText = String(store.value("favoritePresets", "[]"));
        presetsText = String(store.value("userPresets", "[]"));
        importedText = String(store.value("importedLibraries", "[]"));
    }
    function migrate(legacyFavorites, legacyPresets) {
        const oldFavorites = Schema.favoriteIds(legacyFavorites);
        const oldPresets = Schema.parseUserPresets(legacyPresets);
        if (!oldFavorites.length && !oldPresets.length)
            return;
        refresh();
        const key = fingerprint(String(legacyFavorites ?? "") + "\n" + String(legacyPresets ?? ""));
        let imported;
        try {
            imported = JSON.parse(importedText);
        } catch (error) {
            imported = [];
        }
        if (!Array.isArray(imported))
            imported = [];
        if (imported.indexOf(key) !== -1)
            return;
        const merged = presets.slice();
        oldPresets.forEach((preset, index) => {
            const copy = Object.assign({}, preset);
            if (!copy.id)
                copy.id = "legacy-" + key + "-" + index;
            if (merged.some(existing => existing.id === copy.id && JSON.stringify(existing.settings) === JSON.stringify(copy.settings)))
                return;
            if (merged.some(existing => existing.id === copy.id))
                copy.id += "-" + key;
            merged.push(copy);
        });
        setPresets(merged);
        setFavorites(Array.from(new Set(favorites.concat(oldFavorites))));
        importedText = JSON.stringify(imported.concat([key]));
        store.setValue("importedLibraries", importedText);
        store.sync();
    }
    function clear() {
        favoritesText = "[]";
        presetsText = "[]";
        importedText = "[]";
        store.setValue("favoritePresets", favoritesText);
        store.setValue("userPresets", presetsText);
        store.setValue("importedLibraries", importedText);
        store.sync();
    }
    Timer {
        interval: 1000
        running: library.active
        repeat: true
        onTriggered: library.refresh()
    }
}
