import QtQuick
import QtTest
import QtCore
import org.kde.plasma.plasma5support as Support
import "../package/contents/ui"

TestCase {
    name: "Visualizer"
    when: windowShown
    property QtObject plasmoid: QtObject {
        property bool visible: false
        property QtObject configuration: QtObject {
            property int numBars: 4
            property int framerate: 60
            property int sensitivity: 100
            property real noiseReduction: 0.77
            property string inputMethod: "auto"
        }
    }
    property string runtimeDir: StandardPaths.writableLocation(StandardPaths.RuntimeLocation).toString().replace(/^file:\/\//, "")
    Component {
        id: visualizer
        Visualizer {}
    }
    // Hands commands captured from the stub to run.py, which executes them.
    Settings {
        id: exported
        location: "file://" + runtimeDir + "/commands.ini"
    }
    property var subject: null
    property int updates: 0
    Connections {
        target: subject
        function onBarsChanged() {
            updates++;
        }
    }

    function init() {
        Support.Commands.calls = [];
        plasmoid.visible = false;
        subject = createTemporaryObject(visualizer, this);
        verify(subject !== null);
        updates = 0;
    }

    function test_legacyAndIniFrames() {
        subject.handleData("100;200;300;400;");
        verify(subject.hasAudio);
        compare(subject.bars.length, 4);
        verify(subject.bars[3] > subject.bars[0]);
        subject.handleData(["400", "300", "200", "100", ""]);
        verify(subject.hasAudio);
        const before = subject.bars.slice();
        subject.handleData("");
        subject.handleData(["invalid", "200"]);
        compare(subject.bars, before);
    }

    function test_silenceSettlesAndAudioWakes() {
        subject.handleData("900;900;900;900;");
        verify(subject.hasAudio);
        for (let i = 0; i < 200; i++)
            subject.handleData("0;1;2;0;");
        verify(!subject.hasAudio);
        compare(subject.bars, [0, 0, 0, 0]);
        const settled = updates;
        for (let i = 0; i < 20; i++)
            subject.handleData("0;0;0;0;");
        compare(updates, settled, "Silent polls must not repaint the wave");
        subject.handleData("900;900;900;900;");
        verify(subject.hasAudio, "Audio must wake the wave without a media player");
        verify(updates > settled);
    }

    function test_oldFeederFallback() {
        subject.resolvedRunDir = runtimeDir + "/old-feeder";
        subject.readBars();
        verify(subject.hasAudio);
        verify(Support.Commands.calls.some(value => value.startsWith("cat ")));
    }

    function test_liveFeederWithoutFrameProcesses() {
        subject.resolvedRunDir = runtimeDir + "/audio-wave-widget";
        let sawLow = false;
        let sawHigh = false;
        for (let i = 0; i < 90; i++) {
            subject.readBars();
            sawLow = sawLow || subject.bars[0] < 200;
            sawHigh = sawHigh || subject.bars[0] > 700;
            wait(20);
        }
        verify(sawLow && sawHigh, "Must follow changing external frames");
        verify(subject.hasAudio);
        verify(!Support.Commands.calls.some(value => value.startsWith("cat ")), "Current feeder must use in-process reads");
    }

    // run.py runs this command against a real feeder stuck in a backend probe.
    function test_restartStopsFeederBeforeSpawning() {
        subject.resolvedRunDir = runtimeDir + "/audio-wave-widget";
        subject.restart();
        const restart = Support.Commands.calls.find(value => value.includes("pkill"));
        verify(restart !== undefined);
        verify(restart.indexOf("pkill") < restart.indexOf("flock -w") && restart.indexOf("flock -w") < restart.indexOf("bash "), restart);
        // Base64 keeps quotes and backslashes out of QSettings' INI escaping.
        exported.setValue("restart", Qt.btoa(restart).replace(/=+$/, ""));
        exported.sync();
    }

    function test_secondInstanceJoinsWithoutRestarting() {
        plasmoid.visible = true;
        const other = createTemporaryObject(visualizer, this);
        verify(other !== null);
        wait(50);
        verify(Support.Commands.calls.some(value => value.startsWith("bash ")));
        verify(!Support.Commands.calls.some(value => value.includes("pkill")));
        subject.active = false;
        wait(50);
        verify(other.active);
        verify(!Support.Commands.calls.some(value => value.includes("pkill")));
    }
}
