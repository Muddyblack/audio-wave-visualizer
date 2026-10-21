pragma Singleton
import QtQuick

// Hardcoded pixel sizes are designed for Plasma's default 10pt font. px()
// scales them by how far the user's system font is from that, so the card
// and the settings follow Appearance > Fonts like other Qt apps.
QtObject {
    // The "Follow system font size" setting; main.qml and the studio set it.
    property bool follow: true

    readonly property real factor: {
        if (!follow)
            return 1;
        const pt = Qt.application.font.pointSize;
        return pt > 0 ? Math.min(2, Math.max(0.75, pt / 10)) : 1;
    }

    // `limit` caps the result for text that sits in fixed-height chrome (pill,
    // panel progress row) so a large system font cannot outgrow the card.
    function px(size, limit) {
        // Small labels stay readable once the card is scaled to the widget.
        const scaled = Math.max(follow ? 10 : 1, Math.round(size * factor));
        return limit > 0 ? Math.min(scaled, Math.max(size, limit)) : scaled;
    }
}
