import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.private.mpris as Mpris
import org.kde.kirigami as Kirigami
import "studio" as Studio
import "../code/Layouts.js" as LayoutSizes
import "../code/PresentationSettings.js" as Presentations
import "debug"

PlasmoidItem {
    id: root

    // The media card supplies the panel hover content.
    toolTipMainText: ""
    toolTipSubText: ""

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
    Layout.minimumWidth: shouldShow ? (inPanel ? (panelPlacement.vertical ? 30 : panelPlacement.preferredSize[0]) : Math.min(160, LayoutSizes.size(plasmoid.configuration)[0])) : 0
    Layout.minimumHeight: shouldShow ? (inPanel ? (panelPlacement.vertical ? panelPlacement.preferredSize[1] : 30) : Math.min(64, LayoutSizes.size(plasmoid.configuration)[1])) : 0
    Layout.preferredWidth: shouldShow ? (inPanel ? panelPlacement.preferredSize[0] : LayoutSizes.size(plasmoid.configuration)[0]) : 0
    Layout.preferredHeight: shouldShow ? (inPanel ? panelPlacement.preferredSize[1] : LayoutSizes.size(plasmoid.configuration)[1]) : 0
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
    // Our full representation chooses a full card or the compact fallback.
    switchWidth: 0
    switchHeight: 0
    preferredRepresentation: fullRepresentation
    readonly property var panelConfiguration: Presentations.resolve(effectiveConfiguration, "panel")
    readonly property var popupConfiguration: Presentations.resolve(effectiveConfiguration, "popup")
    PanelPresentation {
        id: panelPlacement
        cardConfiguration: root.popupConfiguration
        pillConfiguration: root.panelConfiguration
        availableSize: Qt.size(root.width, root.height)
        vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        rightEdge: Plasmoid.location === PlasmaCore.Types.RightEdge
        orientation: plasmoid.configuration.panelOrientation ?? "auto"
        displayMode: plasmoid.configuration.panelDisplayMode ?? "adaptive"
        cardSizing: plasmoid.configuration.panelCardSizing ?? "fit"
        cardScale: plasmoid.configuration.panelCardScale ?? 1
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

    function toggleCardPopup(anchor) {
        if (!inPanel) {
            expanded = !expanded;
            return;
        }
        popupState.toggle(anchor);
    }

    PanelPopupState {
        id: popupState
        available: root.inPanel && root.shouldShow && !panelPlacement.showCard
        trigger: root.panelConfiguration.pillPopupTrigger ?? "both"
        popupHovered: popupHover.hovered
        onPinnedChanged: if (pinned)
            Qt.callLater(() => {
                if (cardPopup.visible)
                    cardPopup.requestActivate();
            })
    }

    PopupMask {
        id: popupMask
        configuration: root.popupConfiguration
        instance: Plasmoid.id
        dialogVisible: cardPopup.visible
    }
    PopupBlur {
        id: popupBlur
        dialog: cardPopup
        enabledBlur: popupMask.wanted
        maskPath: popupMask.path
    }

    // The native frame only supplies a rounded blur mask; PopupBlur suppresses
    // its paint and shadow. Unsupported Plasma versions retain NoBackground.
    PlasmaCore.Dialog {
        id: cardPopup
        type: PlasmaCore.Dialog.PopupMenu
        flags: Qt.Window | (popupState.pinned ? 0 : Qt.WindowDoesNotAcceptFocus) | (popupState.keepOpen ? Qt.WindowStaysOnTopHint : 0)
        location: Plasmoid.location
        backgroundHints: popupBlur.ready ? PlasmaCore.Dialog.StandardBackground : PlasmaCore.Dialog.NoBackground
        hideOnWindowDeactivate: !popupState.keepOpen
        visualParent: popupState.anchor
        visible: popupState.opened
        onVisibleChanged: if (!visible)
            popupState.dismiss()
        mainItem: Item {
            visible: cardPopup.visible
            HoverHandler {
                id: popupHover
            }
            // Transparent space for the custom card's shadow.
            readonly property real cardMargin: 12
            width: LayoutSizes.size(root.popupConfiguration)[0] + cardMargin * 2
            height: LayoutSizes.size(root.popupConfiguration)[1] + cardMargin * 2
            focus: true
            Keys.onEscapePressed: popupState.dismiss()
            Controls.AbstractButton {
                id: popupPin
                objectName: "popupPin"
                anchors.bottom: popupView.bottom
                anchors.right: popupView.right
                anchors.margins: 6
                width: 20
                height: 20
                z: 2
                opacity: popupState.keepOpen || popupHover.hovered || activeFocus ? 1 : 0
                checkable: true
                checked: popupState.keepOpen
                Accessible.name: checked ? "Unpin and close popup" : "Keep popup open"
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: Accessible.name
                onClicked: popupState.togglePin()
                background: Rectangle {
                    radius: height / 2
                    readonly property color tint: popupPin.checked ? popupView.controlsAccent : popupView.controlColor
                    color: Qt.rgba(tint.r, tint.g, tint.b, popupPin.checked ? 0.22 : popupPin.hovered ? 0.14 : 0.06)
                    border.color: Qt.rgba(tint.r, tint.g, tint.b, popupPin.checked || popupPin.activeFocus ? 0.7 : 0.18)
                }
                contentItem: Kirigami.Icon {
                    source: "window-pin"
                    implicitWidth: 16
                    implicitHeight: 16
                    color: popupPin.checked ? popupView.controlsAccent : popupView.controlColor
                }
                padding: 3
            }
            VisualizerView {
                id: popupView
                anchors.fill: parent
                anchors.margins: parent.cardMargin
                surfaceEffectMargin: parent.cardMargin
                configuration: root.popupConfiguration
                positionUnitsPerSecond: 1000000
                visualizer: vis
                player: mpris2Model.currentPlayer
                playerCount: mpris2Model.playerRows
                switchPlayer: mpris2Model.cyclePlayer
                onBattery: powerSource.onBattery
                isPlaying: player?.playbackStatus === Mpris.PlaybackStatus.Playing
                accentColor: Kirigami.Theme.highlightColor
                systemTextColor: Kirigami.Theme.textColor
                defaultFontFamily: Kirigami.Theme.defaultFont.family
                DetailsPopup {
                    view: popupView
                    active: cardPopup.visible
                }
                fallbackIcon: Component {
                    Kirigami.Icon {
                        source: Qt.resolvedUrl("../../icon.png")
                    }
                }
            }
        }
    }

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
        plasmoidVisible: root.visible || cardPopup.visible
        configuration: cardPopup.visible ? root.popupConfiguration : root.inPanel ? panelPlacement.configuration : root.effectiveConfiguration
        active: (root.visible || cardPopup.visible) && root.shouldShow && root.width > 0 && root.height > 0
    }
    fullRepresentation: FittedFrame {
        id: fullFrame
        // A roomy panel displays the card inline. Small panels display the
        // pill and open the same card in the borderless popup above.
        contentRotation: root.inPanel ? panelPlacement.contentRotation : 0
        readonly property var cardConfiguration: root.inPanel ? panelPlacement.configuration : root.effectiveConfiguration
        fitContents: !["lyrics", "visualizer"].includes(LayoutSizes.mode(cardConfiguration))
        designSize: {
            const dimensions = LayoutSizes.size(cardConfiguration);
            return Qt.size(dimensions[0], dimensions[1]);
        }
        Layout.preferredWidth: root.inPanel ? panelPlacement.preferredSize[0] : implicitWidth
        Layout.preferredHeight: root.inPanel ? panelPlacement.preferredSize[1] : implicitHeight
        Layout.minimumWidth: root.inPanel && !panelPlacement.vertical ? panelPlacement.preferredSize[0] : 0
        Layout.minimumHeight: root.inPanel && panelPlacement.vertical ? panelPlacement.preferredSize[1] : 0
        VisualizerView {
            id: view
            backdropSource: root.desktopWallpaper
            renderScale: fullFrame.fitScale
            anchors.fill: parent
            configuration: fullFrame.cardConfiguration
            positionUnitsPerSecond: 1000000
            visualizer: vis
            player: mpris2Model.currentPlayer
            playerCount: mpris2Model.playerRows
            onBattery: powerSource.onBattery
            switchPlayer: mpris2Model.cyclePlayer
            isPlaying: player?.playbackStatus === Mpris.PlaybackStatus.Playing
            accentColor: Kirigami.Theme.highlightColor
            systemTextColor: Kirigami.Theme.textColor
            defaultFontFamily: Kirigami.Theme.defaultFont.family
            // Use the same borderless card popup for both panel forms.
            onPopupRequested: root.toggleCardPopup(fullFrame)
            onCardHoveredChanged: if (root.inPanel && view.panelForm)
                popupState.hover(fullFrame, cardHovered)
            DetailsPopup {
                view: parent
            }
            fallbackIcon: Component {
                Kirigami.Icon {
                    source: view.desktopEntry !== "" ? view.desktopEntry : Qt.resolvedUrl("../../icon.png")
                }
            }
        }
    }
}
