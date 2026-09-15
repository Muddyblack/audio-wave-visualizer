import QtQuick
import QtTest
import "../package/contents/ui"

// The software scene graph skips ShaderEffect, so these check what WaveShader
// feeds the GPU; tst_rendererparity.qml compares pixels on a desktop.
TestCase {
    id: testCase
    name: "WaveShader"
    when: windowShown
    visible: true
    width: 400
    height: 120

    Component {
        id: shaderComponent
        WaveShader {
            width: 320
            height: 44
            numBars: 6
        }
    }
    Component {
        id: canvasComponent
        WaveCanvas {
            width: 320
            height: 44
        }
    }
    Component {
        id: waveformComponent
        Waveform {
            width: 320
            height: 44
        }
    }

    property var subject: null
    property var effect: null

    function init() {
        subject = createTemporaryObject(shaderComponent, testCase);
        verify(subject !== null);
        effect = findChild(subject, "waveEffect");
        verify(effect !== null);
    }

    function uploaded() {
        const blocks = [effect.levels0, effect.levels1];
        const values = [];
        for (const block of blocks)
            values.push(block.x, block.y, block.z, block.w);
        return values;
    }

    function test_uploadsCanvasLevels() {
        const bars = [100, 400, 800, 1000, 500, 250];
        subject.bars = bars;
        subject.hasAudio = true;
        const canvas = createTemporaryObject(canvasComponent, testCase, {
            numBars: bars.length
        });
        const values = uploaded();
        compare(effect.barCount, bars.length);
        for (let i = 0; i < bars.length; i++)
            fuzzyCompare(values[i], bars[i] / 1000 * canvas._tapers[i], 1e-6, "Bar " + i + " must match WaveCanvas");
        compare(values[6], 0, "Unused slots stay empty");
        compare(values[7], 0, "Unused slots stay empty");
    }

    function test_idleHiddenAndFailedFramesSkipUploads() {
        subject.hasAudio = true;
        subject.bars = [500, 500, 500, 500, 500, 500];
        fuzzyCompare(uploaded()[1], 0.5, 1e-6);

        subject.hasAudio = false;
        subject.bars = [900, 900, 900, 900, 900, 900];
        fuzzyCompare(uploaded()[1], 0.5, 1e-6, "Idle frames must not upload");
        subject.hasAudio = true;
        fuzzyCompare(uploaded()[1], 0.9, 1e-6, "Audio resuming uploads the latest frame");

        subject.visible = false;
        subject.bars = [200, 200, 200, 200, 200, 200];
        fuzzyCompare(uploaded()[1], 0.9, 1e-6, "Hidden frames must not upload");
        subject.visible = true;
        fuzzyCompare(uploaded()[1], 0.2, 1e-6, "Showing uploads the latest frame");

        subject.backendFailed = true;
        subject.bars = [700, 700, 700, 700, 700, 700];
        fuzzyCompare(uploaded()[1], 0.2, 1e-6, "A failed backend must not upload");
        subject.backendFailed = false;
        fuzzyCompare(uploaded()[1], 0.7, 1e-6);
    }

    function test_statesShowIdleLineOrEffect() {
        const idleLine = findChild(subject, "idleLine");
        verify(idleLine !== null);
        subject.hasAudio = false;
        verify(idleLine.visible && !effect.visible);
        subject.hasAudio = true;
        verify(!idleLine.visible && effect.visible);
        subject.backendFailed = true;
        verify(!idleLine.visible && !effect.visible, "The failure text needs an empty waveform");
    }

    function test_barCountIsCapped() {
        subject.numBars = 200;
        subject.bars = Array(200).fill(1000);
        subject.hasAudio = true;
        compare(effect.barCount, 128);
        fuzzyCompare(effect.levels15.x, 1, 1e-6, "Bar 60 is outside the edge taper");
        fuzzyCompare(effect.levels31.w, 0, 1e-6, "The last uploaded bar is the tapered edge");
    }

    function test_appearanceReachesUniforms() {
        subject.visualizerType = 4;
        subject.fillWave = false;
        subject.glowWave = false;
        subject.lineWidth = 3;
        subject.waveColor = "#eb408a";
        compare(effect.style, 4);
        compare(effect.fillAmount, 0);
        compare(effect.glowAmount, 0);
        compare(effect.lineWidth, 3);
        verify(Qt.colorEqual(effect.waveColor, "#eb408a"));
        compare(effect.canvasSize, Qt.size(320, 44));
    }

    function test_softwareSceneGraphUsesCanvas() {
        if (GraphicsInfo.api !== GraphicsInfo.Software)
            skip("Only the software scene graph falls back to WaveCanvas");
        const waveform = createTemporaryObject(waveformComponent, testCase, {
            bars: [300, 700, 900, 400],
            numBars: 4,
            hasAudio: true
        });
        verify(waveform !== null);
        verify(!waveform.shaderSupported);
        compare(findChild(waveform, "shaderLoader").item, null);
        const canvas = findChild(waveform, "canvasLoader").item;
        verify(canvas !== null);
        waveform.waveColor = "#42aed9";
        verify(Qt.colorEqual(canvas.waveColor, "#42aed9"), "Waveform forwards appearance to its renderer");
        compare(canvas.bars, waveform.bars);
    }
}
