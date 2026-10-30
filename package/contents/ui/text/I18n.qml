pragma Singleton
import QtQuick
import "../studio/I18n.js" as Po

// The one i18n() helper every QML file calls. Each host loads a .po into
// `catalog`; bindings read it, so they update when another language is chosen.
QtObject {
    property var catalog: Po.empty()
    // The translate/*.po catalogs a host found, as language codes.
    property var available: []
    // Identifies what is in `catalog`, so widgets can share it.
    property string loadedKey: ""
    // The first catalog is on its way; hosts hide their text until it arrives.
    property bool loading: false
    signal previewEnded

    // The language setting's choices: "" follows the system, and "en" is the
    // untranslated source. A new translate/*.po shows up here by itself.
    readonly property var languageOptions: [["", i18n("System default")], ["en", "English"]].concat(available.filter(code => code !== "en").map(code => {
        const name = Qt.locale(code).nativeLanguageName;
        return [code, name ? name.charAt(0).toUpperCase() + name.slice(1) : code];
    }))

    // Catalog names to try for a language, most specific first. Only real
    // language tags pass, because hosts look these names up on disk.
    function candidates(language) {
        const tags = Po.languageCandidates(language ? [language] : Qt.locale().uiLanguages);
        return tags.filter(tag => /^[A-Za-z]{2,3}(_[A-Za-z0-9]{2,8})?$/.test(tag));
    }
    function load(text, key) {
        catalog = Po.parsePo(text);
        loadedKey = key || "";
        loading = false;
    }
    function i18n(text) {
        // Empty and missing values are shown as nothing, on every host.
        if (text === undefined || text === null || text === "")
            return "";
        return Po.i18n.apply(null, [catalog].concat(Array.prototype.slice.call(arguments)));
    }
    // Marks text stored as data for Messages.sh; it is translated when drawn.
    function noop(text) {
        return text;
    }
}
