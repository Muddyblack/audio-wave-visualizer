import QtQuick
import "text"

// Finds the catalogs in translateDir and loads the chosen language's, using the
// host's command source: QML has no file API that works on every host. One
// command answers both, with the catalog names on the first line.
Item {
    id: root
    required property Component commandSourceComponent
    property string translateDir: decodeURIComponent(Qt.resolvedUrl("../translate").toString().replace(/^file:\/\//, ""))
    property string language: ""
    // Followed when `language` is empty; Qt's locale when this is empty too.
    property string systemLocale: ""
    // A settings page trying a language out, not the widget's saved choice.
    property bool preview: false
    property string command: ""

    function quote(text) {
        return "'" + text.replace(/'/g, "'\\''") + "'";
    }
    function refresh() {
        const wanted = I18n.candidates(language || systemLocale).map(quote).join(" ");
        const next = "cd " + quote(translateDir) + " 2>/dev/null || exit 0; echo *.po; for l in " + wanted + "; do [ -f \"$l.po\" ] && exec cat \"$l.po\"; done";
        // Another widget already loaded it: reloading would only redraw.
        if (next === I18n.loadedKey || !source.item)
            return;
        command = next;
        if (!I18n.loadedKey) {
            I18n.loading = true;
            giveUp.restart();
        }
        source.item.connectSource(command);
    }
    onLanguageChanged: refresh()
    Component.onCompleted: refresh()
    Component.onDestruction: if (preview)
        I18n.previewEnded()

    // Hidden text is worse than English text if the command never answers.
    Timer {
        id: giveUp
        interval: 2000
        onTriggered: I18n.loading = false
    }
    Connections {
        target: I18n
        enabled: !root.preview
        function onPreviewEnded() {
            root.refresh();
        }
    }
    Connections {
        target: source.item
        function onNewData(sourceName, data) {
            if (sourceName !== root.command)
                return;
            const out = String(data["stdout"] || "");
            const end = out.indexOf("\n");
            I18n.available = (end < 0 ? out : out.slice(0, end)).split(" ").filter(file => /\.po$/.test(file) && file !== "*.po").map(file => file.slice(0, -3));
            I18n.load(end < 0 ? "" : out.slice(end + 1), root.command);
            giveUp.stop();
        }
    }
    Loader {
        id: source
        sourceComponent: root.commandSourceComponent
    }
}
