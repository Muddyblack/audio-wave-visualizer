import QtQuick
import "Schema.js" as Schema
import "../../code/ConfigDefaults.js" as ConfigDefaults

// Shared runtime scheduler. The host persists the date together with the look.
// No reroll on restart; manual edits remain until the next local date.
Item {
    id: controller
    required property var configuration
    property var defaults: ({})
    property bool ready: false
    signal apply(var next)
    visible: false
    function check() {
        if (!ready || defaults.showMpris === undefined)
            return;
        const next = Schema.dailyUpdate(defaults, configuration, Schema.localDay());
        if (next)
            apply(next);
    }
    onConfigurationChanged: Qt.callLater(check)
    Component.onCompleted: {
        if (defaults.showMpris === undefined)
            defaults = Object.assign({}, ConfigDefaults.values);
        ready = true;
        Qt.callLater(check);
    }
    Timer {
        interval: 30000
        repeat: true
        running: controller.ready && !!controller.configuration.autoDailyLook
        onTriggered: controller.check()
    }
}
