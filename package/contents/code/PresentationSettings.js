.pragma library

// Each panel presentation stores a complete look. Audio capture, accessibility,
// libraries and placement remain shared with the widget.
var sharedKeys = ["appleTrackInfo", "onlineTrackInfo", "panelAppearance", "popupAppearance", "inputSource", "inputMethod",
    "sensitivity", "noiseReduction", "lowCutoff", "highCutoff", "frequencyScale",
    "bassWeight", "trebleWeight", "silenceDecay", "framerate", "alwaysVisible",
    "gpuDebug", "reducedMotion", "batterySaver", "simpleRender", "autoPillInPanel", "panelDisplayMode", "panelOrientation",
    "autoDailyLook", "dailyLookApplied", "favoritePresets", "userPresets",
    "customVisualizers", "customProgressBars", "customButtonStyles", "lyricsOffset",
    "monitor", "verticalPosition", "desktopLayer", "pauseWhenCovered", "hAnchor",
    "widgetWidth", "widgetHeight", "dockMode", "dockMargin", "barHeight",
    "widthExpansion", "dockPosition"];

function isColor(value) {
    return value && typeof value === "object" && value.r !== undefined && value.g !== undefined && value.b !== undefined && value.a !== undefined;
}

function appearance(source) {
    var result = {};
    Object.keys(source).forEach(function (key) {
        if (sharedKeys.indexOf(key) === -1 && key !== "__proto__" && key !== "constructor" && key !== "prototype")
            result[key] = isColor(source[key]) ? String(source[key]) : source[key];
    });
    return result;
}

function read(text, source) {
    try {
        var value = JSON.parse(text || "{}");
        if (!value || typeof value !== "object" || Array.isArray(value)) return {};
        var result = {};
        Object.keys(appearance(source)).forEach(function (key) {
            if (!Object.prototype.hasOwnProperty.call(value, key)) return;
            var v = value[key], original = source[key];
            if (Array.isArray(original) ? Array.isArray(v) && v.every(function (entry) { return typeof entry === "string"; })
                : (typeof v === typeof original || (isColor(original) && typeof v === "string")) && (typeof v !== "number" || isFinite(v)))
                result[key] = v;
        });
        return result;
    } catch (error) { return {}; }
}

// The popup look carried onto the pill. Layout and pill-specific choices stay.
function carry(next, current) {
    Object.keys(current).forEach(function (key) {
        if (key !== "layoutMode" && key.indexOf("pill") !== 0 && key !== "hoverDetails")
            next[key] = current[key];
    });
    return next;
}

function mirror(next, current) {
    carry(next, current);
    next.pillEq = next.layoutMode === "pillicon" ? "visualizer" : "wave";
    next.pillProgress = next.progressBarStyle === -1 ? "off" : "bar";
    return next;
}

function resolve(source, target) {
    var result = Object.assign({}, source);
    if (target === "panel") {
        result.layoutMode = source.layoutMode === "pillicon" ? "pillicon" : "pill";
        // A pill never customised follows the popup card, as "Use popup look" does.
        if (!source.panelAppearance || source.panelAppearance === "{}")
            mirror(result, appearance(resolve(source, "popup")));
        else
            Object.assign(result, read(source.panelAppearance, source));
        if (result.layoutMode !== "pillicon") result.layoutMode = "pill";
    } else if (target === "popup") {
        // Saved popup choices override defaults; the host controls native framing.
        Object.assign(result, {layoutMode: ["pill", "pillicon"].indexOf(source.layoutMode) === -1 ? source.layoutMode : "classic", showBg: true,
            surfaceStyle: source.showBg ? source.surfaceStyle : "glass",
            bgRadius: Math.max(14, source.bgRadius), cardShadow: "lifted", hoverDetails: "off", compositorGlass: true});
        Object.assign(result, read(source.popupAppearance, source));
        if (result.layoutMode === "pill" || result.layoutMode === "pillicon") result.layoutMode = "classic";
    }
    return result;
}

function edit(source, next, target) {
    if (target !== "panel" && target !== "popup")
        return Object.assign({}, next, {panelAppearance: source.panelAppearance, popupAppearance: source.popupAppearance});
    var result = Object.assign({}, source);
    // Freeze both looks on the first edit so changing one cannot alter the other.
    result.panelAppearance = JSON.stringify(appearance(resolve(source, "panel")));
    result.popupAppearance = JSON.stringify(appearance(resolve(source, "popup")));
    sharedKeys.forEach(function (key) {
        if (key !== "panelAppearance" && key !== "popupAppearance" && next[key] !== undefined)
            result[key] = next[key];
    });
    if (target === "panel") result.autoPillInPanel = true;
    result[target === "panel" ? "panelAppearance" : "popupAppearance"] = JSON.stringify(appearance(next));
    return result;
}

// One-shot copy: ordinary appearance values keep the existing preset format.
// Layout and pill-specific interaction/arrangement stay with their own view.
function syncAppearance(source, from) {
    if (from !== "panel" && from !== "popup") return Object.assign({}, source);
    var to = from === "panel" ? "popup" : "panel";
    var current = appearance(resolve(source, from));
    var next = resolve(source, to);
    if (to === "panel") mirror(next, current);
    else carry(next, current);
    return edit(source, next, to);
}
