import QtQuick

// A Canvas that rasterizes at the card's on-screen size. FittedFrame scales the
// whole card with an item transform, which would otherwise stretch the
// design-size bitmap and blur every stroke. Paint handlers call
// ctx.scale(pixelScale, pixelScale) after ctx.reset() and keep drawing in
// design units.
Item {
    id: canvas

    // Quarter steps (rounded to nearest) avoid reallocating for every small
    // change in fitted scale.
    // Bound both enlargement and bitmap dimensions. Qt handles screen DPR;
    // multiplying it here would oversample again on high-DPI screens.
    // Animated canvases repaint every frame, so they lower this to bound CPU cost.
    property real maxPixelScale: 4

    readonly property real pixelScale: {
        let fitted = 1;
        for (let item = parent; item; item = item.parent) {
            if (item.objectName === "fittedCanvas") {
                fitted = item.scale;
                break;
            }
        }
        return Math.min(maxPixelScale, 2048 / Math.max(1, width, height), Math.max(1, Math.round(fitted * 4) / 4));
    }

    readonly property size canvasSize: Qt.size(painter.width, painter.height)
    property alias renderStrategy: painter.renderStrategy
    readonly property alias available: painter.available
    signal paint
    signal painted

    function getContext(kind) {
        return painter.getContext(kind);
    }
    function requestPaint() {
        if (visible)
            painter.requestPaint();
    }

    // Give the actual Canvas display-sized dimensions, then fit it back into
    // design units. This avoids Qt's deprecated virtual-canvas window handling.
    Canvas {
        id: painter
        width: Math.max(1, Math.round(canvas.width * canvas.pixelScale))
        height: Math.max(1, Math.round(canvas.height * canvas.pixelScale))
        transform: Scale {
            xScale: canvas.width / painter.width
            yScale: canvas.height / painter.height
        }
        antialiasing: canvas.antialiasing
        smooth: true
        onPaint: canvas.paint()
        onPainted: canvas.painted()
        onWidthChanged: canvas.requestPaint()
        onHeightChanged: canvas.requestPaint()
    }
}
