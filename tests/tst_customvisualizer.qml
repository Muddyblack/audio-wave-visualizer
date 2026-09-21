import QtQuick
import QtTest
import "../package/contents/ui"
import "../package/contents/ui/studio" as Studio
import "../package/contents/ui/studio/Schema.js" as Schema
import "../package/contents/code/CustomStyles.js" as CustomStyles

TestCase {
    id: testCase
    name: "CustomVisualizer"
    when: windowShown
    visible: true
    width: 360
    height: 400
    readonly property string example: Qt.resolvedUrl("../package/contents/examples/PulseBars.qml").toString()
    property var subject

    Component {
        id: waveform
        Waveform {
            width: 320
            height: 80
            simpleRender: true
            bars: [200, 400, 600, 800]
            hasAudio: true
        }
    }
    function init() {
        subject = createTemporaryObject(waveform, testCase);
        verify(subject !== null);
    }
    function test_liveInterfaceAndRendererSwitch() {
        subject.customVisualizer = example;
        tryCompare(subject, "customReady", true);
        compare(subject.customError, "");
        const loader = findChild(subject, "customVisualizerLoader");
        const api = loader.item.visualizer;
        compare(loader.item.width, 320);
        compare(loader.item.height, 80);
        compare(api.bars, subject.bars);
        compare(api.energy, 0.5);
        compare(findChild(subject, "canvasLoader").active, false);
        subject.bars = [1000, 0];
        subject.bass = 0.8;
        subject.visualFrameTime = 1234;
        subject.waveColor = "#abcdef";
        compare(api.numBars, 2);
        compare(api.bass, 0.8);
        compare(api.frameTimeMs, 1234);
        compare(api.waveColor, subject.waveColor);
        subject.backendFailed = true;
        compare(api.active, false);
        subject.customVisualizer = "";
        tryCompare(subject, "customReady", false);
        compare(loader.item, null);
        compare(findChild(subject, "canvasLoader").active, true);
    }
    function test_hiddenStylesUnloadAndResume() {
        subject.customVisualizer = example;
        tryCompare(subject, "customReady", true);
        subject.visible = false;
        tryCompare(subject, "customReady", false);
        compare(findChild(subject, "customVisualizerLoader").item, null);
        subject.visible = true;
        tryCompare(subject, "customReady", true);
    }
    function test_badStyleFallsBack_data() {
        return [
            {
                tag: "missing",
                url: Qt.resolvedUrl("fixtures/custom/Deleted.qml").toString()
            },
            {
                tag: "api",
                url: Qt.resolvedUrl("fixtures/custom/Unsupported.qml").toString()
            },
            {
                tag: "interface",
                url: Qt.resolvedUrl("fixtures/custom/MissingInterface.qml").toString()
            },
            {
                tag: "remote",
                url: "https://example.com/Style.qml"
            },
            {
                tag: "relative",
                url: "Style.qml"
            }
        ];
    }
    function test_badStyleFallsBack(data) {
        subject.customVisualizer = data.url;
        tryVerify(() => subject.customError !== "");
        compare(subject.customReady, false);
        compare(findChild(subject, "canvasLoader").active, true);
        // A subsequent working import recovers without restarting the host.
        subject.customVisualizer = example;
        tryCompare(subject, "customReady", true);
        compare(subject.customError, "");
    }
    function test_libraryAndPresetBoundaries() {
        const library = JSON.stringify([
            {
                name: "Example",
                url: example
            }
        ]);
        const defaults = {
            customVisualizer: "",
            customVisualizers: "",
            visualizerType: 0
        };
        const current = {
            customVisualizer: example,
            customVisualizers: library,
            visualizerType: 0
        };
        compare(CustomStyles.readLibrary("broken"), []);
        compare(CustomStyles.readLibrary(library).length, 1);
        compare(CustomStyles.nameForUrl("file:///tmp/My%20Style.qml"), "My Style");
        const look = Schema.applyPreset(defaults, current, {
            visualizerType: 2
        }, false);
        compare(look.customVisualizers, library);
        compare(look.customVisualizer, "");
        compare(Schema.rowPatch({
            k: "visualizerType"
        }, 3, current).customVisualizer, "");
        const exported = Schema.exportPreset("Example", current, defaults);
        const decoded = Schema.importPreset(exported, defaults).settings;
        verify(decoded.customVisualizer === undefined);
        verify(decoded.customVisualizers === undefined);
        const imported = Schema.importPreset(JSON.stringify({
            settings: current
        }), defaults).settings;
        verify(imported.customVisualizer === undefined);
        verify(imported.customVisualizers === undefined);
    }

    Component {
        id: pickerComponent
        Studio.CustomStylePicker {
            width: 320
            studio: QtObject {
                property var draft: ({
                        customVisualizer: "",
                        customVisualizers: "",
                        visualizerType: 0,
                        lineWidth: 2,
                        fillWave: true,
                        glowWave: false
                    })
                property bool onScreen: false
                property var backend: null
                property color accent: "white"
                function update(patch) {
                    draft = Object.assign({}, draft, patch);
                }
            }
        }
    }
    function test_importAndRemove() {
        const picker = createTemporaryObject(pickerComponent, testCase);
        verify(picker !== null);
        picker.importFile(example);
        compare(picker.selected, example);
        compare(picker.library.length, 1);
        picker.importFile(example);
        compare(picker.library.length, 1);
        picker.importFile("https://example.com/Bad.qml");
        compare(picker.selected, example);
        verify(picker.message !== "");
        waitForRendering(picker);
        mouseClick(findChild(picker, "removeCustomVisualizer"));
        compare(picker.selected, "");
        compare(picker.library.length, 0);
    }
}
