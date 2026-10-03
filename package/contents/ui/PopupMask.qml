import QtQuick
import "../code/Layouts.js" as LayoutSizes

// Renders the rounded SVG mask Plasma's native blur uses for the card popup.
// One request at a time; a shape change while one runs queues the next.
PlasmaCommandSource {
    id: root
    required property var configuration
    required property int instance
    property bool dialogVisible: false
    readonly property var dimensions: LayoutSizes.size(configuration)
    readonly property string shape: [Math.round(dimensions[0]), Math.round(dimensions[1]), Math.max(0, Math.min(100, Math.round(configuration.bgRadius ?? 14))), 12].join(" ")
    property string runningShape: ""
    property string completedShape: ""
    property string path: ""
    readonly property bool wanted: !!configuration.compositorGlass && configuration.showBg && !configuration.artBg && LayoutSizes.mode(configuration) !== "visualizer" && ["glass", "liquid"].includes(configuration.surfaceStyle)
    function generate() {
        if (!wanted || !dialogVisible || runningShape !== "" || (completedShape === shape && path !== ""))
            return;
        path = "";
        runningShape = shape;
        const script = Qt.resolvedUrl("../code/popup_blur_mask.sh").toString().replace(/^file:\/\//, "");
        connectSource("bash '" + script.replace(/'/g, "'\\''") + "' " + instance + " " + runningShape);
    }
    onShapeChanged: {
        path = "";
        Qt.callLater(generate);
    }
    onWantedChanged: Qt.callLater(generate)
    onDialogVisibleChanged: Qt.callLater(generate)
    onNewData: (source, data) => {
        const generatedShape = runningShape;
        runningShape = "";
        if (data["exit code"] === 0 && generatedShape === shape) {
            completedShape = generatedShape;
            path = String(data.stdout || "").trim();
        } else if (generatedShape !== shape) {
            Qt.callLater(generate);
        }
    }
}
