import QtQuick
import QtTest
import "../package/contents/ui"

// WaveShader must keep drawing what WaveCanvas draws. This renders both for
// every style and compares pixels over the dark background most desktops put
// behind the widget. It needs a GPU scene graph, so CI (software) skips it;
// on a desktop run: qmltestrunner -input tests/tst_rendererparity.qml
TestCase {
    id: testCase
    name: "RendererParity"
    when: windowShown
    visible: true
    width: 600
    height: 60

    readonly property var samples: [120, 380, 620, 540, 300, 820, 910, 700, 450, 260, 180, 520, 760, 640, 400, 350, 580, 830, 690, 420, 240, 160, 300, 90]

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
    }

    Component {
        id: canvasComponent
        WaveCanvas {
            y: 8
            width: 276
            height: 44
        }
    }
    Component {
        id: shaderComponent
        WaveShader {
            x: 300
            y: 8
            width: 276
            height: 44
        }
    }

    function rootMeanSquare(a, b) {
        let sum = 0;
        for (let y = 0; y < 44; y++) {
            for (let x = 0; x < 276; x++) {
                const p = a.pixel(x, y);
                const q = b.pixel(x, y);
                sum += (p.r - q.r) ** 2 + (p.g - q.g) ** 2 + (p.b - q.b) ** 2;
            }
        }
        return Math.sqrt(sum / (276 * 44 * 3));
    }

    // Limits sit just above the differences measured when the shader was fitted.
    function test_styles_data() {
        return [
            {
                tag: "wave-fill",
                style: 0,
                fill: true,
                limit: 0.02
            },
            {
                tag: "wave",
                style: 0,
                fill: false,
                limit: 0.02
            },
            {
                tag: "bars",
                style: 1,
                fill: true,
                limit: 0.025
            },
            {
                tag: "mirror-bars",
                style: 2,
                fill: true,
                limit: 0.035
            },
            {
                tag: "tech-line",
                style: 3,
                fill: true,
                limit: 0.025
            },
            {
                tag: "dots",
                style: 4,
                fill: true,
                limit: 0.015
            },
            {
                tag: "rings",
                style: 5,
                fill: true,
                limit: 0.015
            }
        ];
    }

    function test_styles(row) {
        if (GraphicsInfo.api === GraphicsInfo.Software)
            skip("WaveShader needs a GPU scene graph");
        const properties = {
            bars: samples,
            numBars: samples.length,
            hasAudio: true,
            waveColor: "#b4befe",
            lineWidth: 1.8,
            fillWave: row.fill,
            glowWave: true,
            visualizerType: row.style
        };
        const canvas = createTemporaryObject(canvasComponent, testCase, properties);
        const shader = createTemporaryObject(shaderComponent, testCase, properties);
        verify(canvas !== null && shader !== null);
        // The canvas paints on a later frame and its glow layer one after that.
        wait(400);
        const difference = rootMeanSquare(grabImage(canvas), grabImage(shader));
        verify(difference < row.limit, row.tag + " differs from WaveCanvas by " + difference.toFixed(4));
    }
}
