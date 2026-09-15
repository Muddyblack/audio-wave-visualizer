import QtQuick
import QtQuick.Layouts
import ".."

// Title and artist at the configured size and alignment. Layouts scale them
// like the HTML (for example Stacked uses title ×1.6 and artist ×1.05).
ColumnLayout {
    id: root
    required property var view
    property real titleFactor: 1
    property real artistSize: 0.82
    // Orbit always centres its texts.
    property int alignmentOverride: -1
    readonly property int alignment: alignmentOverride >= 0 ? alignmentOverride : view.configuration.textAlign === "center" ? Text.AlignHCenter : view.configuration.textAlign === "right" ? Text.AlignRight : Text.AlignLeft
    spacing: 0

    TrackText {
        Layout.fillWidth: true
        titleSize: root.view.configuration.titleSize ?? 11
        sizeFactor: root.titleFactor
        horizontalAlignment: root.alignment
        displayTrack: root.view.displayTrack
        trackUnknown: root.view.trackUnknown
        rawTrack: root.view.track
        color: root.view.textColor
    }

    TrackText {
        Layout.fillWidth: true
        secondary: true
        titleSize: root.view.configuration.titleSize ?? 11
        sizeFactor: root.artistSize / 0.82
        horizontalAlignment: root.alignment
        artist: root.view.artist
        sourceHint: root.view.sourceHint
        color: root.view.textColor
    }
}
