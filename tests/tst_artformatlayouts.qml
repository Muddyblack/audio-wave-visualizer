import QtQuick
import QtTest
import "../package/contents/ui"
import "../package/contents/ui/studio/Schema.js" as Schema
import "../package/contents/code/Layouts.js" as LayoutSizes
import "../hyprland/Configuration.js" as Configuration
import "../package/contents/code/PresentationSettings.js" as Presentations

TestCase {
    id: testCase
    name: "ArtFormatLayouts"
    when: windowShown
    visible: true
    width: 600
    height: 400
    property var defaults: {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../package/contents/config/main.xml"), false);
        request.send();
        return Configuration.defaults(request.responseText);
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
            property string track: "De-ar vorbi inima"
            property string artUrl: Qt.resolvedUrl("fixtures/cover-red-blue.ppm")
            property string desktopEntry: ""
            property real length: 204
            property real position: 71
            property bool canSeek: true
            property bool canGoPrevious: true
            property bool canGoNext: true
            property bool positionSupported: true
            property bool shuffle: false
            property int loopState: 0
            property string album: ""
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
    function arts(item, out) {
        if (item.ratio !== undefined && item.letterbox !== undefined && item.visible && item.width > 0)
            out.push(item);
        for (let i = 0; i < item.children.length; ++i)
            arts(item.children[i], out);
        return out;
    }
    function find(item, name) {
        if (item.objectName === name)
            return item;
        for (let i = 0; i < item.children.length; ++i) {
            const found = find(item.children[i], name);
            if (found)
                return found;
        }
        return null;
    }
    function make(configuration) {
        const size = LayoutSizes.size(configuration);
        const view = createTemporaryObject(viewComponent, testCase, {
            configuration: configuration,
            player: createTemporaryObject(playerComponent, testCase),
            width: size[0],
            height: size[1]
        });
        waitForRendering(view);
        return view;
    }
    // Wide 16:9 must widen the cover in every look that shows one, on the
    // desktop card and in the panel popup, not only in some presets (#21).
    function test_wideCoverInEveryPreset_data() {
        const rows = [];
        for (const p of Schema.PRESETS)
            for (const target of ["desktop", "popup"])
                rows.push({
                    tag: p.id + " " + target,
                    s: p.s,
                    target: target
                });
        return rows;
    }
    function test_wideCoverInEveryPreset(data) {
        const look = Object.assign(Schema.applyPreset(defaults, defaults, data.s, false), {
            artFormat: "wide"
        });
        const configuration = data.target === "popup" ? Presentations.resolve(look, "popup") : look;
        const view = make(configuration);
        for (const art of arts(view, [])) {
            if (art.shape === "circle" || art.disc || art.width < 24)
                continue;
            tryVerify(() => Math.abs(art.width / art.height - 16 / 9) < 0.06, 2000, art.objectName + " " + art.width + "x" + art.height);
        }
    }
    // Inside an orbit the wide box keeps the square cover's diagonal.
    function test_wideCoverStaysInsideTheRing() {
        const p = Schema.PRESETS.find(p => p.id === "sunburst");
        const view = make(Object.assign(Schema.applyPreset(defaults, defaults, p.s, false), {
            artFormat: "wide"
        }));
        const orbit = find(view, "orbitCanvas");
        const art = arts(view, [])[0];
        tryVerify(() => art.ratio > 1.7);
        verify(Math.hypot(art.width, art.height) <= orbit.coverRatio * orbit.width * Math.SQRT2 + 1, "Cover diagonal fits the hole");
    }
    function test_presetsKeepTheArtworkFormat() {
        const current = Object.assign({}, defaults, {
            artFormat: "squareEdges"
        });
        for (const p of Schema.PRESETS)
            compare(Schema.applyPreset(defaults, current, p.s, false).artFormat, "squareEdges", p.id);
        compare(Schema.restoreDefaults(defaults, current).artFormat, defaults.artFormat, "Defaults still resets it");
    }
    function test_titleInsideTheRing() {
        const p = Schema.PRESETS.find(p => p.id === "spectrum");
        const view = make(Schema.applyPreset(defaults, defaults, p.s, false));
        const orbit = find(view, "orbitCanvas");
        verify(find(view, "orbitGlowRing").visible, "Glow ring shown");
        const centre = orbit.mapToItem(view, orbit.width / 2, orbit.height / 2);
        const hole = orbit.coverRatio * orbit.width / 2;
        const titles = [];
        (function walk(item) {
                if (item.visible && typeof item.text === "string" && item.text.indexOf("De-ar") !== -1 && item.paintedWidth !== undefined)
                    titles.push(item);
                for (let i = 0; i < item.children.length; ++i)
                    walk(item.children[i]);
            })(view);
        compare(titles.length, 1, "One title, inside the ring");
        const box = titles[0].mapToItem(view, 0, 0, titles[0].width, titles[0].height);
        for (const [x, y] of [[box.x, box.y], [box.x + box.width, box.y + box.height]])
            verify(Math.hypot(x - centre.x, y - centre.y) <= hole + 1, "Title corner inside the hole");
    }
}
