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
        id: glowComponent
        CardGlow {
            width: 300
            height: 200
            margin: 60
            radius: 16
        }
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

    function test_cardGlowRadialBleedDefaultsAndProperties() {
        const glow = createTemporaryObject(glowComponent, testCase);
        verify(glow !== null);
        compare(glow.margin, 60);
        compare(glow.radius, 16);
        compare(glow.radialBleed, false);
        compare(glow.bleedDistance, 60);
        compare(glow.bleedStops, []);
        compare(glow.bleedColors, []);

        // Enable multi-stop radial bleed
        glow.radialBleed = true;
        glow.bleedDistance = 45;
        glow.bleedStops = [[0.0, Qt.rgba(1, 0, 0, 0.8)], [0.4, Qt.rgba(0.5, 0, 0.5, 0.4)], [1.0, Qt.rgba(0, 0, 0, 0)]];
        verify(glow.radialBleed);
        compare(glow.bleedStops.length, 3);
    }

    function test_cardGlowRadialBleedLayer() {
        const glow = createTemporaryObject(glowComponent, testCase);
        verify(glow !== null);
        glow.layers = [
            {
                radialBleed: true,
                spread: 0,
                bleed: 50,
                stops: [
                    {
                        offset: 0.0,
                        color: Qt.rgba(0, 1, 0, 0.9)
                    },
                    {
                        offset: 0.5,
                        color: Qt.rgba(0, 0.5, 0.5, 0.4)
                    },
                    {
                        offset: 1.0,
                        color: Qt.rgba(0, 0, 0, 0)
                    }
                ]
            }
        ];
        compare(glow.layers.length, 1);
        verify(glow.layers[0].radialBleed);
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
