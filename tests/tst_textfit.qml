import QtQuick
import QtTest
import "../package/contents/ui"
import "../package/contents/ui/text"
import "../package/contents/ui/studio/Schema.js" as Schema
import "../package/contents/code/Layouts.js" as LayoutSizes
import "../hyprland/Configuration.js" as Configuration

// Text scales with the system font while cards keep their design size, so every
// layout and preset must still fit at the default font and at the largest scale.
TestCase {
    id: testCase
    name: "TextFit"
    when: windowShown
    visible: true
    width: 500
    height: 360
    property var defaults: {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../package/contents/config/main.xml"), false);
        request.send();
        return Configuration.defaults(request.responseText);
    }
    property real systemPoints
    function initTestCase() {
        systemPoints = SystemText.points;
    }
    function cleanupTestCase() {
        SystemText.points = systemPoints;
    }
    QtObject {
        id: backend
        property var bars: [300, 700, 900, 400]
        property real frameTimeMs: 0
        property real bass: 0
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
            property string artist: "3 Sud Est"
            property string track: "3 Sud Est - De-ar vorbi inima | Video Oficial"
            property string artUrl: ""
            property string desktopEntry: ""
            property real length: 204
            property real position: 71
            property bool canSeek: true
            property bool canGoPrevious: true
            property bool canGoNext: true
            property bool positionSupported: true
            property bool shuffle: false
            property int loopState: 0
            property string album: "Greatest Hits Vol. 2"
            property string identity: "Spotify"
            property var metadata: undefined
            property real volume: 0.5
        }
    }
    Component {
        id: viewComponent
        VisualizerView {
            visualizer: backend
            positionUnitsPerSecond: 1
            samplePlayback: true
            fallbackIcon: Component {
                Item {}
            }
        }
    }
    function test_fits_data() {
        const extras = {
            plain: {},
            album: {
                showAlbum: true
            },
            source: {
                showSource: true,
                showPlayerSwitch: true
            },
            lyric: {
                showLyrics: true
            }
        };
        const rows = [];
        for (const mode of ["classic", "mirrored", "inline", "hero", "stacked", "poster", "strip", "orbit", "pill"])
            for (const extra in extras)
                rows.push({
                    tag: mode + "+" + extra,
                    settings: Object.assign({
                        layoutMode: mode
                    }, extras[extra])
                });
        // Lyrics scrolls its lines past its own clip by design.
        for (const preset of Schema.PRESETS.filter(preset => preset.id !== "lyricsonly"))
            rows.push({
                tag: "preset " + preset.id,
                settings: Schema.applyPreset(defaults, defaults, preset.s, false)
            });
        return [].concat(...[10, 72].map(points => rows.map(row => Object.assign({}, row, {
                    tag: row.tag + " " + points + "pt",
                    points: points
                }))));
    }
    function test_fits(data) {
        SystemText.points = data.points;
        const configuration = Object.assign({}, defaults, data.settings);
        const size = LayoutSizes.size(configuration);
        const view = createTemporaryObject(viewComponent, testCase, {
            configuration: configuration,
            player: createTemporaryObject(playerComponent, testCase),
            width: size[0],
            height: size[1]
        });
        waitForRendering(view);
        const found = {
            texts: [],
            controls: [],
            wave: -1
        };
        collect(view, view, -Infinity, Infinity, found);
        const problems = [];
        for (const control of found.controls)
            if (control.top < -1 || control.bottom > size[1] + 1)
                problems.push("outside the card: " + control.label + " " + control.top + ".." + control.bottom);
        for (const text of found.texts) {
            if (text.top < -1 || text.bottom > size[1] + 1)
                problems.push("outside the card: " + text.label);
            if (text.top < text.clipTop - 1 || text.bottom > text.clipBottom + 1)
                problems.push("cut off: " + text.label);
        }
        found.texts.forEach((a, index) => found.texts.slice(index + 1).forEach(b => {
                if (a.label !== b.label && Math.min(a.right, b.right) - Math.max(a.left, b.left) > 2 && Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top) > 2)
                    problems.push("overlap: " + a.label + " / " + b.label);
            }));
        if (found.wave >= 0 && found.wave < 15)
            problems.push("wave squeezed to " + found.wave);
        compare(problems, []);
    }
    function collect(item, view, clipTop, clipBottom, found) {
        if (!item.visible || item.opacity === 0)
            return;
        const box = item.mapToItem(view, 0, 0, item.width, item.height);
        if (item.clip) {
            clipTop = Math.max(clipTop, box.y);
            clipBottom = Math.min(clipBottom, box.y + box.height);
        }
        if (["canvasLoader", "posterTexture", "orbitCanvas"].includes(item.objectName))
            found.wave = box.height;
        if (["progressBar", "playArea"].includes(item.objectName))
            found.controls.push({
                label: item.objectName,
                top: box.y,
                bottom: box.y + box.height
            });
        if (typeof item.text === "string" && item.text !== "" && item.paintedHeight !== undefined) {
            const painted = Math.min(item.paintedWidth, box.width);
            const left = box.x + (item.horizontalAlignment === Text.AlignHCenter ? (box.width - painted) / 2 : item.horizontalAlignment === Text.AlignRight ? box.width - painted : 0);
            const top = box.y + (item.verticalAlignment === Text.AlignVCenter ? (box.height - item.paintedHeight) / 2 : item.verticalAlignment === Text.AlignBottom ? box.height - item.paintedHeight : 0);
            found.texts.push({
                label: item.text.slice(0, 16),
                left: left,
                right: left + painted,
                top: top,
                bottom: top + item.paintedHeight,
                clipTop: clipTop,
                clipBottom: clipBottom
            });
        }
        for (const child of item.children)
            collect(child, view, clipTop, clipBottom, found);
    }
}
