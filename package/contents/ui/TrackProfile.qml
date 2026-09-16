pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    property Component commandSourceComponent: null
    property string fileUrl: ""
    property bool active: true
    property bool wantPeaks: true
    property var peaks: []
    property var chapters: []
    property string status: "idle"
    property string _command: ""
    property int _generation: 0
    function quote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }
    function reset() {
        settle.stop();
        if (_command) {
            worker.cancelSource(_command);
            worker.disconnectSource(_command);
        }
        _command = "";
        peaks = [];
        chapters = [];
        status = active && fileUrl ? "loading" : "idle";
        if (active && fileUrl)
            settle.restart();
    }
    function load() {
        if (!worker.item || !active || !fileUrl)
            return;
        const script = decodeURIComponent(Qt.resolvedUrl("../code/track_profile.sh").toString().replace(/^file:\/\//, ""));
        _command = "bash " + quote(script) + " " + quote(fileUrl) + (wantPeaks ? "" : " --chapters-only") + " # " + (++_generation);
        worker.connectSource(_command);
    }
    onFileUrlChanged: reset()
    onActiveChanged: reset()
    onWantPeaksChanged: reset()
    Component.onDestruction: {
        if (_command) {
            worker.cancelSource(_command);
            worker.disconnectSource(_command);
        }
    }
    Timer {
        id: settle
        interval: 250
        onTriggered: root.load()
    }
    CommandSource {
        id: worker
        objectName: "trackProfileWorker"
        sourceComponent: root.commandSourceComponent
        onLoaded: {
            if (root.active && root.fileUrl)
                settle.restart();
        }
        onNewData: function (source, data) {
            if (source !== root._command)
                return;
            disconnectSource(source);
            root._command = "";
            try {
                const result = JSON.parse(data["stdout"] || "{}");
                root.peaks = Array.isArray(result.peaks) && result.peaks.length === 128 && result.peaks.every(v => Number.isFinite(v) && v >= 0 && v <= 1) ? result.peaks : [];
                root.chapters = Array.isArray(result.chapters) ? result.chapters : [];
                root.status = result.status || "unavailable";
            } catch (error) {
                root.status = "unavailable";
            }
        }
    }
}
