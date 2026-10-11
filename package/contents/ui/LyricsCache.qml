import QtQuick
import QtQuick.LocalStorage

// Isolated so a missing QtQuick.LocalStorage module (a separate package on
// some distros) only disables the lyrics cache instead of the whole widget.
QtObject {
    function open() {
        return LocalStorage.openDatabaseSync("PlasmaAudioVisualizerLyrics", "1", "Synced lyrics cache", 2000000);
    }
}
