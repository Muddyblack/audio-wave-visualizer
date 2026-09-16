import QtQuick
import "Schema.js" as Schema

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
        if (defaults.showMpris === undefined) {
            const request = new XMLHttpRequest();
            request.open("GET", Qt.resolvedUrl("../../config/main.xml"));
            request.onreadystatechange = function () {
                if (request.readyState === XMLHttpRequest.DONE) {
                    controller.defaults = Schema.defaultsFromXml(request.responseText);
                    controller.ready = true;
                    controller.check();
                }
            };
            request.send();
        } else {
            ready = true;
            Qt.callLater(check);
        }
    }
    Timer {
        interval: 30000
        repeat: true
        running: controller.ready && !!controller.configuration.autoDailyLook
        onTriggered: controller.check()
    }
}
