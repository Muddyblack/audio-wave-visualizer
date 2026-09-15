import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.private.mpris as Mpris
import org.kde.kirigami as Kirigami
import "../code/Layouts.js" as LayoutSizes

PlasmoidItem {
    id: root
    readonly property bool shouldShow: !!mpris2Model.currentPlayer || plasmoid.configuration.alwaysVisible
    Layout.minimumWidth: shouldShow ? (plasmoid.configuration.showMpris ? 260 : 160) : 0
    Layout.minimumHeight: shouldShow ? Math.min(64, LayoutSizes.size(plasmoid.configuration)[1]) : 0
    Layout.preferredWidth: shouldShow ? LayoutSizes.size(plasmoid.configuration)[0] : 0
    Layout.preferredHeight: shouldShow ? LayoutSizes.size(plasmoid.configuration)[1] : 0
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: "NoBackground"

    Mpris.Mpris2Model {
        id: mpris2Model
        // Row 0 is Plasma's automatic player choice; the others are players.
        property int playerRows: 0
        function refreshRows() {
            playerRows = Math.max(0, rowCount() - 1);
        }
        function cyclePlayer() {
            if (playerRows > 0)
                currentIndex = currentIndex % playerRows + 1;
        }
        onRowsInserted: refreshRows()
        onRowsRemoved: refreshRows()
        onModelReset: refreshRows()
        Component.onCompleted: refreshRows()
    }
    // Power source for the battery saver.
    Plasma5Support.DataSource {
        id: powerSource
        engine: "powermanagement"
        connectedSources: plasmoid.configuration.batterySaver ? ["AC Adapter"] : []
        readonly property bool onBattery: plasmoid.configuration.batterySaver && data["AC Adapter"] !== undefined && data["AC Adapter"]["Plugged in"] === false
    }
    Visualizer {
        id: vis
        batterySaverActive: powerSource.onBattery
        active: root.visible && root.shouldShow && root.width > 0 && root.height > 0
    }
    fullRepresentation: VisualizerView {
        id: view
        configuration: plasmoid.configuration
        visualizer: vis
        player: mpris2Model.currentPlayer
        playerCount: mpris2Model.playerRows
        onBattery: powerSource.onBattery
        switchPlayer: mpris2Model.cyclePlayer
        isPlaying: player?.playbackStatus === Mpris.PlaybackStatus.Playing
        accentColor: Kirigami.Theme.highlightColor
        systemTextColor: Kirigami.Theme.textColor
        defaultFontFamily: Kirigami.Theme.defaultFont.family
        coverPalette: artColors
        Image {
            id: paletteImage
            source: (view.configuration.accentFromArt || view.configuration.vizColorMode === "cover") ? view.artUrl : ""
            sourceSize: Qt.size(64, 64)
            width: 64
            height: 64
            visible: false
            asynchronous: true
            onStatusChanged: {
                if (status === Image.Ready)
                    artColors.update();
            }
        }
        Kirigami.ImageColors {
            id: artColors
            source: paletteImage.status === Image.Ready ? paletteImage : null
            fallbackDominant: view.baseWaveColor
            fallbackDominantContrasting: view.baseWaveColor
            fallbackHighlight: view.baseWaveColor
        }
        // Hover details (tooltip or drawer) in a borderless popup below the card.
        PlasmaCore.Dialog {
            id: detailsDialog
            // Named so the details' own `view` property does not shadow it.
            readonly property var cardView: view
            type: PlasmaCore.Dialog.Tooltip
            flags: Qt.WindowDoesNotAcceptFocus
            location: PlasmaCore.Types.Floating
            backgroundHints: PlasmaCore.Dialog.NoBackground
            visualParent: view
            visible: view.detailsVisible
            mainItem: TrackDetails {
                width: Math.max(detailsDialog.cardView.width, 250)
                height: implicitHeight
                view: detailsDialog.cardView
                mode: detailsDialog.cardView.detailsPopupMode
            }
        }
        fallbackIcon: Component {
            Kirigami.Icon {
                source: view.desktopEntry !== "" ? view.desktopEntry : "audio-x-generic-symbolic"
            }
        }
    }
}
