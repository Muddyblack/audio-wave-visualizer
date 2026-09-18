pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Dialogs
import ".."
import "Theme.js" as Theme
import "../../code/CustomStyles.js" as CustomStyles

Column {
    id: root
    objectName: "customStylePicker_" + selectionKey
    required property var studio
    property bool progressBar: false
    property bool buttons: false
    readonly property string selectionKey: buttons ? "customButtons" : progressBar ? "customProgressBar" : "customVisualizer"
    readonly property string libraryKey: buttons ? "customButtonStyles" : progressBar ? "customProgressBars" : "customVisualizers"
    readonly property string kindLabel: buttons ? "Custom button styles" : progressBar ? "Custom progress bars" : "Custom visualizers"
    readonly property string builtInLabel: buttons ? "Built-in buttons" : progressBar ? "Built-in progress bar" : "Built-in visualizer"
    readonly property var library: CustomStyles.readLibrary(studio.draft[libraryKey] ?? "")
    readonly property string selected: studio.draft[selectionKey] ?? ""
    property string message: ""
    property bool expanded: false
    spacing: expanded ? 8 : 0

    function importFile(url) {
        expanded = true;
        const source = String(url);
        if (!CustomStyles.validUrl(source)) {
            message = "Choose a local .qml file.";
            return;
        }
        const entries = library.slice();
        if (!entries.some(entry => entry.url === source))
            entries.push({
                name: CustomStyles.nameForUrl(source),
                url: source
            });
        const patch = {};
        patch[libraryKey] = JSON.stringify(entries);
        patch[selectionKey] = source;
        studio.update(patch);
        message = "";
    }

    function select(source) {
        const patch = {};
        patch[selectionKey] = source;
        studio.update(patch);
        message = "";
    }
    function removeSelected() {
        const patch = {};
        patch[selectionKey] = "";
        patch[libraryKey] = JSON.stringify(library.filter(entry => entry.url !== selected));
        studio.update(patch);
        message = "";
    }

    Item {
        width: parent.width
        height: 28
        Text {
            anchors.left: parent.left
            anchors.right: expandButton.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.kindLabel + (root.selected ? " · " + CustomStyles.nameForUrl(root.selected) : "")
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
        }
        StudioButton {
            id: expandButton
            anchors.right: parent.right
            compact: true
            text: root.expanded ? "Hide" : "Manage…"
            areaName: "expand_" + root.selectionKey
            onClicked: root.expanded = !root.expanded
        }
    }
    Column {
        width: parent.width
        visible: root.expanded
        spacing: 8
        Text {
            width: parent.width
            text: "QML styles run code with the host’s permissions. Import only files you trust. Keep the file and its assets in a permanent folder; importing remembers their location."
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
        StudioSelect {
            objectName: root.selectionKey + "Select"
            width: parent.width
            options: [["", root.builtInLabel]].concat(root.library.map(entry => [entry.url, entry.name])).concat(root.selected && !root.library.some(entry => entry.url === root.selected) ? [[root.selected, CustomStyles.nameForUrl(root.selected)]] : [])
            value: root.selected
            onChosen: value => root.select(value)
        }
        Flow {
            width: parent.width
            spacing: 8
            StudioButton {
                text: "Import QML…"
                areaName: root.buttons ? "importCustomButtons" : root.progressBar ? "importCustomProgressBar" : "importCustomVisualizer"
                onClicked: fileDialog.open()
            }
            StudioButton {
                text: "Try example"
                onClicked: root.importFile(Qt.resolvedUrl(root.buttons ? "../../examples/MinimalButtons.qml" : root.progressBar ? "../../examples/GradientProgress.qml" : "../../examples/PulseBars.qml"))
            }
            StudioButton {
                text: "Remove"
                areaName: root.buttons ? "removeCustomButtons" : root.progressBar ? "removeCustomProgressBar" : "removeCustomVisualizer"
                enabled: root.selected !== ""
                onClicked: root.removeSelected()
            }
        }
        Text {
            width: parent.width
            visible: root.selected !== ""
            text: root.selected
            color: Theme.dim
            font.pixelSize: 10
            wrapMode: Text.WrapAnywhere
        }
        Loader {
            id: preview
            width: parent.width
            height: root.selected !== "" ? (root.buttons ? 36 : root.progressBar ? 32 : 72) : 0
            active: root.expanded && root.selected !== "" && root.studio.onScreen
            sourceComponent: root.buttons ? buttonsPreview : root.progressBar ? progressPreview : waveformPreview
        }
        Component {
            id: waveformPreview
            WaveArea {
                configuration: root.studio.draft
                visualizer: root.studio.backend
                waveColor: root.studio.accent
                textColor: Theme.text
            }
        }
        Component {
            id: progressPreview
            ProgressBar {
                customProgressBar: root.selected
                player: root.studio.samplePlayer
                isPlaying: true
                style: root.studio.draft.progressBarStyle ?? 0
                textColor: Theme.text
                pgStartColor: root.studio.accent
                pgEndColor: "white"
                positionUnitsPerSecond: 1
                showTimes: root.studio.draft.showTimes ?? true
                timeFormat: root.studio.draft.timeFormat ?? "total"
                reducedMotion: root.studio.draft.reducedMotion ?? false
            }
        }
        Component {
            id: buttonsPreview
            TransportDock {
                anchors.centerIn: parent
                configuration: Object.assign({}, root.studio.draft, {
                    customButtons: root.selected
                })
                player: root.studio.samplePlayer
                isPlaying: true
                controlColor: Theme.text
                accentColor: root.studio.accent
                cardHovered: true
            }
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.message || (root.buttons ? (preview.item as TransportDock)?.customError : root.progressBar ? (preview.item as ProgressBar)?.customError : (preview.item as WaveArea)?.customError) || ""
            color: Theme.muted
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
    }
    FileDialog {
        id: fileDialog
        title: root.buttons ? "Import trusted QML buttons" : root.progressBar ? "Import trusted QML progress bar" : "Import trusted QML visualizer"
        fileMode: FileDialog.OpenFile
        nameFilters: ["QML styles (*.qml)"]
        onAccepted: root.importFile(selectedFile)
    }
}
