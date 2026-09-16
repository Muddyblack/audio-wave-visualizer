import QtQuick
import QtTest
import "../package/contents/ui"

TestCase {
    id: testCase
    name: "SilkRibbon"
    when: windowShown
    visible: true
    width: 160
    height: 50

    Rectangle {
        anchors.fill: parent
        color: "#101016"
    }

    Component {
        id: waveComponent
        Waveform {
            width: 64
            height: 20
            visualizerType: 15
            hasAudio: true
            bars: Array(24).fill(40)
            bass: 0.03
            mid: 0.04
            glowWave: false
            waveColor: "#b4befe"
            reducedMotion: true
        }
    }
    function bodyHeight(wave) {
        waitForRendering(wave);
        wait(80);
        const image = grabImage(wave);
        let pixels = 0;
        for (let y = 0; y < wave.height; y++) {
            if (image.pixel(Math.floor(wave.width / 2), y).b > 0.2)
                pixels++;
        }
        return pixels;
    }
    function test_quietAudioStaysReadableAtPanelSize_data() {
        return [
            {
                tag: "canvas",
                software: true
            },
            {
                tag: "shader",
                software: false
            }
        ];
    }
    function test_quietAudioStaysReadableAtPanelSize(data) {
        if (!data.software && GraphicsInfo.api === GraphicsInfo.Software)
            skip("Shader rendering requires a GPU scene graph");
        const wave = createTemporaryObject(waveComponent, testCase, {
            simpleRender: data.software
        });
        const quiet = bodyHeight(wave);
        verify(quiet >= 5, "Quiet music needs a visible ribbon body, got " + quiet + " px");
        grabImage(wave).save("/tmp/silk-quiet-" + data.tag + ".png");
        wave.bars = Array(24).fill(700);
        wave.bass = 0.6;
        const loud = bodyHeight(wave);
        verify(loud > quiet, "The thicker baseline must retain audio response");
        verify(loud <= quiet * 3, "Demo peaks must not dwarf quieter live audio");
        wave.ribbonFullness = 0.6;
        const narrow = bodyHeight(wave);
        wave.ribbonFullness = 1.3;
        verify(bodyHeight(wave) > narrow, "Fullness must still adjust the body");
    }
}
