import QtQuick
import org.kde.plasma.core as PlasmaCore

// Plasma's Dialog owns the native blur protocol. Its internal FrameSvgItem
// supplies the region; hide its paint and use only our transparent-margin mask.
// This adapter is deliberately guarded: unknown Plasma internals stay borderless.
Item {
    id: root
    required property var dialog
    property string maskPath: ""
    property bool enabledBlur: false
    property var frame: null
    property bool prepared: false
    readonly property bool ready: prepared && enabledBlur && maskPath !== ""

    function findFrame(item, depth) {
        if (!item || item === dialog.mainItem || depth > 3)
            return null;
        if (item.imagePath !== undefined && item.fixedMargins !== undefined && item.mask !== undefined && item.enabledBorders !== undefined)
            return item;
        for (let i = 0; i < item.children.length; ++i) {
            const found = findFrame(item.children[i], depth + 1);
            if (found)
                return found;
        }
        return null;
    }
    function prepare() {
        if (!frame)
            frame = findFrame(dialog.contentItem, 0);
        if (!frame)
            return;
        frame.opacity = 0;
        frame.enabledBorders = 0;
        refresh();
    }
    function refresh() {
        prepared = false;
        if (!frame || !enabledBlur || maskPath === "")
            return;
        frame.opacity = 0;
        frame.enabledBorders = 0;
        frame.imagePath = maskPath;
        prepared = true;
    }
    Component.onCompleted: Qt.callLater(prepare)
    onMaskPathChanged: Qt.callLater(refresh)
    onEnabledBlurChanged: Qt.callLater(refresh)
    Connections {
        target: root.frame
        // updateTheme writes the standard theme path immediately before reading
        // the mask. Substitute synchronously; never schedule updates from here.
        function onImagePathChanged() {
            if (root.ready && root.dialog.backgroundHints !== PlasmaCore.Dialog.NoBackground && root.frame.imagePath !== root.maskPath)
                root.frame.imagePath = root.maskPath;
        }
        function onEnabledBordersChanged() {
            if (root.frame.enabledBorders !== 0)
                root.frame.enabledBorders = 0;
        }
    }
}
