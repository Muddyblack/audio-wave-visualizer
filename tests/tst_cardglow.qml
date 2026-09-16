import QtQuick
import QtTest
import "../package/contents/ui"
import "../hyprland/Configuration.js" as Configuration

TestCase {
    id: testCase
    name: "CardGlow"
    when: windowShown
    visible: true
    width: 400
    height: 300

    property var defaults

    function initTestCase() {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../package/contents/config/main.xml"), false);
        request.send();
        defaults = Configuration.defaults(request.responseText);
    }

    Component {
        id: viewComponent
        VisualizerView {
            width: 360
            height: 104
            accentColor: "#a855f7"
            systemTextColor: "#ffffff"
        }
    }

    function test_ambientDesktopGlowSoundReactivity() {
        const fakeVisualizer = Qt.createQmlObject('import QtQuick; QtObject { property real bass: 0.0; property bool plasmoidVisible: true }', testCase);
        const fakePlayer = Qt.createQmlObject('import QtQuick; QtObject { property bool isPlaying: true; property string trackArtist: "Test Artist"; property string trackTitle: "Test Title"; property string trackArtUrl: "" }', testCase);

        const view = createTemporaryObject(viewComponent, testCase, {
            visualizer: fakeVisualizer,
            player: fakePlayer,
            isPlaying: true,
            configuration: Object.assign({}, defaults, {
                showBg: true,
                ambientGlow: true,
                ambientGlowRadius: 75,
                ambientGlowIntensity: 0.8,
                ambientGlowMode: "cover"
            })
        });
        verify(view !== null);

        const ambientGlow = findChild(view, "ambientDesktopGlow");
        verify(ambientGlow !== null, "Ambient desktop glow item must exist when enabled");
        verify(ambientGlow.radialBleed, "Ambient desktop glow must use multi-stop radial bleed");
        compare(ambientGlow.margin, 75);
        compare(ambientGlow.bleedStops.length, 4, "Must have 4 stops for multi-stop bleed falloff");

        // Verify sound reactivity: loader opacity increases with bass energy
        const loader = findChild(view, "ambientGlowLoader");
        verify(loader !== null, "ambientGlowLoader must exist");
        const calmOpacity = loader.opacity;
        verify(calmOpacity > 0);

        // Surge bass kick
        fakeVisualizer.bass = 0.95;
        tryVerify(() => loader.opacity > calmOpacity + 0.1, 500, "Ambient glow opacity must increase on bass kick");

        // When ambientGlow is false, glow item must not exist
        view.configuration = Object.assign({}, view.configuration, {
            ambientGlow: false
        });
        compare(loader.active, false, "Loader must become inactive when ambientGlow is false");
        tryVerify(() => !findChild(view, "ambientDesktopGlow"), 500, "Ambient glow item must be destroyed when disabled");
    }
}
