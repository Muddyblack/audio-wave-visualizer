import QtQuick
import QtTest
import "../package/contents/ui"

TestCase {
    name: "TrackProfile"
    Component {
        id: profileComponent
        TrackProfile {
            commandSourceComponent: Component {
                Item {
                    property var connectedSources: []
                    signal newData(string source, var data)
                    function connectSource(source) {
                        connectedSources = [source];
                    }
                    function disconnectSource(source) {
                        connectedSources = connectedSources.filter(s => s !== source);
                    }
                    function cancelSource(source) {
                        disconnectSource(source);
                    }
                }
            }
        }
    }
    function test_rejectsOldResultsAndClearsWhenHidden() {
        const profile = createTemporaryObject(profileComponent, this, {
            fileUrl: "file:///tmp/one.wav"
        });
        const worker = findChild(profile, "trackProfileWorker");
        tryVerify(() => profile._command !== "");
        const oldCommand = profile._command;
        profile.fileUrl = "file:///tmp/two.wav";
        compare(profile.peaks, []);
        tryVerify(() => profile._command !== "" && profile._command !== oldCommand);
        const response = {
            stdout: JSON.stringify({
                peaks: Array(128).fill(.8),
                chapters: [
                    {
                        start: 1,
                        title: "Verse"
                    }
                ],
                status: "ready"
            })
        };
        worker.item.newData(oldCommand, response);
        compare(profile.peaks.length, 0);
        worker.item.newData(profile._command, response);
        compare(profile.peaks.length, 128);
        compare(profile.chapters[0].title, "Verse");
        profile.active = false;
        compare(profile.peaks, []);
        compare(profile.chapters, []);
    }
    function test_chapterModelValidatesAndOrders() {
        const model = createTemporaryObject(Qt.createComponent("../package/contents/ui/ChapterModel.qml"), this, {
            duration: 60,
            localChapters: [null,
                {
                    start: 30,
                    title: "Drop"
                },
                {
                    start: -1
                },
                {
                    start: 0,
                    title: "Intro"
                },
                {
                    start: 90
                }
            ]
        });
        compare(model.chapters.length, 2);
        compare(model.at(29).title, "Intro");
        compare(model.at(30).title, "Drop");
        model.metadata = {
            chapters: [
                {
                    start: 5,
                    title: "Player cue"
                }
            ]
        };
        compare(model.chapters.length, 1);
        compare(model.at(4), null);
    }
}
