.pragma library

// Design sizes at 1× (docs/redesign-plan.md §4). `compact` is showMpris=false.
const SIZES = {
    classic: [360, 104],
    mirrored: [360, 104],
    inline: [360, 104],
    hero: [340, 138],
    stacked: [320, 200],
    strip: [460, 46],
    poster: [360, 112],
    compact: [200, 84]
};

// Layouts the widget can draw; other stored values fall back to Classic.
const MODES = ["classic", "mirrored", "inline", "hero", "stacked", "poster", "strip"];

function mode(configuration) {
    if (!configuration.showMpris)
        return "compact";
    const value = configuration.layoutMode || "classic";
    return MODES.indexOf(value) === -1 ? "classic" : value;
}

function size(configuration) {
    const current = mode(configuration);
    if (current === "poster")
        return [360, configuration.posterLines === 2 ? 138 : 112];
    return SIZES[current];
}
