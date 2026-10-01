import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.private.mpris as Mpris
import org.kde.kirigami as Kirigami
import "studio" as Studio
import "../code/Layouts.js" as LayoutSizes
import "debug"

PlasmoidItem {
    id: root

    // Diagnostics only: see debug/GpuDebug.qml.
    readonly property string gpuDebug: plasmoid.configuration.gpuDebug ?? ""
    onGpuDebugChanged: GpuDebug.apply(gpuDebug)
    Component.onCompleted: GpuDebug.apply(gpuDebug)
    Studio.DailyLookController {
        configuration: root.effectiveConfiguration
        onApply: next => {
            for (const key of plasmoid.configuration.keys()) {
                if (next[key] !== undefined && next[key] !== plasmoid.configuration[key])
                    plasmoid.configuration[key] = next[key];
            }
        }
    }
    readonly property bool shouldShow: !!mpris2Model.currentPlayer || plasmoid.configuration.alwaysVisible
    Layout.minimumWidth: shouldShow ? Math.min(160, LayoutSizes.size(plasmoid.configuration)[0]) : 0
    Layout.minimumHeight: shouldShow ? Math.min(64, LayoutSizes.size(plasmoid.configuration)[1]) : 0
    Layout.preferredWidth: shouldShow ? LayoutSizes.size(plasmoid.configuration)[0] : 0
    Layout.preferredHeight: shouldShow ? LayoutSizes.size(plasmoid.configuration)[1] : 0
    // Respect Plasma's system animation preference without writing over the
    // user's own reduced-motion setting.
    readonly property var effectiveConfiguration: {
        const source = plasmoid.configuration, copy = {};
        for (const key of source.keys())
            copy[key] = source[key];
        copy.reducedMotion = source.reducedMotion || Kirigami.Units.longDuration === 0;
        return copy;
    }
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    // When autoPillInPanel is on, let Plasma show the full representation
    // inline whenever the panel can fit at least a small panel form (30 × 30
    // for a pill-icon).  The full representation then picks the best layout
    // for the available space: the user's chosen layout when it fits, or a
    // pill / pill-icon fallback when it does not.
    // When the option is off the full card is always used (switchWidth 0).
    switchWidth: inPanel && plasmoid.configuration.autoPillInPanel ? 30 : 0
    switchHeight: inPanel && plasmoid.configuration.autoPillInPanel ? 30 : 0
    // The popup card: Classic with a card, glass unless a material is chosen,
    // at least 14 px radius, lifted shadow and no hover details.
    readonly property var popupConfiguration: {
        const source = root.effectiveConfiguration, copy = {};
        for (const key of Object.keys(source))
            copy[key] = source[key];
        return Object.assign(copy, {
            layoutMode: "classic",
            showBg: true,
            surfaceStyle: source.showBg ? source.surfaceStyle : "glass",
            bgRadius: Math.max(14, source.bgRadius),
            cardShadow: "lifted",
            hoverDetails: "off"
        });
    }
    // Desktop wallpaper is a separate scene item, safe to sample without
    // capturing our own text or other applets. Panel popups use another window.
    readonly property Item desktopWallpaper: {
        if (inPanel)
            return null;
        for (let item = root.parent; item; item = item.parent)
            if (item instanceof ContainmentItem)
                return item.wallpaper;
        return null;
    }
    // Let Plasma's theme own native blur/contrast when explicitly selected.
    Plasmoid.backgroundHints: (root.effectiveConfiguration.compositorGlass ?? false) && root.effectiveConfiguration.showBg && ["glass", "liquid"].includes(root.effectiveConfiguration.surfaceStyle) ? "TranslucentBackground" : "NoBackground"

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
    compactRepresentation: VisualizerView {
        id: pill
        presentation: Plasmoid.formFactor === PlasmaCore.Types.Vertical || plasmoid.configuration.layoutMode === "pillicon" ? "pillicon" : "pill"
        configuration: root.effectiveConfiguration
        visualizer: vis
        player: mpris2Model.currentPlayer
        isPlaying: player?.playbackStatus === Mpris.PlaybackStatus.Playing
        playerCount: mpris2Model.playerRows
        switchPlayer: mpris2Model.cyclePlayer
        onBattery: powerSource.onBattery
        accentColor: Kirigami.Theme.highlightColor
        systemTextColor: Kirigami.Theme.textColor
        defaultFontFamily: Kirigami.Theme.defaultFont.family
        Layout.minimumWidth: shouldShow ? implicitWidth : 0
        Layout.preferredWidth: shouldShow ? implicitWidth : 0
        Layout.maximumWidth: shouldShow ? implicitWidth : 0
        Layout.minimumHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? implicitHeight : 0
        onPopupRequested: root.expanded = !root.expanded
        fallbackIcon: Component {
            Kirigami.Icon {
                source: pill.desktopEntry !== "" ? pill.desktopEntry : Qt.resolvedUrl("../../icon.png")
            }
        }
    }
    fullRepresentation: FittedFrame {
        id: fullFrame
        // When inPanel, the full rep may be shown inline (panel is big
        // enough for at least a pill) or as a popup (expanded from the
        // compact pill).  Only the popup should use popupConfiguration.
        readonly property bool isPopup: root.inPanel && root.expanded
        // Check whether the user's chosen layout fits the space the panel
        // actually gave us.  When it does not, fall back to a compact panel
        // form so the widget still renders inline instead of scaling the
        // full card down to an unreadable size.
        readonly property var chosenDesignSize: LayoutSizes.size(root.effectiveConfiguration)
        readonly property bool chosenLayoutFits: !root.inPanel || isPopup || (root.width >= chosenDesignSize[0] && root.height >= chosenDesignSize[1])
        readonly property var inlinePanelConfig: {
            const source = root.effectiveConfiguration, copy = {};
            for (const key of Object.keys(source))
                copy[key] = source[key];
            copy.layoutMode = Plasmoid.formFactor === PlasmaCore.Types.Vertical || plasmoid.configuration.layoutMode === "pillicon" ? "pillicon" : "pill";
            return copy;
        }
        readonly property var cardConfiguration: isPopup ? root.popupConfiguration : chosenLayoutFits ? root.effectiveConfiguration : inlinePanelConfig
        fitContents: !["lyrics", "visualizer"].includes(LayoutSizes.mode(cardConfiguration))
        designSize: {
            const dimensions = LayoutSizes.size(cardConfiguration);
            return Qt.size(dimensions[0], dimensions[1]);
        }
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        VisualizerView {
            id: view
            backdropSource: root.desktopWallpaper
            renderScale: fullFrame.fitScale
            anchors.fill: parent
            configuration: fullFrame.cardConfiguration
            visualizer: vis
            player: mpris2Model.currentPlayer
            playerCount: mpris2Model.playerRows
            onBattery: powerSource.onBattery
            switchPlayer: mpris2Model.cyclePlayer
            isPlaying: player?.playbackStatus === Mpris.PlaybackStatus.Playing
            accentColor: Kirigami.Theme.highlightColor
            systemTextColor: Kirigami.Theme.textColor
            defaultFontFamily: Kirigami.Theme.defaultFont.family
            // Pill click in an inline panel form: let Plasma open a popup
            // with the full card (same as the compact representation does).
            onPopupRequested: root.expanded = !root.expanded
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
                    source: view.desktopEntry !== "" ? view.desktopEntry : Qt.resolvedUrl("../../icon.png")
                }
            }
        }
    }
}
