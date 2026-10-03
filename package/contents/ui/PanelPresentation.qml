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
    readonly property int sideRotation: rightEdge ? 90 : -90
    readonly property int forcedRotation: orientation === "left" ? -90 : orientation === "right" ? 90 : 0
    readonly property var uprightCardSize: Layouts.size(cardConfiguration)
    readonly property int cardRotation: orientation === "auto" ? (vertical && availableSize.width < uprightCardSize[0] ? sideRotation : 0) : forcedRotation
    readonly property var cardSize: cardRotation === 0 ? uprightCardSize : [uprightCardSize[1], uprightCardSize[0]]
    // Scaling layouts may shrink slightly to fit; reflowing ones need full size.
    readonly property real fitFloor: ["lyrics", "visualizer"].includes(Layouts.mode(cardConfiguration)) ? 1 : 0.8
    readonly property bool canRequestCard: displayMode === "card" || displayMode !== "pill" && (vertical ? availableSize.width >= cardSize[0] * fitFloor : availableSize.height >= cardSize[1] * fitFloor)
    readonly property bool showCard: canRequestCard && (displayMode === "card" || availableSize.width >= cardSize[0] * fitFloor && availableSize.height >= cardSize[1] * fitFloor)
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
