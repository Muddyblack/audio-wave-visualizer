import QtQml

QtObject {
    property string engine: ""
    property var connectedSources: []
    signal newData(string source, var data)
    function connectSource(source) {
        Commands.calls = Commands.calls.concat([source]);
        connectedSources = connectedSources.concat([source]);
        if (source.startsWith("cat "))
            newData(source, {
                stdout: Commands.legacyFrame
            });
    }
    function disconnectSource(source) {
        connectedSources = connectedSources.filter(value => value !== source);
    }
    function cancelSource(source) {
        Commands.cancelled = Commands.cancelled.concat([source]);
        disconnectSource(source);
    }
}
