pragma Singleton
import QtQuick

// Hardcoded pixel sizes are designed around an 11 px title. px() scales them so
// that title matches the user's system font, as other Qt apps' text does; the
// display scale then applies to both alike.
QtObject {
    // The "Follow system font size" setting; main.qml and the studio set it.
    property bool follow: true
    // Read through here so tests can try other system fonts.
    property real points: Qt.application.font.pointSize

    readonly property real factor: {
        if (!follow || !(points > 0))
            return 1;
        // A point is 4/3 of Qt's logical pixel. Fixed-size cards hold up to a
        // 14 px title (tst_textfit); past that, resizing the widget scales them.
        return Math.min(14 / 11, Math.max(0.75, points * 4 / 3 / 11));
    }

    // `limit` caps the result for text that sits in fixed-height chrome (pill,
    // panel progress row) so a large system font cannot outgrow the card.
    function px(size, limit) {
        // Small labels stay readable once the card is scaled to the widget.
        const scaled = Math.max(follow ? 10 : 1, Math.round(size * factor));
        return limit > 0 ? Math.min(scaled, Math.max(size, limit)) : scaled;
    }
}
