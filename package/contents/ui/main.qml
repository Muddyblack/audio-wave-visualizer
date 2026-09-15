import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
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
    }
    Visualizer {
        id: vis
        active: root.visible && root.shouldShow && root.width > 0 && root.height > 0
    }
    fullRepresentation: VisualizerView {
        id: view
        configuration: plasmoid.configuration
        visualizer: vis
        player: mpris2Model.currentPlayer
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
        fallbackIcon: Component {
            Kirigami.Icon {
                source: view.desktopEntry !== "" ? view.desktopEntry : "audio-x-generic-symbolic"
            }
        }
    }
}
