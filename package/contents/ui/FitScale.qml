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
    // Texture pixels per design unit for an explicit layer.textureSize, which
    // Qt takes in device pixels and never scales by the screen DPR itself, so
    // `steps` alone blurs layers on high-DPI screens. (A Canvas does get the
    // DPR from Qt; CrispCanvas uses `steps`.) ProgressBar's layers still use
    // `steps`: with texels its gradient fill vanished at 2.5x, cause unknown.
    readonly property real texels: steps * (Screen.devicePixelRatio || 1)
}
