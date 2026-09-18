import QtQuick
import QtTest
import "../package/contents/ui"
import "../package/contents/ui/studio" as Studio
import "../hyprland/Configuration.js" as Configuration
import "../package/contents/ui/studio/Schema.js" as Schema

TestCase {
    id: testCase
    name: "CustomProgress"
    when: windowShown
    visible: true
    width: 500
    height: 350
    readonly property string example: Qt.resolvedUrl("../package/contents/examples/GradientProgress.qml").toString()
    property var subject
    property var player
    property var defaults

    Component {
        id: playerComponent
        Studio.SamplePlayer {
            canSeek: true
            position: 60
            length: 240
        }
    }
    Component {
        id: progressComponent
        ProgressBar {
            width: 320
            height: implicitHeight
            positionUnitsPerSecond: 1
        }
    }
    Component {
        id: viewComponent
        VisualizerView {
            width: implicitWidth
            height: implicitHeight
            visualizer: Studio.PreviewBackend {
                running: false
            }
        }
    }
    Component {
        id: pickerComponent
        Studio.CustomStylePicker {
            width: 320
            progressBar: true
            studio: QtObject {
                property var draft: ({})
                property bool onScreen: false
                function update(patch) {
                    draft = Object.assign({}, draft, patch);
                }
            }
        }
    }
    function initTestCase() {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../package/contents/config/main.xml"), false);
        request.send();
        defaults = Configuration.defaults(request.responseText);
    }
    function init() {
        failOnWarning(/undefined|TypeError|ReferenceError|Binding loop/);
        player = createTemporaryObject(playerComponent, testCase);
        subject = createTemporaryObject(progressComponent, testCase, {
            player: player
        });
        verify(subject !== null);
    }
    function test_clockSeekingAndBuiltinInputReplacement() {
        subject.customProgressBar = example;
        tryCompare(subject, "customReady", true);
        const loader = findChild(subject, "customProgressBarLoader");
        const api = loader.item.progressBar;
        compare(api.progress, 0.25);
        compare(api.position, 60);
        compare(api.duration, 240);
        compare(api.elapsedText, "1:00");
        compare(subject.implicitHeight, 24);
        verify(!findChild(subject, "pbArea").enabled);
        const seekArea = findChild(subject, "customSeekArea");
        mouseClick(seekArea, seekArea.width * 0.75, 3);
        compare(player.position, 180);
        compare(api.progress, 0.75);
        player.canSeek = false;
        verify(!api.canSeek);
        verify(!api.seekToFraction(0.1));
        compare(player.position, 180);
        subject.showTimes = false;
        compare(subject.implicitHeight, 10);
        subject.customProgressBar = "";
        tryCompare(subject, "customReady", false);
        verify(!findChild(subject, "pbArea").enabled, "The built-in control also respects canSeek");
        player.canSeek = true;
        verify(findChild(subject, "pbArea").enabled);
    }
    function test_nativeMicrosecondSeeking() {
        subject.positionUnitsPerSecond = 1000000;
        player.length = 240000000;
        player.position = 60000000;
        subject.customProgressBar = example;
        tryCompare(subject, "customReady", true);
        const api = findChild(subject, "customProgressBarLoader").item.progressBar;
        compare(api.duration, 240);
        compare(api.position, 60);
        verify(api.seekToFraction(0.5));
        compare(player.position, 120000000);
    }
    function test_wrongExtensionKindFallsBack() {
        subject.customProgressBar = Qt.resolvedUrl("../package/contents/examples/PulseBars.qml").toString();
        tryVerify(() => subject.customError !== "");
        verify(!subject.customReady);
        verify(findChild(subject, "pbArea").enabled);
        subject.customProgressBar = example;
        tryCompare(subject, "customReady", true);
    }
    function test_layoutWiringAndCoverRingPrecedence_data() {
        return ["classic", "inline", "hero", "stacked", "poster", "orbit"].map(mode => ({
                    tag: mode,
                    mode: mode
                }));
    }
    function test_layoutWiringAndCoverRingPrecedence(data) {
        const view = createTemporaryObject(viewComponent, testCase, {
            configuration: Object.assign({}, defaults, {
                layoutMode: data.mode,
                customProgressBar: example,
                progressBarStyle: 10
            }),
            player: player
        });
        verify(view !== null);
        tryVerify(() => findChild(view, "progressBar") !== null);
        const progress = findChild(view, "progressBar");
        verify(!progress.suppressed);
        tryCompare(progress, "customReady", true);
    }
    function test_pickerAndPortablePresets() {
        const picker = createTemporaryObject(pickerComponent, testCase);
        picker.importFile(example);
        compare(picker.studio.draft.customProgressBar, example);
        compare(picker.library.length, 1);
        verify(picker.studio.draft.customVisualizer === undefined);
        const look = Schema.applyPreset(defaults, picker.studio.draft, {
            progressBarStyle: 2
        }, false);
        compare(look.customProgressBar, "");
        compare(look.customProgressBars, picker.studio.draft.customProgressBars);
        const exported = Schema.exportPreset("Progress", picker.studio.draft, defaults);
        const imported = Schema.importPreset(exported, defaults).settings;
        verify(imported.customProgressBar === undefined);
        verify(imported.customProgressBars === undefined);
        const crafted = Schema.importPreset(JSON.stringify(picker.studio.draft), defaults).settings;
        verify(crafted.customProgressBar === undefined);
        verify(crafted.customProgressBars === undefined);
        compare(Schema.rowPatch({
            k: "progressBarStyle"
        }, 2, picker.studio.draft).customProgressBar, "");
        picker.removeSelected();
        compare(picker.selected, "");
        compare(picker.library, []);
    }
}
