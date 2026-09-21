import QtQuick
import QtTest
import "../package/contents/ui"
import "../package/contents/ui/studio" as Studio
import "../package/contents/ui/studio/Schema.js" as Schema
import "../hyprland/Configuration.js" as Configuration

TestCase {
    id: testCase
    name: "CustomButtons"
    when: windowShown
    visible: true
    width: 320
    height: 100
    readonly property string example: Qt.resolvedUrl("../package/contents/examples/MinimalButtons.qml").toString()
    property var subject
    property int previousCalls: 0
    property int playCalls: 0
    property int nextCalls: 0
    property var defaults

    Component {
        id: dockComponent
        TransportDock {
            anchors.centerIn: parent
            configuration: ({
                    customButtons: testCase.example,
                    showSkipButtons: true,
                    useSystemDockBg: true
                })
            player: ({
                    canGoPrevious: true,
                    canGoNext: true,
                    canTogglePlaying: true,
                    previous: () => testCase.previousCalls++,
                    next: () => testCase.nextCalls++,
                    togglePlaying: () => testCase.playCalls++
                })
        }
    }
    Component {
        id: pickerComponent
        Studio.CustomStylePicker {
            width: 320
            buttons: true
            studio: QtObject {
                property var draft: ({
                        customButtons: "",
                        customButtonStyles: ""
                    })
                property bool onScreen: false
                function update(patch) {
                    draft = Object.assign({}, draft, patch);
                }
            }
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
        id: samplePlayerComponent
        Studio.SamplePlayer {}
    }
    function initTestCase() {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../package/contents/config/main.xml"), false);
        request.send();
        defaults = Configuration.defaults(request.responseText);
    }
    function init() {
        previousCalls = playCalls = nextCalls = 0;
        subject = createTemporaryObject(dockComponent, testCase);
        verify(subject !== null);
    }
    function test_customLoaderAndPlaybackActions() {
        tryCompare(subject, "customReady", true);
        compare(subject.customError, "");
        const item = findChild(subject, "customButtonsLoader").item;
        compare(item.width, subject.width);
        compare(subject.implicitWidth, 112);
        const api = item.buttons;
        verify(api.canGoPrevious && api.canTogglePlaying && api.canGoNext);
        mouseClick(findChild(item, "exampleButton_previous"));
        mouseClick(findChild(item, "exampleButton_togglePlaying"));
        mouseClick(findChild(item, "exampleButton_next"));
        compare(previousCalls, 1);
        compare(playCalls, 1);
        compare(nextCalls, 1);
        subject.player = ({
                canGoPrevious: false,
                previous: () => testCase.previousCalls++
            });
        verify(!api.canGoPrevious && !api.canTogglePlaying);
        verify(!api.previous());
        compare(previousCalls, 1);
        subject.configuration = {
            customButtons: "",
            useSystemDockBg: true
        };
        tryCompare(subject, "customReady", false);
        compare(findChild(subject, "customButtonsLoader").item, null);
    }
    function test_invalidStyleFallsBack() {
        subject.configuration = {
            customButtons: Qt.resolvedUrl("../package/contents/examples/PulseBars.qml").toString(),
            useSystemDockBg: true
        };
        tryVerify(() => subject.customError !== "");
        verify(!subject.customReady);
        verify(findChild(subject, "prevArea") !== null);
        subject.configuration = {
            customButtons: example,
            useSystemDockBg: true
        };
        tryCompare(subject, "customReady", true);
    }
    function test_cardLayoutsUseCustomButtons_data() {
        return ["classic", "inline", "hero", "stacked", "poster", "orbit", "strip"].map(mode => ({
                    tag: mode,
                    mode: mode
                }));
    }
    function test_cardLayoutsUseCustomButtons(data) {
        const sample = createTemporaryObject(samplePlayerComponent, testCase);
        const view = createTemporaryObject(viewComponent, testCase, {
            configuration: Object.assign({}, defaults, {
                layoutMode: data.mode,
                customButtons: example
            }),
            player: sample
        });
        verify(view !== null);
        const loader = findChild(view, "customButtonsLoader");
        verify(loader !== null);
        tryCompare(loader, "status", Loader.Ready);
    }
    function test_pickerAndPortableLooks() {
        const picker = createTemporaryObject(pickerComponent, testCase);
        picker.importFile(example);
        compare(picker.selected, example);
        compare(picker.library.length, 1);
        const look = Schema.applyPreset(defaults, picker.studio.draft, {
            dockStyle: "soft"
        }, false);
        compare(look.customButtons, "");
        compare(look.customButtonStyles, picker.studio.draft.customButtonStyles);
        const imported = Schema.importPreset(Schema.exportPreset("Buttons", picker.studio.draft, defaults), defaults).settings;
        verify(imported.customButtons === undefined);
        verify(imported.customButtonStyles === undefined);
        compare(Schema.rowPatch({
            k: "dockStyle"
        }, "glass").customButtons, "");
        picker.removeSelected();
        compare(picker.library.length, 0);
    }
}
