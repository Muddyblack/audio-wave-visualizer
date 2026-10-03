import QtQuick
import QtQuick.Controls.Basic as Controls
import ".." as Shared
import "Theme.js" as Theme
import "Schema.js" as Schema

// The shared settings studio for Plasma and Hyprland,
// styled after the HTML studio. Hosts own the draft: every change is emitted
// through `edited(next)` and the host assigns it back to `draft`.
Rectangle {
    // Children bind `studio: studioRoot`: their own `studio` property would
    // shadow an id of the same name.
    id: studioRoot
    property var draft: ({})
    property var defaults: ({})
    property string presentationTarget: "desktop"
    property int previewRotation: 0
    property string libraryPath: ""
    property alias presetLibrary: library
    // "kde" or "hypr": platform notes and placement rows.
    property string env: "kde"
    property var screenNames: []
    // function(done(text)) running contents/code/doctor.sh, or null.
    property var diagnosticsRunner: null
    property Component commandSourceComponent: null
    property string dependencyReport: ""
    readonly property string dependencyWarning: {
        if (env !== "kde")
            return "";
        const missing = [];
        if (/^python3: missing$/m.test(dependencyReport))
            missing.push("Python 3");
        if (/^busctl: missing$/m.test(dependencyReport))
            missing.push("busctl");
        if (!missing.length)
            return "";
        const install = /^distro: (nixos|nix)$/m.test(dependencyReport) ? "On NixOS, add pkgs.python3 and pkgs.systemd to environment.systemPackages, rebuild, then sign out and in." : "Install the missing tools with your distribution's package manager, then restart Plasma.";
        return "Browser site names and media details need " + missing.join(" and ") + ". " + install;
    }
    Shared.CommandSource {
        id: dependencyCheck
        sourceComponent: studioRoot.commandSourceComponent
        onNewData: function (source, data) {
            disconnectSource(source);
            studioRoot.dependencyReport = data["stdout"] || "";
        }
    }
    Timer {
        interval: 15000
        running: studioRoot.env === "kde" && studioRoot.onScreen && !!studioRoot.commandSourceComponent
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (dependencyCheck.connectedSources.length)
                return;
            const path = decodeURIComponent(Qt.resolvedUrl("../../code/media_metadata.sh").toString().replace(/^file:\/\//, ""));
            dependencyCheck.connectSource("'" + path.replace(/'/g, "'\\''") + "' --check");
        }
    }
    property var discoveredSources: [["auto", "Default output monitor"]]
    readonly property var audioSourceOptions: discoveredSources.some(o => o[0] === (draft.inputSource || "auto")) ? discoveredSources : discoveredSources.concat([[draft.inputSource, "Unavailable: " + draft.inputSource]])
    Shared.CommandSource {
        id: sourceDiscovery
        sourceComponent: studioRoot.commandSourceComponent
        onNewData: function (source, data) {
            disconnectSource(source);
            try {
                const choices = JSON.parse(data["stdout"] || "[]");
                if (choices.length)
                    studioRoot.discoveredSources = choices;
            } catch (error) { /* Keep the saved selection during discovery failures. */ }
        }
    }
    Timer {
        interval: 5000
        running: studioRoot.onScreen && studioRoot.currentTab === "audio" && !!studioRoot.commandSourceComponent
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!sourceDiscovery.connectedSources.length) {
                const path = Qt.resolvedUrl("../../code/audio_sources.py").toString().replace(/^file:\/\//, "");
                sourceDiscovery.connectSource("python3 '" + path.replace(/'/g, "'\\''") + "' list");
            }
        }
    }
    property color previewAccent: "#3daee9"
    property bool livePreview: false
    property var liveVisualizer: null
    property var livePlayer: null
    property bool liveIsPlaying: false
    property real livePositionUnitsPerSecond: 0
    property int currentTabIndex: 0
    property string query: ""
    onCurrentTabIndexChanged: body.contentY = 0
    property bool keepColors: false
    property string presetFilter: "all"
    property string day: Schema.localDay()
    readonly property var daily: Schema.dailyLook(day)
    PresetLibrary {
        id: library
        filePath: studioRoot.libraryPath
        active: studioRoot.onScreen
    }
    readonly property var favorites: library.favorites
    onReadyChanged: if (ready)
        library.migrate(draft.favoritePresets, draft.userPresets)
    onDraftChanged: if (ready)
        library.migrate(draft.favoritePresets, draft.userPresets)
    function toggleFavorite(id) {
        library.refresh();
        const current = library.favorites;
        library.setFavorites(current.indexOf(id) === -1 ? current.concat([id]) : current.filter(value => value !== id));
    }
    function saveDaily() {
        library.refresh();
        const id = daily.id;
        if (!userPresetList().some(p => p.id === id))
            library.setPresets(userPresetList().concat([
                {
                    id: id,
                    name: daily.name,
                    settings: daily.s
                }
            ]));
    }
    Timer {
        interval: 30000
        repeat: true
        running: studioRoot.onScreen
        triggeredOnStart: true
        onTriggered: studioRoot.day = Schema.localDay()
    }
    readonly property string currentGroup: Schema.tabGroup(currentTab)
    function selectTab(id) {
        currentTabIndex = Schema.TABS.findIndex(t => t.id === id);
        query = "";
    }
    property bool canDiscard: false
    // Optional controls supplied by the host beside the settings search.
    property Component toolbarExtra: null
    signal previewPopupRequested
    signal edited(var draft)
    signal discard
    signal undo

    readonly property string currentTab: Schema.TABS[currentTabIndex].id
    // Nothing renders until the host has supplied a draft.
    readonly property bool ready: !!draft && draft.showMpris !== undefined
    // Previews animate only while the settings window is actually shown.
    readonly property bool onScreen: visible && !!Window.window && Window.window.visible
    readonly property color accent: draft.useSystemAccent === false ? draft.customColor : previewAccent
    readonly property var monitorOptions: [["", "First available display"], ["all", "Every monitor"]].concat(screenNames.map(name => [name, name]))
    // Keep the layout from bouncing between modes while the dialog is dragged
    // near a breakpoint. Width and height can move in opposite directions as
    // the host negotiates the page's size.
    property bool wide: false
    property bool compact: false
    function updateLayoutMode() {
        wide = wide ? width >= 960 : width >= 1040;
        compact = !wide && (compact ? height < 660 : height < 620);
    }
    onWidthChanged: updateLayoutMode()
    onHeightChanged: updateLayoutMode()
    Component.onCompleted: updateLayoutMode()
    readonly property int inset: compact ? 10 : 20
    readonly property bool anyResults: Schema.SECTIONS.some(section => section.rows.some(row => rowVisible(row, section)) && (query.trim() !== "" || section.tab === currentTab))
    property alias backend: tileBackend
    property alias stillBackend: stillBackend
    property alias samplePlayer: samplePlayer

    function acceptsPreset(settings) {
        const panel = ["pill", "pillicon"].includes(settings.layoutMode || "classic");
        return presentationTarget === "desktop" || panel === (presentationTarget === "panel");
    }
    readonly property var appearanceTabs: Schema.TABS.filter(tab => Schema.APPEARANCE_TABS.includes(tab.id))
    readonly property var mainTabs: Schema.MAIN_TABS.filter(tab => presentationTarget !== "panel" || tab.id !== "lyrics")
    onPresentationTargetChanged: {
        presetFilter = "all";
        if (currentGroup === "appearance" || (presentationTarget === "panel" && currentTab === "lyrics"))
            selectTab("layout");
    }
    onAppearanceTabsChanged: {
        if (currentGroup === "appearance" && !appearanceTabs.some(tab => tab.id === currentTab))
            selectTab("layout");
    }

    function rowVisible(row, section) {
        if (section.title === "Panel placement" && presentationTarget === "desktop")
            return false;
        if (env === "kde" && presentationTarget === "popup" && row.k === "glassRefraction")
            return false;
        if (env === "kde" && presentationTarget === "popup" && row.k === "compositorGlass" && draft.artBg)
            return false;
        if (presentationTarget !== "desktop" && row.k === "autoPillInPanel")
            return false;
        if (presentationTarget === "panel") {
            if (section.tab === "lyrics" || (section.tab === "buttons" && section.title === "Playback buttons"))
                return false;
            if (section.tab === "buttons" && ["dockSrc", "customDockBgColor"].includes(row.id || row.k))
                return false;
        }
        return Schema.rowVisible(row, section, draft, env, query.trim().toLowerCase());
    }
    function rowDefinition(row) {
        if (env === "kde" && presentationTarget === "popup" && row.k === "glassBlur")
            return Object.assign({}, row, {
                label: "Preview wallpaper blur",
                desc: "Adjusts wallpaper blur in this preview. Actual popup blur strength is set in KDE System Settings → Desktop Effects → Blur."
            });
        if (env === "kde" && presentationTarget === "popup" && row.k === "compositorGlass")
            return Object.assign({}, row, {
                label: "Blur behind card",
                desc: "Blur application windows behind the rounded card. Requires KWin’s Blur effect."
            });
        if (row.k === "pillClick" && env === "kde")
            return Object.assign({}, row, {
                label: "Click action",
                opts: [["popup", "Nothing"], ["toggle", "Play / pause"]]
            });
        if (row.k === "pillEq" && draft.layoutMode === "pillicon")
            return Object.assign({}, row, {
                opts: [["off", "Off"], ["static", "Static"], ["live", "Bouncing"], ["wave", "Orbit"], ["visualizer", "Mini visualizer"]]
            });
        if (row.k !== "layoutMode" || presentationTarget === "desktop")
            return row;
        return Object.assign({}, row, {
            opts: row.opts.filter(option => (["pill", "pillicon"].includes(option.v)) === (presentationTarget === "panel"))
        });
    }

    function update(patch) {
        const next = Schema.normalize(patch);
        if (presentationTarget === "panel") {
            if (next.visualizerType !== undefined || next.customVisualizer !== undefined)
                next.pillEq = draft.layoutMode === "pillicon" ? "visualizer" : "wave";
            if (next.progressBarStyle !== undefined || next.customProgressBar !== undefined)
                next.pillProgress = next.progressBarStyle === -1 && !next.customProgressBar ? "off" : next.progressBarStyle === 10 && !next.customProgressBar ? "ring" : "bar";
        }
        edited(Object.assign({}, draft, next));
    }
    function applyLook(settings) {
        if (!acceptsPreset(settings))
            return;
        const next = Schema.applyPreset(defaults, draft, settings, keepColors);
        edited(next);
    }
    function userPresetList() {
        return library.presets;
    }
    function addUserPreset(entry) {
        library.refresh();
        const list = userPresetList();
        list.push({
            id: "u" + Date.now(),
            name: entry.name,
            settings: entry.settings
        });
        library.setPresets(list);
    }
    function saveUserPreset(name) {
        addUserPreset({
            name: name,
            settings: Object.assign(Schema.changedKeys(defaults, draft), {
                layoutMode: draft.layoutMode
            })
        });
    }
    function renameUserPreset(index, name) {
        library.refresh();
        const list = userPresetList();
        const trimmed = String(name).trim();
        if (!trimmed || !Number.isInteger(index) || index < 0 || index >= list.length)
            return false;
        list[index] = Object.assign({}, list[index], {
            name: trimmed
        });
        library.setPresets(list);
        return true;
    }
    function removeUserPreset(index) {
        library.refresh();
        const list = userPresetList();
        const removed = list.splice(index, 1)[0];
        if (removed && favorites.indexOf(removed.id) !== -1)
            toggleFavorite(removed.id);
        library.setPresets(list);
    }

    color: Theme.bg
    onQueryChanged: {
        body.contentY = 0;
        if (searchInput.text !== query)
            searchInput.text = query;
    }

    PreviewBackend {
        id: tileBackend
        // Only waveform, progress and artwork tiles consume animated frames.
        // Search can expose these rows outside their normal tabs.
        running: studioRoot.onScreen && (studioRoot.query.trim() !== "" || ["viz", "controls", "art"].indexOf(studioRoot.currentTab) !== -1)
    }
    PreviewBackend {
        id: stillBackend
        running: false
    }
    SamplePlayer {
        id: samplePlayer
    }

    Shortcut {
        sequence: "/"
        enabled: !searchInput.activeFocus
        onActivated: searchInput.forceActiveFocus()
    }
    Shortcut {
        sequence: StandardKey.Undo
        enabled: studioRoot.canDiscard
        onActivated: studioRoot.undo()
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        y: studioRoot.inset
        width: Math.max(0, parent.width - studioRoot.inset * 2)
        height: Math.max(0, parent.height - studioRoot.inset * 2)

        PreviewPane {
            id: pane
            objectName: "studioPreviewPane"
            compact: studioRoot.compact
            studio: studioRoot
            visible: studioRoot.ready
            x: studioRoot.wide ? panel.width + 20 : 0
            width: studioRoot.wide ? parent.width - panel.width - 20 : parent.width
            height: studioRoot.wide ? Math.min(parent.height, 420) : Math.min(parent.height, Math.min(260, Math.max(112, 112 + (parent.height - 420) * 0.5)) + (studioRoot.compact && optionsExpanded ? 138 : 0))
        }

        Rectangle {
            id: panel
            y: studioRoot.wide ? 0 : pane.height + (studioRoot.compact ? 8 : 14)
            width: studioRoot.wide ? Math.max(380, (parent.width - 20) * 0.52) : parent.width
            height: studioRoot.wide ? parent.height : Math.max(0, parent.height - y)
            radius: 18
            border.color: Theme.line2
            border.width: 1
            clip: true
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Theme.panelTop
                }
                GradientStop {
                    position: 1
                    color: Theme.panelBottom
                }
            }

            Row {
                id: header
                x: 18
                y: studioRoot.compact ? 8 : 16
                width: parent.width - 36
                spacing: 8
                Rectangle {
                    width: Math.max(80, parent.width - surprise.width - (discardBtn.visible ? discardBtn.width + header.spacing : 0) - (extraSlot.hasExtra ? extraSlot.width + header.spacing : 0) - header.spacing)
                    height: 36
                    radius: 10
                    color: Theme.sunk
                    border.color: searchInput.activeFocus ? "#66d1e5bd" : Theme.line2
                    border.width: 1
                    Canvas {
                        x: 11
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        height: 14
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            ctx.scale(14 / 24, 14 / 24);
                            ctx.strokeStyle = Theme.dim;
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            ctx.arc(11, 11, 7, 0, Math.PI * 2);
                            ctx.moveTo(20, 20);
                            ctx.lineTo(16.5, 16.5);
                            ctx.stroke();
                        }
                    }
                    TextInput {
                        id: searchInput
                        objectName: "studioSearch"
                        x: 33
                        width: parent.width - 33 - 34
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        clip: true
                        onTextEdited: studioRoot.query = text
                        Keys.onEscapePressed: studioRoot.query = ""
                    }
                    Text {
                        anchors.fill: searchInput
                        verticalAlignment: Text.AlignVCenter
                        visible: searchInput.text === ""
                        text: "Search settings…"
                        color: Theme.dim
                        font: searchInput.font
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 11
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: 4
                        color: "transparent"
                        border.color: Theme.line2
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "/"
                            color: Theme.dim
                            font.pixelSize: 10
                        }
                    }
                }
                Item {
                    id: extraSlot
                    objectName: "toolbarExtraSlot"
                    readonly property bool hasExtra: studioRoot.toolbarExtra !== null
                    visible: hasExtra
                    width: hasExtra && extraLoader.item ? extraLoader.item.implicitWidth : 0
                    height: 36
                    Loader {
                        id: extraLoader
                        anchors.centerIn: parent
                        sourceComponent: studioRoot.toolbarExtra
                    }
                }
                StudioButton {
                    id: discardBtn
                    enabled: studioRoot.canDiscard
                    text: (typeof i18n === "function" ? i18n("Discard") : "Discard")
                    tooltip: "Discard unapplied changes (Verwerfen)"
                    areaName: "discardSettings"
                    onClicked: studioRoot.discard()
                }
                StudioButton {
                    id: surprise
                    text: "Surprise me"
                    onClicked: {
                        const next = Schema.surprise(studioRoot.defaults, studioRoot.draft);
                        if (studioRoot.presentationTarget === "panel")
                            next.layoutMode = studioRoot.draft.layoutMode === "pillicon" ? "pillicon" : "pill";
                        else if (studioRoot.presentationTarget === "popup" && ["pill", "pillicon"].includes(next.layoutMode))
                            next.layoutMode = "classic";
                        next.userPresets = studioRoot.draft.userPresets ?? "";
                        studioRoot.edited(next);
                    }
                }
            }

            Item {
                id: tabs
                objectName: "studioTabs"
                x: 12
                y: header.y + header.height + (studioRoot.compact ? 4 : 12)
                width: parent.width - 24
                height: 36
                clip: true
                Flickable {
                    id: mainTabScroller
                    objectName: "mainTabScroller"
                    anchors.fill: parent
                    Controls.ScrollBar.horizontal: Controls.ScrollBar {
                        policy: Controls.ScrollBar.AsNeeded
                    }
                    contentWidth: tabRow.width
                    contentHeight: height
                    boundsBehavior: Flickable.StopAtBounds
                    Row {
                        id: tabRow
                        spacing: 2
                        Repeater {
                            id: tabRepeater
                            model: studioRoot.mainTabs
                            Item {
                                id: tab
                                required property var modelData
                                required property int index
                                readonly property bool selected: studioRoot.query.trim() === "" && studioRoot.currentGroup === modelData.id
                                objectName: "mainTab_" + modelData.id
                                width: tabContent.width + 16
                                height: 36
                                Row {
                                    id: tabContent
                                    x: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.verticalCenterOffset: -1
                                    spacing: 6
                                    Canvas {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 15
                                        height: 15
                                        readonly property var signature: [tab.selected, tabArea.containsMouse]
                                        onSignatureChanged: requestPaint()
                                        onPaint: {
                                            const ctx = getContext("2d");
                                            ctx.reset();
                                            ctx.scale(15 / 24, 15 / 24);
                                            ctx.strokeStyle = tab.selected || tabArea.containsMouse ? Theme.text : Theme.muted;
                                            ctx.lineWidth = 1.7;
                                            ctx.lineCap = "round";
                                            ctx.lineJoin = "round";
                                            ctx.path = tab.modelData.icon;
                                            ctx.stroke();
                                        }
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: tab.modelData.label
                                        color: tab.selected || tabArea.containsMouse ? Theme.text : Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                    }
                                }
                                Rectangle {
                                    x: 8
                                    width: parent.width - 16
                                    height: 2
                                    radius: 1
                                    anchors.bottom: parent.bottom
                                    color: Theme.brand
                                    visible: tab.selected
                                }
                                MouseArea {
                                    id: tabArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        studioRoot.selectTab(tab.modelData.id === "appearance" ? (studioRoot.presentationTarget === "panel" ? "layout" : "viz") : tab.modelData.id);
                                        studioRoot.query = "";
                                        body.contentY = 0;
                                    }
                                }
                            }
                        }
                    }
                }
                TabScrollArrow {
                    anchors.left: parent.left
                    scroller: mainTabScroller
                    forward: false
                    areaName: "mainTabsBack"
                }
                TabScrollArrow {
                    anchors.right: parent.right
                    scroller: mainTabScroller
                    areaName: "mainTabsForward"
                }
            }
            Rectangle {
                y: tabs.y + tabs.height
                width: parent.width
                height: 1
                color: Theme.line
            }

            Item {
                id: appearanceNavigation
                objectName: "appearanceNavigation"
                x: 18
                y: tabs.y + tabs.height + 1
                width: parent.width - 36
                height: visible ? 48 : 0
                visible: studioRoot.query.trim() === "" && ["appearance", "presets"].indexOf(studioRoot.currentGroup) !== -1
                PresetNavigation {
                    anchors.fill: parent
                    studio: studioRoot
                    visible: studioRoot.currentGroup === "presets"
                }
                Flickable {
                    id: appearanceScroller
                    objectName: "appearanceScroller"
                    anchors.fill: parent
                    visible: studioRoot.currentGroup === "appearance"
                    Controls.ScrollBar.horizontal: Controls.ScrollBar {
                        policy: Controls.ScrollBar.AsNeeded
                    }
                    contentWidth: appearanceRow.width
                    contentHeight: height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Row {
                        id: appearanceRow
                        y: 10
                        spacing: 6
                        Repeater {
                            model: studioRoot.appearanceTabs
                            StudioButton {
                                required property var modelData
                                text: modelData.label
                                icon: modelData.icon
                                compact: true
                                primary: studioRoot.currentTab === modelData.id
                                areaName: "subTab_" + modelData.id
                                onClicked: studioRoot.selectTab(modelData.id)
                            }
                        }
                    }
                }
                TabScrollArrow {
                    anchors.left: parent.left
                    scroller: appearanceScroller
                    forward: false
                    areaName: "appearanceTabsBack"
                    visible: appearanceScroller.visible && appearanceScroller.contentX > 1
                    y: 10
                    height: 28
                }
                TabScrollArrow {
                    anchors.right: parent.right
                    scroller: appearanceScroller
                    areaName: "appearanceTabsForward"
                    visible: appearanceScroller.visible && appearanceScroller.contentX < limit - 1
                    y: 10
                    height: 28
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.line
                }
            }

            Flickable {
                id: body
                objectName: "studioBody"
                y: appearanceNavigation.y + appearanceNavigation.height
                width: parent.width
                height: parent.height - y
                contentHeight: sections.height + 28
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    policy: Controls.ScrollBar.AsNeeded
                }

                Column {
                    id: sections
                    x: 18
                    y: 6
                    width: body.width - 36
                    spacing: 18
                    Rectangle {
                        objectName: "dependencyBanner"
                        width: sections.width
                        height: visible ? dependencyText.implicitHeight + 24 : 0
                        visible: studioRoot.dependencyWarning !== ""
                        radius: 8
                        color: "#332b2110"
                        border.color: Theme.warn
                        border.width: 1
                        Text {
                            id: dependencyText
                            x: 12
                            y: 12
                            width: parent.width - 24
                            text: studioRoot.dependencyWarning
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }
                    Item {
                        width: 1
                        height: 0
                    }
                    Repeater {
                        model: studioRoot.ready ? Schema.SECTIONS.length : 0
                        StudioSection {
                            required property int index
                            width: sections.width
                            studio: studioRoot
                            sectionIndex: index
                        }
                    }
                    Text {
                        width: sections.width
                        visible: studioRoot.ready && !studioRoot.anyResults
                        topPadding: 30
                        horizontalAlignment: Text.AlignHCenter
                        text: studioRoot.query.trim() !== "" ? "No settings match that search." : "No settings are available for this design."
                        wrapMode: Text.WordWrap
                        color: Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
