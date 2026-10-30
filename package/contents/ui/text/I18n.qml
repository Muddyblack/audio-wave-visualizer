pragma Singleton
import QtQuick
import "../studio/I18n.js" as Po

// The one i18n() helper every QML file calls. Plasma hands over its own i18n()
// with useKde(), which reads the compiled .mo; the other hosts load a .po into
// `catalog`. Bindings read these properties, so they update when either arrives.
QtObject {
    property var kde: null
    property var catalog: Po.empty()

    function useKde(fn) {
        kde = fn;
    }
    // Catalog names for a locale (default: Qt's), most specific first.
    function languages(locale) {
        return Po.languageCandidates([locale || Qt.locale().name]);
    }
    function load(text) {
        catalog = Po.parsePo(text);
    }
    function i18n(text) {
        // Empty and missing values are shown as nothing, on every host.
        if (text === undefined || text === null || text === "")
            return "";
        const args = Array.prototype.slice.call(arguments);
        return kde ? kde.apply(null, args) : Po.i18n.apply(null, [catalog].concat(args));
    }
    // Marks text stored as data for Messages.sh; it is translated when drawn.
    function noop(text) {
        return text;
    }
}
