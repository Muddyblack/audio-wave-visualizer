import QtQuick
import "../code/CoverPalette.js" as CoverPalette

// Shared album palette for every host. Sample only when the cover changes;
// the transparent 32px Canvas never follows audio.
Canvas {
    id: sampler
    property string source: ""
    property color fallback: "#b4befe"
    property color dominant: fallback
    property color vibrant: fallback
    property color muted: fallback
    readonly property var gradientStops: [primary, accent, secondary]
    property color primary: fallback
    property color secondary: fallback
    property color accent: fallback
    property bool ready: false
    property string _loadedSource: ""
    width: 32
    height: 32
    opacity: 0
    renderStrategy: Canvas.Cooperative

    function resetPalette() {
        ready = false;
        dominant = fallback;
        vibrant = fallback;
        muted = fallback;
        primary = fallback;
        secondary = fallback;
        accent = fallback;
    }
    function refresh() {
        resetPalette();
        if (_loadedSource)
            unloadImage(_loadedSource);
        _loadedSource = source;
        if (available && source) {
            loadImage(source);
            // A cached local image may load synchronously without imageLoaded.
            if (isImageLoaded(source))
                requestPaint();
        }
    }
    onSourceChanged: refresh()
    onFallbackChanged: {
        if (!ready)
            resetPalette();
    }
    onAvailableChanged: {
        if (available)
            refresh();
    }
    onImageLoaded: {
        if (source && isImageLoaded(source))
            requestPaint();
    }
    onPaint: {
        if (!source || !isImageLoaded(source))
            return;
        const ctx = getContext("2d");
        ctx.reset();
        ctx.drawImage(source, 0, 0, width, height);
        const palette = CoverPalette.extract(ctx.getImageData(0, 0, width, height).data);
        if (!palette) {
            resetPalette();
            return;
        }
        dominant = palette.dominant;
        vibrant = palette.vibrant;
        muted = palette.muted;
        primary = palette.primary;
        secondary = palette.secondary;
        accent = palette.accent;
        ready = true;
    }
}
