.pragma library

// Shared colour and level preparation for both renderers. The six original
// styles retain their historical count and cosine taper.
function count(requested, width, style) {
    const n = Math.max(0, Math.min(128, Math.floor(requested)));
    if (style < 6)
        return n;
    const dense = style === 7 || style === 12 || style === 14 || style === 21;
    return Math.max(6, Math.min(n, Math.floor(width / (dense ? 4 : 2.5))));
}

function levels(bars, n, range) {
    const result = new Array(n);
    for (let i = 0; i < n; i++) {
        const p = n > 1 ? i / (n - 1) : 0.5;
        const edge = 0.15;
        const weight = p < edge ? p / edge : (p > 1 - edge ? (1 - p) / edge : 1);
        const taper = weight < 1 ? 0.5 - 0.5 * Math.cos(weight * Math.PI) : 1;
        result[i] = range > 0 ? (bars[i] || 0) / range * taper : 0;
    }
    return result;
}

var palettes = {
    aurora: ["#5ef2c1", "#4aa8ff", "#b57bff"],
    ember: ["#ffc36b", "#ff6a3d", "#d6246e"],
    ice: ["#e6f9ff", "#86d6ff", "#3a7bd5"],
    grove: ["#d8f59a", "#6fcf6f", "#1f8a70"],
    iris: ["#cdb8ff", "#8f6bff", "#ff7ad9"],
    coral: ["#ffd6b8", "#ff8a7a", "#ff4f81"]
};

function color(value) {
    return typeof value === "string" ? Qt.tint(value, "transparent") : value;
}

function hsl(value) {
    const c = color(value);
    const max = Math.max(c.r, c.g, c.b), min = Math.min(c.r, c.g, c.b);
    const l = (max + min) / 2, d = max - min;
    if (d === 0)
        return [0, 0, l];
    const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    const h = max === c.r ? (c.g - c.b) / d + (c.g < c.b ? 6 : 0)
        : max === c.g ? (c.b - c.r) / d + 2 : (c.r - c.g) / d + 4;
    return [h * 60, s, l];
}

function shiftHue(value, degrees) {
    const c = color(value), parts = hsl(c);
    return Qt.hsla(((parts[0] + degrees) % 360 + 360) % 360 / 360, parts[1], parts[2], c.a);
}

function colorStops(accent, mode, palette, cover1, cover2, reactive, high, seconds, reducedMotion) {
    const t = reducedMotion ? 0 : seconds;
    let stops;
    switch (mode) {
    case "gradient": stops = [accent, shiftHue(accent, 55)]; break;
    case "cover": stops = [cover1, accent, cover2]; break;
    case "palette": stops = palettes[palette] || palettes.aurora; break;
    case "rainbow":
        return [0, 60, 120, 180, 240, 300].map(h => Qt.hsla(((h + t * 24) % 360 + 360) % 360 / 360, 0.85, 0.65, 1));
    default: stops = [accent];
    }
    const drift = reactive && !reducedMotion ? Math.sin(t * 0.15) * 20 + (high - 0.5) * 14 : 0;
    return stops.map(c => drift ? shiftHue(c, drift) : color(c));
}

// CAVA emits logarithmic frequency bins. Remap bin centres for mel spacing;
// this is display interpolation, not a second FFT or an amplitude dB scale.
function focusBands(parts, low, high, scale, bassWeight, trebleWeight, range) {
    if (!(low >= 20 && high > low && high <= 20000)) {
        low = 50;
        high = 10000;
    }
    const n = parts.length;
    const logSpan = Math.log(high / low);
    const melLow = Math.log(1 + low / 700);
    const melHigh = Math.log(1 + high / 700);
    return parts.map((value, i) => {
        const p = (i + 0.5) / n;
        const frequency = scale === "mel" ? 700 * (Math.exp(melLow + p * (melHigh - melLow)) - 1) : low * Math.exp(p * logSpan);
        const x = Math.max(0, Math.min(n - 1, Math.log(frequency / low) / logSpan * n - 0.5));
        const index = Math.floor(x);
        const level = scale === "mel" ? parts[index] + (parts[Math.min(n - 1, index + 1)] - parts[index]) * (x - index) : value;
        const weight = frequency < 250 ? bassWeight : frequency > 4000 ? trebleWeight : 1;
        return Math.max(0, Math.min(range, level * weight));
    });
}

function energyRise(current, previous, elapsedMs) {
    return elapsedMs > 0 ? Math.max(0, (current * current - previous * previous) * 1000 / elapsedMs) : 0;
}

function releaseBlend(previous, target, elapsedMs, decayMs) {
    if (decayMs <= 0)
        return target;
    const next = target + (previous - target) * Math.exp(-Math.max(0, elapsedMs) / decayMs);
    return Math.abs(next - target) < 0.5 ? target : next;
}
