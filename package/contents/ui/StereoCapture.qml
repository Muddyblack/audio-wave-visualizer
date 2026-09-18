pragma ComponentBehavior: Bound
import QtQuick
import QtCore

// Each owner has a lease. Hiding, destruction or a host crash stops capture
// within three seconds, including hosts without command cancellation support.
Item {
    id: root
    required property Component commandSourceComponent
    property string runtimeDirectory: ""
    property bool active: false
    property int framerate: 30
    property string inputSource: "auto"
    onInputSourceChanged: {
        const settings = lease.item as Settings;
        if (settings) {
            settings.setValue("t", 0);
            settings.sync();
        }
        _id = "stereo-" + Date.now() + "-" + Math.floor(Math.random() * 1000000);
        clear();
        heartbeat();
    }
    property var samples: []
    property var previous: []
    property string status: active ? "Waiting for stereo output" : ""
    property string _id: "stereo-" + Date.now() + "-" + Math.floor(Math.random() * 1000000)
    readonly property string base: runtimeDirectory ? runtimeDirectory + "/" + _id : ""
    property real _last: 0
    function quote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }
    function clear() {
        samples = [];
        previous = [];
        _last = 0;
    }
    function accept(value, stamp) {
        if (!active || !Number.isFinite(stamp) || Math.abs(Date.now() - stamp * 1000) > 1000) {
            clear();
            return;
        }
        if (stamp === _last)
            return;
        const pairs = String(value).split(";").map(s => s.split(":").map(Number));
        if (pairs.length !== 32 || pairs.some(p => p.length !== 2 || p.some(v => !Number.isFinite(v) || Math.abs(v) > 1))) {
            clear();
            return;
        }
        previous = samples;
        samples = pairs;
        _last = stamp;
        status = "";
    }
    Loader {
        id: lease
        active: root.base !== ""
        sourceComponent: Settings {
            location: "file://" + root.base + ".lease"
        }
    }
    Loader {
        id: frame
        active: root.active && root.base !== ""
        sourceComponent: Settings {
            location: "file://" + root.base + ".ini"
        }
    }
    CommandSource {
        id: capture
        sourceComponent: root.commandSourceComponent
        onNewData: function (source, data) {
            disconnectSource(source);
            if (root.active)
                root.status = String(data["stdout"] || "Stereo capture unavailable").trim();
        }
    }
    function heartbeat() {
        const settings = lease.item as Settings;
        if (!settings)
            return;
        settings.setValue("t", active ? Date.now() : 0);
        settings.sync();
        if (active && !capture.connectedSources.length) {
            const script = Qt.resolvedUrl("../code/stereo_capture.sh").toString().replace(/^file:\/\//, "");
            capture.connectSource("bash " + quote(script) + " " + quote(base + ".lease") + " " + quote(base + ".ini") + " " + Math.max(1, Math.min(60, framerate)) + " " + quote(inputSource));
        }
    }
    onActiveChanged: {
        clear();
        heartbeat();
    }
    Component.onDestruction: {
        const settings = lease.item as Settings;
        if (settings) {
            settings.setValue("t", 0);
            settings.sync();
        }
    }
    Timer {
        interval: 1000
        running: root.active && root.base !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: root.heartbeat()
    }
    Timer {
        interval: Math.round(1000 / Math.max(1, Math.min(60, root.framerate)))
        running: root.active && !!frame.item
        repeat: true
        onTriggered: {
            const settings = frame.item as Settings;
            if (!settings)
                return;
            settings.sync();
            root.accept(settings.value("v", ""), Number(settings.value("t", 0)));
            if (!root.samples.length && !root.status)
                root.status = "Waiting for stereo output";
        }
    }
}
