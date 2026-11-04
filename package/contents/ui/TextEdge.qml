import QtQuick
import QtQuick.Effects

// The soft part of the Text edge, the way macOS and iOS lift light type off
// a busy wallpaper. Text never passes through the effect (that resamples the
// glyphs and softens them): this draws a blurred copy of `target` in the edge
// colour underneath, and the text renders natively on top.
//
// Place it before `target` in any plain Item that contains it: it paints
// below and follows the target through nested layouts. A wide, faint ambient
// pass darkens the wallpaper around the words. "shadow" adds a tight key pass
// 1 px below; "outline" pairs the glow with the text's own crisp native halo
// (VisualizerView.edgeStyle), since a blur that tight smudges small type.
Loader {
    id: edge
    property Item target: null
    property string mode: "none"
    property color edgeColor: "#101318"
    readonly property bool halo: mode === "outline"
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
        ShaderEffectSource {
            id: copy
            anchors.fill: parent
            sourceItem: edge.target
            hideSource: false
            visible: false
        }
        // Wide and faint: darkens the wallpaper around the words.
        Pass {
            source: copy
            offset: edge.halo ? 0 : 2
            blurMax: edge.halo ? 12 : 20
            blur: 0.5
            opacity: edge.halo ? 0.3 : 0.5
        }
        // Shadow: a tight key pass 1 px below defines each letter.
        Pass {
            visible: !edge.halo
            source: copy
            offset: 1
            blurMax: 2
            blur: 0.5
            opacity: 0.45
        }
    }
}
