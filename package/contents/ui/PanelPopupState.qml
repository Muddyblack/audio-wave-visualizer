import QtQuick

// Hover opens the same card as a click. Delay closing across the gap between
// windows so its playback controls remain reachable.
Item {
    id: state
    property bool available: true
    property string trigger: "both"
    readonly property bool hoverEnabled: trigger !== "click"
    readonly property bool clickEnabled: trigger !== "hover"
    property Item anchor: null
    property bool anchorHovered: false
    property bool popupHovered: false
    property bool opened: false
    property bool pinned: false
    // Explicit pin survives focus loss; a normal click only latches hover.
    property bool keepOpen: false
    property int showDelay: 350
    property int hideDelay: 350

    function hover(item, entered) {
        if (entered) {
            anchor = item;
            anchorHovered = true;
            closeTimer.stop();
            if (available && hoverEnabled && !opened)
                openTimer.restart();
        } else if (anchor === item) {
            anchorHovered = false;
            openTimer.stop();
            scheduleClose();
        }
    }
    function toggle(item) {
        if (!available || !clickEnabled || keepOpen)
            return;
        openTimer.stop();
        closeTimer.stop();
        if (!available)
            return;
        anchor = item;
        if (opened && pinned) {
            dismiss();
        } else {
            pinned = true;
            opened = true;
        }
    }
    function togglePin() {
        if (keepOpen) {
            dismiss();
        } else if (available && opened) {
            openTimer.stop();
            closeTimer.stop();
            keepOpen = true;
            pinned = true;
        }
    }
    function scheduleClose() {
        if (opened && !pinned && !anchorHovered && !popupHovered)
            closeTimer.restart();
        else
            closeTimer.stop();
    }
    function dismiss() {
        openTimer.stop();
        closeTimer.stop();
        opened = false;
        pinned = false;
        keepOpen = false;
    }
    onPopupHoveredChanged: scheduleClose()
    onTriggerChanged: dismiss()
    onAvailableChanged: if (!available)
        dismiss()
    Timer {
        id: openTimer
        interval: state.showDelay
        onTriggered: if (state.available && state.hoverEnabled && state.anchorHovered)
            state.opened = true
    }
    Timer {
        id: closeTimer
        interval: state.hideDelay
        onTriggered: if (!state.pinned && !state.anchorHovered && !state.popupHovered)
            state.dismiss()
    }
}
