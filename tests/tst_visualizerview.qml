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
    function test_coveredViewPausesPlaybackClock() {
        subject.isPlaying = true;
        const clock = findChild(subject, "positionClock");
        verify(clock.active && clock.ticking);
        backend.plasmoidVisible = false;
        verify(!clock.active && !clock.ticking);
        const covered = clock.displayedPosition;
        wait(50);
        backend.frameTimeMs = Date.now();
        compare(clock.displayedPosition, covered, "Covered views ignore audio frames");
        backend.plasmoidVisible = true;
        verify(clock.active && clock.ticking);
        verify(clock.displayedPosition > covered, "Uncovering catches up playback");
    }
    function test_styles_data() {
        return [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(style => ({
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
    function test_timeLabelsAndFormat() {
        const bar = findChild(subject, "progressBar");
        compare(bar.implicitHeight, 18);
        compare(findChild(subject, "totalTimeLabel").text, "3:00");
        subject.configuration = Object.assign({}, defaults, {
            timeFormat: "remaining"
        });
        compare(findChild(subject, "totalTimeLabel").text, "-2:00");
        subject.configuration = Object.assign({}, defaults, {
            showTimes: false
        });
        compare(bar.implicitHeight, 9);
        verify(!findChild(subject, "elapsedTimeLabel").visible);
        verify(!findChild(subject, "totalTimeLabel").visible);
        // Time only keeps its labels even with time labels switched off.
        subject.configuration = Object.assign({}, defaults, {
            showTimes: false,
            progressBarStyle: 9
        });
        compare(bar.implicitHeight, 12);
        verify(findChild(subject, "timeOnlyRow").visible);
        compare(findChild(subject, "timeOnlyElapsed").text, "1:00");
        compare(findChild(subject, "timeOnlyTotal").text, "3:00");
    }

    function test_squiggleSettlesWhenPausedOrReduced() {
        subject.configuration = Object.assign({}, defaults, {
            progressBarStyle: 5
        });
        const seek = findChild(subject, "lineSeek");
        verify(seek.visible);
        compare(seek.amplitude, 0);
        subject.isPlaying = true;
        tryCompare(seek, "amplitude", 2.2);
        subject.configuration = Object.assign({}, defaults, {
            progressBarStyle: 5,
            reducedMotion: true
        });
        tryCompare(seek, "amplitude", 0);
        compare(seek.phase, 0, "A flat squiggle does not repaint on audio frames");
    }

    function test_coverRingReplacesBar() {
        subject.configuration = Object.assign({}, defaults, {
            progressBarStyle: 10
        });
        const bar = findChild(subject, "progressBar");
        const ring = findChild(subject, "coverRing");
        verify(!bar.visible, "The ring shows progress instead of the bar");
        verify(ring.visible);
        fuzzyCompare(ring.progress, 1 / 3, 0.01);
        verify(ring.parent.width <= 66, "The cover shrinks to make room for the ring");
        subject.configuration = Object.assign({}, defaults, {
            progressBarStyle: 10,
            showArtThumb: false
        });
        verify(!ring.visible);
        verify(bar.visible);
        compare(bar.style, 0, "Without a cover the ring falls back to the default bar");
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

    function test_coverPaletteAndStyleReachTheVisibleWave() {
        subject.configuration = Object.assign({}, defaults, {
            visualizerType: 15,
            vizColorMode: "cover",
            accentFromArt: true,
            simpleRender: true,
            ribbonCurvature: 0.75,
            bloom: 1.25
        });
        subject.coverPalette = {
            dominant: Qt.rgba(1, 0, 0, 1),
            dominantContrast: Qt.rgba(0, 0, 1, 1),
            highlight: Qt.rgba(0, 1, 0, 1)
        };
        const loader = findChild(subject, "canvasLoader");
        tryVerify(() => loader.item !== null);
        compare(loader.item.visualizerType, 15);
        compare(loader.item.ribbonCurvature, 0.75);
        compare(loader.item.bloom, 1.25);
        verify(Qt.colorEqual(loader.item.waveColor, "lime"));
        verify(Qt.colorEqual(loader.item.coverColor1, "red"));
        verify(Qt.colorEqual(loader.item.coverColor2, "blue"));
        subject.coverPalette = null;
        player.artUrl = Qt.resolvedUrl("fixtures/cover-red-blue.ppm").toString();
        tryVerify(() => subject.coverColor1.r > 0.9 && subject.coverColor1.g < 0.1);
        tryVerify(() => subject.coverColor2.b > 0.9);
        subject.player = null;
        verify(Qt.colorEqual(loader.item.waveColor, subject.baseWaveColor), "No stale cover accent after player removal");
    }
}
