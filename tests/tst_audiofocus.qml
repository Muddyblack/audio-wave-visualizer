import QtQuick
import QtTest
import "../package/contents/code/WaveMath.js" as WaveMath

TestCase {
    name: "AudioFocus"
    function test_defaultPreservesBins() {
        compare(WaveMath.focusBands([20, 50, 90, 120], 50, 10000, "log", 1, 1, 1000), [20, 50, 90, 120]);
    }
    function test_melKeepsUniformSpectrumAndBounds() {
        compare(WaveMath.focusBands([300, 300, 300, 300], 50, 10000, "mel", 1, 1, 1000), [300, 300, 300, 300]);
        const focused = WaveMath.focusBands([0, 250, 500, 1000], 50, 10000, "mel", 1, 1, 1000);
        verify(focused[0] > 0, "Mel redistributes the logarithmic samples");
        for (let i = 0; i < focused.length; i++) {
            verify(focused[i] >= 0 && focused[i] <= 1000);
            if (i)
                verify(focused[i] >= focused[i - 1]);
        }
    }
    function test_weightingUsesFrequency() {
        const focused = WaveMath.focusBands(Array(32).fill(400), 50, 10000, "log", 2, 0.5, 1000);
        compare(focused[0], 800);
        compare(focused[16], 400);
        compare(focused[31], 200);
    }
    function test_releaseIndependentOfFrameRate() {
        const one = WaveMath.releaseBlend(1000, 0, 100, 350);
        let many = 1000;
        for (let i = 0; i < 10; i++)
            many = WaveMath.releaseBlend(many, 0, 10, 350);
        fuzzyCompare(one, many, 1e-9);
        compare(WaveMath.releaseBlend(1000, 0, 10, 0), 0);
        compare(WaveMath.releaseBlend(0.1, 0, 10, 350), 0);
    }
    function test_energyDerivative() {
        compare(WaveMath.energyRise(1, 0, 100), 10);
        compare(WaveMath.energyRise(0, 1, 100), 0);
        compare(WaveMath.energyRise(1, 1, 100), 0);
        compare(WaveMath.energyRise(1, 0, 0), 0);
    }
}
