import QtQuick
import Quickshell.Hyprland
import "Occlusion.js" as Geometry

QtObject {
    id: root

    property bool enabled: true
    // Widget bounds in desktop logical coordinates, supplied by the shell.
    property var rectangles: []
    readonly property var coveredScreens: enabled ? Geometry.coveredScreens(rectangles, Hyprland.toplevels.values, Hyprland.monitors.values) : []

    // This detects geometric coverage. Hyprland IPC does not establish that
    // every surface pixel is opaque; users of translucent windows can disable
    // this optimization in the shell's settings.
    function refresh() {
        if (!enabled || rectangles.length === 0 || !Hyprland.requestSocketPath)
            return;
        Hyprland.refreshMonitors();
        Hyprland.refreshToplevels();
    }

    function scheduleRefresh() {
        if (enabled && rectangles.length > 0)
            debounce.restart();
    }

    onEnabledChanged: scheduleRefresh()
    onRectanglesChanged: scheduleRefresh()
    Component.onCompleted: scheduleRefresh()

    property Timer debounce: Timer {
        interval: 80
        onTriggered: root.refresh()
    }

    // Window drags/resizes do not consistently produce geometry events.
    // Native IPC once a second also resumes a covered widget after a drag;
    // there is no shell process or query tied to the audio/render frame rate.
    property Timer geometryRefresh: Timer {
        interval: 1000
        repeat: true
        running: root.enabled && root.rectangles.length > 0 && Hyprland.monitors.values.length > 0
        onTriggered: root.refresh()
    }

    property Connections events: Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (/^(workspace|focusedmon|activewindow|fullscreen|monitoradded|monitorremoved|openwindow|closewindow|movewindow|changefloatingmode|activespecial|moveworkspace|configreloaded|pin)/.test(event.name))
                root.scheduleRefresh();
        }
    }
}
