import QtQuick
import QtQuick.Effects
import "../code/ColourStyle.js" as ColourStyle

// The soft part of the Text edge, the way macOS and iOS lift light type off
// a busy wallpaper. Text never passes through the effect (that resamples the
// glyphs and softens them): MultiEffect captures `target` itself (and leaves
// it visible) to draw a blurred copy in the edge colour underneath, and the
// text renders natively on top. A ShaderEffectSource in between would skip
// MultiEffect's blur padding and smear an enlarged ghost beside the text.
//
// Place it before `target` in any plain Item that contains it: it paints
// below and follows the target through nested layouts. A wide, faint ambient
// pass darkens the wallpaper around the words. "shadow" adds a tight key pass
// 1 px below; "outline" pairs the glow with the text's own crisp native halo
// (VisualizerView.edgeStyle), since a blur that tight smudges small type. A
// light edge (behind dark text) always glows evenly: light cast downward
// reads as a doubled, letterpressed copy at small sizes.
Loader {
    id: edge
    property Item target: null
    property string mode: "none"
    property color edgeColor: "#101318"
    readonly property bool halo: mode === "outline"
    readonly property bool glow: halo || ColourStyle.luminance(edgeColor) > 0.5
    // The target's position in this item's parent, summed through layouts.
    readonly property point origin: {
        let px = 0, py = 0;
        for (let item = target; item && item !== parent; item = item.parent) {
            px += item.x;
            py += item.y;
        }
        return Qt.point(px, py);
    }
    x: origin.x
    y: origin.y
    width: target?.width ?? 0
    height: target?.height ?? 0
    opacity: target?.opacity ?? 1
    active: !!target && target.visible && (mode === "outline" || mode === "shadow") && width > 0 && height > 0

    component Pass: MultiEffect {
        property real offset
        anchors.fill: parent
        anchors.topMargin: offset
        anchors.bottomMargin: -offset
        blurEnabled: true
        // Recolour every pixel to the edge colour, whatever the text colour.
        brightness: 1
        colorization: 1
        colorizationColor: edge.edgeColor
    }

    sourceComponent: Item {
        // Wide and faint: darkens the wallpaper around the words.
        Pass {
            source: edge.target
            offset: edge.glow ? 0 : 2
            blurMax: edge.glow ? 12 : 20
            blur: 0.5
            opacity: edge.halo ? 0.3 : edge.glow ? 0.45 : 0.5
        }
        // Shadow: a tight key pass 1 px below defines each letter.
        Pass {
            visible: !edge.glow
            source: edge.target
            offset: 1
            blurMax: 2
            blur: 0.5
            opacity: 0.45
        }
    }
}
