.pragma library
.import "WaveMath.js" as Colors

// Material You-inspired tonal roles, without a platform dependency. Quantize
// RGB (including neutrals) before scoring: hue-only buckets lose both muted
// detail and the actual population of the dominant colour.
function extract(pixels) {
    const buckets = {};
    let total = 0;
    for (let i = 0; i < pixels.length; i += 4) {
        const weight = pixels[i + 3] / 255;
        if (weight < 0.5)
            continue;
        const r = pixels[i], g = pixels[i + 1], b = pixels[i + 2];
        const key = (r >> 4) * 256 + (g >> 4) * 16 + (b >> 4);
        const bin = buckets[key] || (buckets[key] = [0, 0, 0, 0]);
        bin[0] += r * weight;
        bin[1] += g * weight;
        bin[2] += b * weight;
        bin[3] += weight;
        total += weight;
    }
    if (!total)
        return null;
    const swatches = Object.keys(buckets).map(key => {
        const bin = buckets[key];
        const color = Qt.rgba(bin[0] / bin[3] / 255, bin[1] / bin[3] / 255, bin[2] / bin[3] / 255, 1);
        return { color: color, hsl: Colors.hsl(color), population: bin[3] / total };
    }).sort((a, b) => b.population - a.population || a.hsl[0] - b.hsl[0]);
    const dominant = swatches[0];
    // Suppress tiny compression speckles and near-black/white as role seeds.
    const usable = swatches.filter(s => s.population >= 0.01 && s.hsl[2] > 0.08 && s.hsl[2] < 0.92);
    function best(candidates, score) {
        let chosen = null, highest = -Infinity;
        for (const s of candidates) {
            const value = score(s);
            if (value > highest) {
                chosen = s;
                highest = value;
            }
        }
        return chosen;
    }
    const vibrant = best(usable.filter(s => s.hsl[1] >= 0.35),
        s => 0.5 * s.hsl[1] + 0.35 * Math.sqrt(s.population) + 0.15 * (1 - Math.abs(s.hsl[2] - 0.5) * 2));
    const seed = vibrant || dominant;
    const muted = best(usable.filter(s => s.hsl[1] < 0.35),
        s => 0.6 * Math.sqrt(s.population) + 0.4 * (1 - s.hsl[1]));
    function hueDistance(a, b) {
        const d = Math.abs(a - b);
        return Math.min(d, 360 - d);
    }
    const accent = best(usable.filter(s => s.hsl[1] >= 0.35 && hueDistance(s.hsl[0], seed.hsl[0]) >= 30),
        s => 0.45 * Math.sqrt(s.population) + 0.25 * s.hsl[1] + 0.3 * (1 - Math.abs(hueDistance(s.hsl[0], seed.hsl[0]) - 60) / 180));
    function tone(s, saturation, lightness, rotation) {
        return Qt.hsla(((s.hsl[0] + (rotation || 0)) % 360) / 360, saturation, lightness, 1);
    }
    // Neutral artwork stays neutral; single-colour art gains related tonal
    // stops rather than repeating a colour or importing the system accent.
    const chroma = seed.hsl[1];
    const primary = tone(seed, Math.min(0.85, chroma), 0.65);
    const secondary = accent ? tone(accent, Math.min(0.7, accent.hsl[1]), 0.72)
        : tone(seed, Math.min(0.45, chroma * 0.6), 0.8, chroma >= 0.35 ? 30 : 0);
    const highlight = tone(seed, Math.min(0.9, chroma), 0.48);
    return {
        dominant: dominant.color,
        vibrant: vibrant ? vibrant.color : primary,
        muted: muted ? muted.color : tone(seed, Math.min(0.25, chroma * 0.4), 0.7),
        accent: highlight,
        primary: primary,
        secondary: secondary
    };
}
