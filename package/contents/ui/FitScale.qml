import QtQuick

// The on-screen scale FittedFrame applies to the card, for items that must
// rasterize (canvases, layer textures) at display size instead of design size.
Item {
    id: fit
    visible: false
    readonly property real value: {
        for (let item = parent; item; item = item.parent) {
            if (item.objectName === "fittedCanvas")
                return item.scale;
        }
        return 1;
    }
    // Quarter steps avoid reallocating textures for every small scale change.
    readonly property real steps: Math.max(1, Math.round(value * 4) / 4)
}
