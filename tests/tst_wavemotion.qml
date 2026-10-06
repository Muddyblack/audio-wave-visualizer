import QtQuick
import QtTest
import "../package/contents/ui"
import "../package/contents/code/WaveMath.js" as WaveMath

TestCase {
    name: "WaveMotion"
    when: windowShown
    Component {
        id: motionComponent
        WaveMotion {
            width: 320
            height: 64
            numBars: 24
            bars: Array(24).fill(800)
            active: true
        }
    }
    property var subject
    function init() {
        subject = createTemporaryObject(motionComponent, this);
        verify(subject !== null);
    }
    function test_peakHoldAndDecayUseOnlyNewAudioFrames() {
        subject.style = 6;
        subject.frameTime = 1000;
        fuzzyCompare(subject.peaks[12], 0.8, 1e-6);
        subject.bars = Array(24).fill(100);
        compare(subject.peaks[12], 0.8);
        subject.advance();
        compare(subject.peaks[12], 0.8, "Painting or reading again cannot advance state");
        subject.frameTime += 1000 / 60;
        fuzzyCompare(subject.peaks[12], 0.79, 1e-6);
        subject.active = false;
        compare(subject.peaks, []);
        subject.frameTime += 100;
        compare(subject.peaks, []);
    }
    function test_originalSparklesKeepTheirVerticalDrift() {
        subject.style = 14;
        subject.bars = Array(24).fill(0);
        subject.frameTime = 1000;
        subject.particles = [
            {
                x: 80,
                y: 40,
                vy: -1,
                r: 1,
                life: .9
            }
        ];
        subject.frameTime += 1000 / 60;
        compare(subject.particles.length, 1);
        const p = subject.particles[0];
        fuzzyCompare(p.x, 80, 1e-6);
        fuzzyCompare(p.y, 39, 1e-6);
        fuzzyCompare(p.vy, -1, 1e-6);
        fuzzyCompare(p.life, .875, 1e-6);
        verify(p.vx === undefined, "Original Sparkles must not acquire gravity or lateral turbulence");
    }
    function test_gravitySparksAreASeparateStyle() {
        subject.style = 21;
        subject.bars = Array(24).fill(0);
        subject.frameTime = 1000;
        subject.particles = [
            {
                x: 80,
                y: 40,
                vx: 1,
                vy: -1,
                r: 1,
                life: .9
            }
        ];
        subject.frameTime += 1000 / 60;
        compare(subject.particles.length, 1);
        verify(subject.particles[0].x > 80);
        verify(subject.particles[0].vy > -1);
        subject.style = 14;
        compare(subject.particles.length, 0, "Switching variants clears their different physics states");
    }
    function test_particlesStayBoundedAndDeterministic() {
        subject.style = 14;
        const other = createTemporaryObject(motionComponent, this, {
            style: 14
        });
        for (let i = 1; i <= 240; i++) {
            subject.frameTime = i * 1000 / 60;
            other.frameTime = subject.frameTime;
            verify(subject.particles.length <= 32);
            compare(subject.particles, other.particles);
        }
        verify(subject.particles.length > 0);
        subject.reducedMotion = true;
        compare(subject.particles, []);
        for (let i = 1; i < 10; i++)
            subject.frameTime += 17;
        compare(subject.particles, []);
    }
    function test_ripplesRequireAttackAndStayBounded() {
        subject.style = 15;
        subject.frameTime = 1000;
        compare(subject.ripples, []);
        subject.attack = true;
        for (let i = 0; i < 20; i++)
            subject.frameTime += 17;
        verify(subject.ripples.length > 0 && subject.ripples.length <= 4);
        subject.attack = false;
        for (let i = 0; i < 120; i++)
            subject.frameTime += 17;
        compare(subject.ripples, []);
        subject.style = 0;
        compare(subject.particles, []);
        compare(subject.peaks, []);
    }
    function test_paletteColoursAndDefaults() {
        const accent = Qt.rgba(0.4, 0.6, 0.8, 0.7);
        const solid = WaveMath.colorStops(accent, "solid", "aurora", "red", "blue", false, 0.5, 20, false);
        verify(Qt.colorEqual(solid[0], accent));
        const aurora = WaveMath.colorStops(accent, "palette", "aurora", "red", "blue", false, 0.5, 0, false);
        compare(aurora.length, 3);
        verify(Qt.colorEqual(aurora[0], "#5ef2c1"));
        verify(Qt.colorEqual(aurora[1], "#4aa8ff"));
        verify(Qt.colorEqual(aurora[2], "#b57bff"));
        const cover = WaveMath.colorStops(accent, "cover", "aurora", "red", "blue", false, 0.5, 0, false);
        verify(Qt.colorEqual(cover[0], "red") && Qt.colorEqual(cover[1], accent) && Qt.colorEqual(cover[2], "blue"));
        const shifted = WaveMath.shiftHue("red", 120);
        // QColor retains its HSL/RGB storage spec; compare the rendered channels.
        compare(shifted.r, 0);
        compare(shifted.g, 1);
        compare(shifted.b, 0);
        compare(shifted.a, 1);
    }
    function test_customRangeAnyLengthAndShaderLimit() {
        const list = "#ff0000, #00ff00;#0000ff,not-a-colour,#ffffff,#000000,#123456,#abcdef";
        compare(WaveMath.parseColors(list).length, 7);
        const stops = WaveMath.colorStops("red", "custom", list, "red", "blue", false, 0.5, 0, false);
        compare(stops.length, 7);
        verify(Qt.colorEqual(stops[1], "#00ff00"));
        // An empty or invalid list falls back to the accent instead of blanking.
        const fallback = WaveMath.colorStops("#336699", "custom", "oops", "red", "blue", false, 0.5, 0, false);
        compare(fallback.length, 1);
        verify(Qt.colorEqual(fallback[0], "#336699"));
        const limited = WaveMath.limitStops(stops, 6);
        compare(limited.length, 6);
        verify(Qt.colorEqual(limited[0], "#ff0000"));
        verify(Qt.colorEqual(limited[5], "#abcdef"));
        compare(WaveMath.limitStops(["red", "blue"], 6).length, 2);
        compare(WaveMath.hexOf("#336699"), "#336699");
    }
    function test_glowTintUsesOwnRangeOrNothing() {
        compare(WaveMath.glowTint("", 0, false).a, 0);
        const middle = WaveMath.glowTint("#000000,#ff0000,#0000ff", 5, true);
        verify(Qt.colorEqual(middle, "#ff0000"));
        compare(WaveMath.glowTint("#000000,#ffffff", 3, false).a, 1);
    }
    function test_reducedMotionFreezesRainbowAndHueDrift() {
        for (const mode of ["solid", "gradient", "palette", "rainbow"]) {
            const first = WaveMath.colorStops("#b4befe", mode, "iris", "red", "blue", true, 0, 0, true);
            const last = WaveMath.colorStops("#b4befe", mode, "iris", "red", "blue", true, 1, 500, true);
            compare(first, last);
        }
        const rainbow = WaveMath.colorStops("red", "rainbow", "iris", "red", "blue", false, 0.5, 0, false);
        const moved = WaveMath.colorStops("red", "rainbow", "iris", "red", "blue", false, 0.5, 1, false);
        compare(rainbow.length, 6);
        verify(!Qt.colorEqual(rainbow[0], moved[0]));
    }
}
