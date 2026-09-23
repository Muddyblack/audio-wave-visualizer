import QtQuick

// One bounded helper invocation per request; late replies cannot cross tracks.
Item {
    id: root
    property Component commandSourceComponent: null
    property string mode: "queue"
    property var payload: ({})
    property bool active: false
    property var result: ({})
    property string status: "idle"
    property string command: ""
    property int generation: 0
    function quote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }
    function cancel() {
        timeout.stop();
        const old = command;
        command = "";
        if (old) {
            worker.cancelSource(old);
            worker.disconnectSource(old);
        }
    }
    function reset() {
        settle.stop();
        cancel();
        result = ({});
        status = active ? "loading" : "idle";
        if (active)
            settle.restart();
    }
    function refresh() {
        if (!active || command)
            return;
        if (!worker.item) {
            status = "error";
            return;
        }
        const script = decodeURIComponent(Qt.resolvedUrl("../code/media_metadata.sh").toString().replace(/^file:\/\//, ""));
        command = quote(script) + " " + quote(mode) + " " + quote(JSON.stringify(payload)) + " # " + (++generation);
        worker.connectSource(command);
        timeout.restart();
    }
    onActiveChanged: reset()
    onPayloadChanged: reset()
    onModeChanged: reset()
    Component.onDestruction: cancel()
    Timer {
        id: settle
        interval: 250
        onTriggered: root.refresh()
    }
    Timer {
        id: timeout
        interval: 25000
        onTriggered: {
            root.cancel();
            root.status = "error";
        }
    }
    CommandSource {
        id: worker
        objectName: "mediaLookupWorker"
        sourceComponent: root.commandSourceComponent
        onLoaded: {
            if (root.active)
                settle.restart();
        }
        onNewData: function (source, data) {
            if (source !== root.command)
                return;
            timeout.stop();
            worker.disconnectSource(source);
            root.command = "";
            try {
                root.result = JSON.parse(data["stdout"] || "{}");
                root.status = root.result.status || "error";
            } catch (error) {
                root.status = "error";
            }
        }
    }
}
