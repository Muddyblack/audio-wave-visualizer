import QtQuick
import QtTest
import "../package/contents/ui"
import "../hyprland/Configuration.js" as Configuration

TestCase {
    id: testCase
    name: "VisualizerView"
    when: windowShown
    visible: true
    width: 400
    height: 140
    property var defaults
    property var subject
    property var player

    function initTestCase() {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../package/contents/config/main.xml"), false);
        request.send();
        defaults = Configuration.defaults(request.responseText);
        compare(defaults.numBars, 24);
        compare(defaults.artBgBlur, 0.22);
        compare(defaults.showMpris, true);
        compare(defaults.customColor, "#a855f7");
    }
    QtObject {
        id: backend
        property var bars: [300, 700, 900, 400]
        property real frameTimeMs: 0
        property int numBars: 4
        property real maxRange: 1000
        property bool hasAudio: true
        property bool backendFailed: false
        property bool plasmoidVisible: true
        property string backendCode: ""
        property string backendMessage: ""
        property string backendAction: ""
        property string backendHint: ""
    }
    Component {
        id: playerComponent
        QtObject {
            property string artist: "Artist"
            property string track: "Track"
            property string artUrl: ""
            property string desktopEntry: ""
            property real length: 180
            property real position: 60
            property bool canSeek: true
            property bool positionSupported: true
            property int previousCalls: 0
            property int playCalls: 0
            property int nextCalls: 0
            function previous() {
                previousCalls++;
            }
            function togglePlaying() {
                playCalls++;
            }
            function next() {
                nextCalls++;
            }
        }
    }
    Component {
        id: viewComponent
        VisualizerView {
            width: 360
            height: 104
            visualizer: backend
            positionUnitsPerSecond: 1
            fallbackIcon: Component {
                Item {}
            }
        }
    }
    function init() {
        player = createTemporaryObject(playerComponent, this);
        subject = createTemporaryObject(viewComponent, this, {
            configuration: Object.assign({}, defaults),
            player: player
        });
        verify(subject !== null);
        waitForRendering(subject);
    }
    function test_controlsAndSeeking() {
        mouseClick(findChild(subject, "prevArea"));
        mouseClick(findChild(subject, "playArea"));
        mouseClick(findChild(subject, "nextArea"));
        compare(player.previousCalls, 1);
        compare(player.playCalls, 1);
        compare(player.nextCalls, 1);
        const seek = findChild(subject, "pbArea");
        mouseClick(seek, seek.width / 2, seek.height / 2);
        verify(Math.abs(player.position - 90) < 2);
        player.canSeek = false;
        mouseClick(seek, seek.width / 4, seek.height / 2);
        verify(Math.abs(player.position - 90) < 2);
    }

    function test_progressUsesAudioFramesWithSlowFallback() {
        subject.isPlaying = true;
        const clock = findChild(subject, "positionClock");
        compare(clock.updateInterval, 1000);
        const before = clock.displayedPosition;
        wait(150);
        compare(clock.displayedPosition, before, "No independent 20 Hz progress ticker");
        backend.frameTimeMs = Date.now();
        verify(clock.displayedPosition > before, "A fresh waveform frame advances playback");
        subject.visible = false;
        const hidden = clock.displayedPosition;
        wait(50);
        backend.frameTimeMs = Date.now();
        compare(clock.displayedPosition, hidden, "Hidden views do not tick on audio frames");
    }
    function test_styles_data() {
        return [0, 1, 2, 3, 4].map(style => ({
                    tag: "progress-" + style,
                    style: style
                }));
    }
    function test_styles(data) {
        subject.configuration = Object.assign({}, defaults, {
            progressBarStyle: data.style,
            showBg: true
        });
        waitForRendering(subject);
        const clock = findChild(subject, "positionClock");
        compare(clock.elapsedText, "1:00");
        compare(clock.totalText, "3:00");
        verify(grabImage(subject).width > 0);
    }
    function test_playerChangesClearOldArtwork() {
        player.artUrl = Qt.resolvedUrl("../readme/album_art.png").toString();
        compare(subject.artUrl, player.artUrl);
        subject.player = null;
        compare(subject.artUrl, "");
        verify(!subject.shouldShow);
        subject.configuration = Object.assign({}, defaults, {
            alwaysVisible: true
        });
        verify(subject.shouldShow);
    }
}
