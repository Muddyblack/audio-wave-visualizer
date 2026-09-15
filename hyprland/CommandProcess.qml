pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io

Item {
    id: root
    property string runtimeDirectory: ""
    property var connectedSources: []
    property var processes: ({})
    signal newData(string source, var data)

    // The core explicitly stops its feeder on destruction. Detaching lets
    // that SIGTERM run its cleanup instead of Quickshell's destructor SIGKILL.
    function runDetached(source) {
        const process = command.createObject(root, {
            source: source
        });
        process.startDetached();
        process.destroy();
    }

    function connectSource(source, owned = false) {
        if (connectedSources.indexOf(source) !== -1)
            return;
        connectedSources = connectedSources.concat([source]);
        const process = command.createObject(root, {
            source: source,
            owned: owned
        });
        processes[source] = process;
        process.running = true;
    }
    function cancelSource(source) {
        const process = processes[source];
        if (!process)
            return;
        delete processes[source];
        disconnectSource(source);
        process.cancelled = true;
        stopProcess(process);
    }
    function stopProcess(process) {
        const pid = Number(process.processId);
        if (process.owned && pid > 0) {
            // Its own session keeps the group identifiable even if QML
            // destruction kills the feeder before its EXIT trap can run.
            const pidfile = "'" + (runtimeDirectory + "/feeder.pid").replace(/'/g, "'\\''") + "'";
            runDetached("kill -TERM -" + pid + " 2>/dev/null || kill -TERM " + pid + " 2>/dev/null; if [ \"$(cat " + pidfile + " 2>/dev/null)\" = \"" + pid + "\" ]; then rm -f " + pidfile + "; fi");
        } else {
            process.running = false;
        }
    }
    function disconnectSource(source) {
        connectedSources = connectedSources.filter(value => value !== source);
    }

    Component {
        id: command
        Process {
            id: process
            required property string source
            property bool cancelled: false
            property bool owned: false
            command: owned ? ["setsid", "sh", "-c", source] : ["sh", "-c", source]
            environment: ({
                    AUDIO_WAVE_RUNTIME_DIR: root.runtimeDirectory
                })
            stdout: StdioCollector {}
            stderr: StdioCollector {}
            onStarted: if (cancelled)
                root.stopProcess(process)
            onExited: (exitCode, exitStatus) => {
                if (root.processes[source] === process) {
                    delete root.processes[source];
                    root.disconnectSource(source);
                }
                if (!cancelled)
                    root.newData(source, {
                        stdout: stdout.text,
                        stderr: stderr.text,
                        "exit code": exitCode
                    });
                process.destroy();
            }
        }
    }
}
