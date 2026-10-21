pragma Singleton
import QtQuick

// Hardcoded pixel sizes are designed for Plasma's default 10pt font. px()
// scales them by how far the user's system font is from that, so the card
// and the settings follow Appearance > Fonts like other Qt apps.
QtObject {
    readonly property real factor: {
        const pt = Qt.application.font.pointSize;
        return pt > 0 ? Math.min(3, Math.max(0.75, pt / 10)) : 1;
    }

    function px(size) {
        return Math.max(1, Math.round(size * factor));
    }
}
