import QtQuick
import "../code/Layouts.js" as Layouts

// Ask the panel for the card's length when its thickness can accommodate it.
// Keep that request independent of the current fallback to avoid getting stuck
// with the icon's 30px allocation, or oscillating between the two sizes.
QtObject {
    required property var cardConfiguration
    required property var pillConfiguration
    property size availableSize: Qt.size(0, 0)
    property bool vertical: false
    property bool rightEdge: false
    property string orientation: "auto"
    property string displayMode: "adaptive"
    property string cardSizing: "fit"
    property real cardScale: 1
    readonly property int sideRotation: rightEdge ? 90 : -90
    readonly property int forcedRotation: orientation === "left" ? -90 : orientation === "right" ? 90 : 0
    readonly property var uprightCardSize: Layouts.size(cardConfiguration)
    readonly property int cardRotation: orientation === "auto" ? (vertical && availableSize.width < uprightCardSize[0] ? sideRotation : 0) : forcedRotation
    readonly property var baseCardSize: cardRotation === 0 ? uprightCardSize : [uprightCardSize[1], uprightCardSize[0]]
    // Fit grows the card to the panel's thickness, which the panel decides
    // independently of our request, so the size cannot oscillate.
    readonly property real thickness: vertical ? availableSize.width : availableSize.height
    readonly property real sizeFactor: cardSizing === "fixed" ? Math.max(0.5, cardScale) : Math.min(4, Math.max(1, thickness / baseCardSize[vertical ? 0 : 1]))
    readonly property var cardSize: [Math.round(baseCardSize[0] * sizeFactor), Math.round(baseCardSize[1] * sizeFactor)]
    // Scaling layouts may shrink slightly to fit; reflowing ones need full size.
    readonly property real fitFloor: ["lyrics", "visualizer"].includes(Layouts.mode(cardConfiguration)) ? 1 : 0.8
    readonly property bool canRequestCard: displayMode === "card" || displayMode !== "pill" && (vertical ? availableSize.width >= baseCardSize[0] * fitFloor : availableSize.height >= baseCardSize[1] * fitFloor)
    readonly property bool showCard: canRequestCard && (displayMode === "card" || availableSize.width >= baseCardSize[0] * fitFloor && availableSize.height >= baseCardSize[1] * fitFloor)
    readonly property var fallback: Object.assign({}, pillConfiguration, {
        layoutMode: vertical && orientation === "normal" ? "pillicon" : pillConfiguration.layoutMode
    })
    readonly property int pillRotation: fallback.layoutMode === "pillicon" ? 0 : orientation === "auto" ? (vertical ? sideRotation : 0) : forcedRotation
    readonly property var uprightPillSize: Layouts.size(fallback)
    readonly property var pillSize: pillRotation === 0 ? uprightPillSize : [uprightPillSize[1], uprightPillSize[0]]
    readonly property int contentRotation: showCard ? cardRotation : pillRotation
    readonly property var configuration: showCard ? cardConfiguration : fallback
    readonly property var preferredSize: canRequestCard ? cardSize : pillSize
}
