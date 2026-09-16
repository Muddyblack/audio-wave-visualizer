import QtQuick
import QtTest
import "../package/contents/code/CoverPalette.js" as Palette
import "../package/contents/ui"

TestCase {
    name: "CoverColors"
    when: windowShown
    visible: true
    width: 100
    height: 100
    CoverColors {
        id: sampler
        source: Qt.resolvedUrl("fixtures/cover-red-blue.ppm").toString()
    }
    SignalSpy {
        id: paints
        target: sampler
        signalName: "painted"
    }
    function pixels(swatches) {
        let result = [];
        for (const swatch of swatches)
            for (let i = 0; i < swatch[4]; i++)
                result.push(swatch[0], swatch[1], swatch[2], swatch[3]);
        return result;
    }
    function test_rolesAndTransparentPixels() {
        const palette = Palette.extract(pixels([[120, 120, 120, 255, 60], [220, 30, 50, 255, 30], [30, 80, 220, 255, 10], [0, 255, 0, 0, 1000]]));
        verify(Math.abs(palette.dominant.r - 120 / 255) < 0.01);
        verify(palette.vibrant.r > 0.8);
        verify(Qt.colorEqual(palette.muted, palette.dominant));
        verify(palette.secondary.b > palette.secondary.r);
        verify(!Qt.colorEqual(palette.primary, palette.accent));
        compare(Palette.extract([255, 0, 0, 0]), null);
        compare(Palette.extract([]), null);
    }
    function test_singleColorAndNeutral_data() {
        return [
            {
                tag: "red",
                rgb: [255, 0, 0],
                neutral: false
            },
            {
                tag: "black",
                rgb: [0, 0, 0],
                neutral: true
            },
            {
                tag: "white",
                rgb: [255, 255, 255],
                neutral: true
            },
            {
                tag: "gray",
                rgb: [128, 128, 128],
                neutral: true
            }
        ];
    }
    function test_singleColorAndNeutral(data) {
        const palette = Palette.extract(data.rgb.concat([255]));
        const stops = [palette.primary, palette.accent, palette.secondary];
        verify(!Qt.colorEqual(stops[0], stops[1]));
        verify(!Qt.colorEqual(stops[0], stops[2]));
        verify(!Qt.colorEqual(stops[1], stops[2]));
        for (const c of stops) {
            compare(c.a, 1);
            if (data.neutral) {
                verify(Math.abs(c.r - c.g) < 0.001);
                verify(Math.abs(c.g - c.b) < 0.001);
            }
        }
    }
    function test_staticCoverIsSampledOnceAndClears() {
        tryCompare(sampler, "ready", true);
        verify(sampler.primary.r > sampler.primary.b + 0.4);
        verify(sampler.secondary.b > sampler.secondary.r + 0.3);
        paints.clear();
        wait(100);
        compare(paints.count, 0, "A static cover does not keep painting");
        sampler.source = "";
        compare(sampler.ready, false);
        verify(Qt.colorEqual(sampler.primary, sampler.fallback));
        verify(Qt.colorEqual(sampler.dominant, sampler.fallback));
        verify(Qt.colorEqual(sampler.muted, sampler.fallback));
        verify(Qt.colorEqual(sampler.vibrant, sampler.fallback));
        sampler.fallback = "orange";
        for (const c of sampler.gradientStops)
            verify(Qt.colorEqual(c, "orange"));
        sampler.source = Qt.resolvedUrl("fixtures/cover-red-blue.ppm").toString();
        tryCompare(sampler, "ready", true);
        sampler.source = Qt.resolvedUrl("fixtures/nonexistent-cover.png").toString();
        compare(sampler.ready, false);
        for (const c of sampler.gradientStops)
            verify(Qt.colorEqual(c, sampler.fallback));
    }
}
