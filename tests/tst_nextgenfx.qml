import QtQuick
import QtTest
import "../package/contents/ui"
import "../package/contents/code/PreviewAudio.js" as PreviewAudio

TestCase {
    id: testCase
    name: "NextGenFX"
    when: windowShown
    visible: true
    width: 360
    height: 180
    Component {
        id: component
        Waveform {
            width: 320
            height: 160
            hasAudio: true
            bars: Array.from({
                length: 24
            }, (_, i) => 200 + Math.sin(i / 23 * Math.PI) * 600)
            bass: .6
            mid: .5
            high: .4
            visualFrameTime: 2500
            vizColorMode: "palette"
            fillWave: true
            stereoSamples: Array.from({
                length: 32
            }, (_, i) => [Math.sin(i / 31 * Math.PI * 4) * .8, Math.cos(i / 31 * Math.PI * 4) * .8])
        }
    }
    function init() {
        failOnWarning(/TypeError|ReferenceError|Binding loop|Failed to load shader/);
    }
    function lit(image) {
        let count = 0;
        for (let y = 0; y < image.height; y++)
            for (let x = 0; x < image.width; x++) {
                const p = image.pixel(x, y);
                if (Math.max(p.r, p.g, p.b) > .15 && p.a > .1)
                    count++;
            }
        return count;
    }
    function test_stereoPreviewKeepsLoopAcrossPhaseCycle() {
        for (const t of [0, Math.PI / 2, Math.PI, 3 * Math.PI / 2, 2 * Math.PI]) {
            const samples = PreviewAudio.stereo(t);
            compare(samples.length, 32);
            verify(Math.abs(samples[0][1]) > .35, "The preview channels must stay out of phase at t=" + t);
        }
        verify(Math.abs(PreviewAudio.stereo(0)[0][1] - PreviewAudio.stereo(2)[0][1]) > .05, "The loop should still animate");
    }
    function test_visibleAndReducedMotion_data() {
        const rows = [];
        for (const type of [21, 16, 17, 18, 19, 20])
            for (const software of [true, false])
                rows.push({
                    tag: type + (software ? "-canvas" : "-gpu"),
                    type: type,
                    software: software
                });
        return rows;
    }
    function test_visibleAndReducedMotion(row) {
        if (!row.software && GraphicsInfo.api === GraphicsInfo.Software)
            skip("GPU scene graph unavailable");
        const wave = createTemporaryObject(component, testCase, {
            visualizerType: row.type,
            simpleRender: row.software
        });
        verify(wave);
        if (row.type === 21) {
            for (let i = 1; i < 15; i++) {
                wave.visualFrameTime += 17;
                wait(1);
            }
        }
        waitForRendering(wave);
        wait(80);
        let picture = grabImage(wave);
        verify(lit(picture) > 30, "The style must draw visible geometry");
        picture.save("/tmp/nextgen-" + row.tag + ".png");
        wave.reducedMotion = true;
        wait(80);
        const still = grabImage(wave);
        verify(lit(still) > 30, "Reduced motion keeps an audio-reactive still representation");
        wave.visualFrameTime += 4000;
        wait(80);
        verify(still.equals(grabImage(wave)), "Reduced motion freezes time-driven motion");
        wave.hasAudio = false;
        wait(80);
        verify(!still.equals(grabImage(wave)), "Idle state clears the effect");
    }
    function test_tunnelAttackDecaysAndResets() {
        const wave = createTemporaryObject(component, testCase, {
            visualizerType: 17
        });
        const motion = findChild(wave, "waveMotion");
        wave.attack = true;
        wave.visualFrameTime += 17;
        compare(motion.beatPulse, 1);
        wave.attack = false;
        wave.visualFrameTime += 100;
        verify(motion.beatPulse > 0 && motion.beatPulse < 1);
        wave.visible = false;
        compare(motion.beatPulse, 0);
    }
    function test_pcmUniformsPreservePhase() {
        const shader = createTemporaryObject(Qt.createComponent("../package/contents/ui/WaveShader.qml"), testCase, {
            width: 100,
            height: 50,
            hasAudio: true,
            visualizerType: 20,
            stereoSamples: [[.8, -.8], [-.3, .3]],
            previousStereo: [[.4, -.4], [-.2, .2]]
        });
        verify(shader);
        const effect = findChild(shader, "waveEffect");
        compare(effect.scopeCount, 2);
        compare(effect.scope0, Qt.vector4d(.8, -.8, .4, -.4));
        shader.stereoSamples = [];
        compare(effect.scopeCount, 0, "Stale PCM must not survive a cleared frame");
    }
}
