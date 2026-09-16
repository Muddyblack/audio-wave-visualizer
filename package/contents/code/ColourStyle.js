.pragma library
.import "WaveMath.js" as WaveMath

function sample(stops, position) {
    var x = Math.max(0, Math.min(1, position)) * Math.max(0, stops.length - 1);
    var left = Math.floor(x), fraction = x - left;
    var a = WaveMath.color(stops[left] || "#ffffff");
    if (fraction === 0) return a;
    var b = WaveMath.color(stops[Math.min(left + 1, stops.length - 1)] || a);
    return Qt.rgba(a.r + (b.r - a.r) * fraction, a.g + (b.g - a.g) * fraction, a.b + (b.b - a.b) * fraction, a.a + (b.a - a.a) * fraction);
}
function hex(value) {
    var c = WaveMath.color(value);
    return "#" + [c.r, c.g, c.b].map(function (v) { return ("0" + Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16)).slice(-2); }).join("");
}
function resolve(s, accent, control, start, end, stops) {
    var controls = s.controlsColorSource || "legacy";
    var progress = s.progressColorSource || "legacy";
    var tint = controls === "visualizer" ? sample(stops, 0) : controls === "accent" ? accent : control;
    var colors = progress === "visualizer" ? stops : progress === "custom" ? [s.customProgressColor || accent] : progress === "accent" ? [accent] : [];
    return {control: tint, controlAccent: controls === "legacy" ? accent : tint,
        progressStops: colors, progressWave: colors.length ? sample(colors, 0) : accent,
        start: colors.length ? sample(colors, 0) : start, end: colors.length ? sample(colors, 1) : end};
}

// Host adapters provide system colours and the extracted/sample cover palette.
function appearance(s, systemAccent, systemText, coverAccent, hasCover) {
    var light = s.showBg && s.surfaceStyle === "solid"
        && !(s.showMpris && s.artBg && hasCover) && (s.autoContrast ?? true);
    var base = s.useSystemAccent ? systemAccent : s.customColor;
    return {
        light: light,
        wave: s.accentFromArt || s.vizColorMode === "cover" ? coverAccent : base,
        text: s.useSystemText ? (light ? "#1e241d" : systemText) : s.customTextColor,
        control: s.useSystemControls ? (light ? "#1e241d" : "#ffffff") : s.customControlColor
    };
}
function linked(s, wave, control, systemAccent, cover1, cover2, high, seconds) {
    var stops = s.controlsColorSource === "visualizer" || s.progressColorSource === "visualizer"
        ? WaveMath.colorStops(wave, s.vizColorMode, s.vizPalette, cover1, cover2, s.hueReactive, high, seconds, s.reducedMotion ?? false)
        : [wave];
    return resolve(s, wave, control, s.useSystemControls ? systemAccent : control,
        s.useSystemControls ? "#ffffff" : control, stops);
}
