import QtQuick
import org.kde.plasma.core as PlasmaCore

// Hover details (tooltip or drawer) in a borderless window below the card.
// Place it inside the card's view: it anchors to that view's pointer.
Item {
    id: root
    required property var view
    property bool active: true
    x: view.detailsPopupMode === "drawer" ? view.width / 2 : view.detailsPointer.x
    y: view.detailsPopupMode === "drawer" ? view.height : view.detailsPointer.y + 16
    width: 1
    height: 1
    PlasmaCore.Dialog {
        type: PlasmaCore.Dialog.Tooltip
        flags: Qt.WindowDoesNotAcceptFocus
        location: PlasmaCore.Types.Floating
        backgroundHints: PlasmaCore.Dialog.NoBackground
        visualParent: root
        visible: root.active && root.view.detailsVisible
        mainItem: TrackDetails {
            width: root.view.detailsPopupMode === "drawer" ? Math.max(root.view.width, 380) : 310
            height: implicitHeight
            view: root.view
            mode: root.view.detailsPopupMode
        }
    }
}
