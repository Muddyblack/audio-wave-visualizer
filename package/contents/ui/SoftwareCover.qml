import QtQuick

// Paint once at display resolution, then fit the backing canvas to the cover.
// Playback frames never rasterize artwork.
Item {
    id: cover
    property url source
    property size imageSize: Qt.size(1, 1)
    property real radius: 10
    property bool grayed: false
    // Fit the whole image over a dimmed cropped copy instead of cropping it.
    property bool letterbox: false
    // With letterbox: fill the bands with stretched edges, not a dimmed copy.
    property bool edges: false
    // Source pixel size, for the 1 px edge slices.
    property size naturalSize: Qt.size(1, 1)
    property bool ready: false
    property real rasterScale: Math.max(1, Screen.devicePixelRatio)

    Canvas {
        id: painter
        objectName: "softwareCoverCanvas"
        property url loadedSource
        width: Math.max(1, Math.min(2048, Math.ceil(cover.width * cover.rasterScale)))
        height: Math.max(1, Math.min(2048, Math.ceil(cover.height * cover.rasterScale)))
        transform: Scale {
            xScale: cover.width / painter.width
            yScale: cover.height / painter.height
        }
        renderStrategy: Canvas.Cooperative
        smooth: true
        antialiasing: true
        function loadSource() {
            cover.ready = false;
            if (loadedSource.toString() !== "")
                unloadImage(loadedSource);
            loadedSource = cover.source;
            if (cover.source.toString() !== "") {
                loadImage(cover.source);
                cover.ready = isImageLoaded(cover.source);
            }
            requestPaint();
        }
        Component.onCompleted: loadSource()
        onImageLoaded: {
            cover.ready = isImageLoaded(cover.source);
            requestPaint();
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: cover
            function onSourceChanged() {
                painter.loadSource();
            }
            function onImageSizeChanged() {
                painter.requestPaint();
            }
            function onRadiusChanged() {
                painter.requestPaint();
            }
            function onGrayedChanged() {
                painter.requestPaint();
            }
            function onLetterboxChanged() {
                painter.requestPaint();
            }
            function onEdgesChanged() {
                painter.requestPaint();
            }
            function onNaturalSizeChanged() {
                painter.requestPaint();
            }
        }
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            if (cover.source.toString() === "" || !isImageLoaded(cover.source) || cover.width <= 0 || cover.height <= 0)
                return;
            ctx.scale(width / cover.width, height / cover.height);
            const w = cover.width, h = cover.height;
            const r = Math.max(0, Math.min(cover.radius, w / 2, h / 2));
            ctx.beginPath();
            ctx.roundedRect(0, 0, w, h, r, r);
            ctx.closePath();
            ctx.clip();
            const iw = Math.max(1, cover.imageSize.width), ih = Math.max(1, cover.imageSize.height);
            // The cropped cover; the edge variant paints its bands over nothing,
            // as the slide show does.
            const fill = Math.max(w / iw, h / ih);
            if (!(cover.letterbox && cover.edges))
                ctx.drawImage(cover.source, (w - iw * fill) / 2, (h - ih * fill) / 2, iw * fill, ih * fill);
            if (cover.letterbox && !cover.edges) {
                ctx.fillStyle = "rgba(0,0,0,0.55)";
                ctx.fillRect(0, 0, w, h);
                const fitWhole = Math.min(w / iw, h / ih);
                ctx.drawImage(cover.source, (w - iw * fitWhole) / 2, (h - ih * fitWhole) / 2, iw * fitWhole, ih * fitWhole);
            } else if (cover.letterbox) {
                // Terminal Slide Show's createBlurredBackground(): 1 px edge
                // slices stretched over the bands (columns over the full height),
                // blurred, darkened by a quarter, then the image fitted on top.
                // Canvas has no blur filter, so a 9-tap running average along the
                // slice stands in for blur(20px).
                const fit = Math.min(w / iw, h / ih);
                const fw = iw * fit, fh = ih * fit, fx = (w - fw) / 2, fy = (h - fh) / 2;
                const slice = (sx, sy, sw, sh, dx, dy, dw, dh, alongX) => {
                    if (dw <= 0.5 || dh <= 0.5)
                        return;
                    ctx.save();
                    ctx.beginPath();
                    ctx.rect(dx, dy, dw, dh);
                    ctx.clip();
                    const taps = 9, radius = 20;
                    for (let i = 0; i < taps; ++i) {
                        const offset = (i / (taps - 1) - 0.5) * 2 * radius;
                        ctx.globalAlpha = 1 / (i + 1);
                        ctx.drawImage(cover.source, sx, sy, sw, sh, dx + (alongX ? offset : 0), dy + (alongX ? 0 : offset), dw, dh);
                    }
                    ctx.restore();
                };
                const nw = cover.naturalSize.width, nh = cover.naturalSize.height;
                if (nw > 0 && nh > 0) {
                    slice(0, 0, 1, nh, 0, 0, fx, h, false);
                    slice(nw - 1, 0, 1, nh, fx + fw, 0, w - (fx + fw), h, false);
                    slice(0, 0, nw, 1, fx, 0, fw, fy, true);
                    slice(0, nh - 1, nw, 1, fx, fy + fh, fw, h - (fy + fh), true);
                }
                ctx.fillStyle = "rgba(0,0,0,0.25)";
                ctx.fillRect(0, 0, w, h);
                ctx.drawImage(cover.source, fx, fy, fw, fh);
            }
            if (cover.grayed) {
                ctx.globalCompositeOperation = "source-atop";
                ctx.fillStyle = "rgba(0,0,0,0.25)";
                ctx.fillRect(0, 0, w, h);
            }
        }
    }
}
