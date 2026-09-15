import QtQuick

// The backend only needs this small subset of Plasma's executable DataSource.
// Hosts supply either the real DataSource or a Quickshell Process adapter.
Loader {
    id: root
    readonly property var connectedSources: item ? item.connectedSources : []
    signal newData(string source, var data)

    function connectSource(source, detached = false, owned = false) {
        if (item && detached && typeof item.runDetached === "function")
            item.runDetached(source);
        else if (item && owned)
            item.connectSource(source, true);
        else if (item)
            item.connectSource(source);
    }
    function disconnectSource(source) {
        if (item)
            item.disconnectSource(source);
    }
    function cancelSource(source) {
        if (item && typeof item.cancelSource === "function")
            item.cancelSource(source);
    }
    Connections {
        target: root.item
        function onNewData(source, data) {
            root.newData(source, data);
        }
    }
}
