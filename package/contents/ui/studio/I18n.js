.pragma library
.import "TranslationCatalog.js" as Catalog

// The one translation helper for every QML file in the widget and studio.
//
//   import "studio/I18n.js" as I18n
//   text: I18n.i18n(<English text>)
//   text: I18n.i18n("%1 bars", count)
//
// Strings are looked up in the Turkish catalog that Messages.sh generates from
// tr.po (TranslationCatalog.js). It is part of this module, so it is ready before
// any QML object is created. That matters: bindings that call i18n() while the
// interface is built would otherwise run before a host could register anything.
//
// Plasma: the host also hands over KDE's global i18n() through useKde(); when it
// is set, KDE's compiled plasma_applet_<Id>.mo is used instead.
//
// Messages.sh extracts every i18n and N_ call with a literal from these files
// into template.pot. N_ only marks a string for extraction and returns it
// unchanged; it is used for labels that are stored as data and translated
// when they are drawn.

var kdeI18n = null;

function useKde(fn) {
    kdeI18n = typeof fn === "function" ? fn : null;
}

function language() {
    try {
        return String(Qt.locale().name || "").split(/[_.@-]/)[0];
    } catch (error) {
        return "";
    }
}

var messages = language() === "tr" ? Catalog.messages : ({});

function substitute(text, args) {
    return String(text).replace(/%(\d)/g, function (all, d) {
        var value = args[Number(d) - 1];
        return value === undefined ? all : String(value);
    });
}

function i18n(text) {
    var args = Array.prototype.slice.call(arguments);
    if (kdeI18n)
        return kdeI18n.apply(null, args);
    var source = String(text === undefined || text === null ? "" : text);
    var shown = Object.prototype.hasOwnProperty.call(messages, source) ? messages[source] : source;
    return substitute(shown, args.slice(1));
}

// Marks a string for extraction only: returns it unchanged.
function N_(text) {
    return text;
}
