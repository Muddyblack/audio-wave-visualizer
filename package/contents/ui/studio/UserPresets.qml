import QtQuick
import "Theme.js" as Theme
import "Schema.js" as Schema

// Saved looks: grid, name field with Save,
// Copy as JSON and Import JSON. Placement keys are never saved.
Column {
    id: saved
    required property var studio
    readonly property var list: Schema.parseUserPresets(studio.draft.userPresets ?? "")
    readonly property int columns: Math.max(1, Math.floor((width + 8) / 158))
    readonly property real tileWidth: (width - (columns - 1) * 8) / columns
    property bool favoritesOnly: false
    property bool importing: false
    property string message: ""
    spacing: 10

    function save() {
        const name = nameInput.text.trim();
        if (name === "")
            return;
        studio.saveUserPreset(name);
        nameInput.text = "";
        message = "";
    }

    PresetTools {
        width: parent.width
        studio: saved.studio
        visible: !saved.favoritesOnly
    }
    Flow {
        width: parent.width
        spacing: 8
        visible: saved.list.length > 0
        Repeater {
            model: saved.list.length
            PresetTile {
                required property int index
                objectName: "userPreset_" + index
                readonly property var look: saved.list[index]
                readonly property var lookSettings: Schema.normalize(look.settings)
                visible: !saved.favoritesOnly || saved.studio.favorites.indexOf(look.id) !== -1
                favorite: saved.studio.favorites.indexOf(look.id) !== -1
                onFavoriteToggled: saved.studio.toggleFavorite(look.id)
                width: saved.tileWidth
                studio: saved.studio
                name: look.name
                backdrop: "breeze"
                settings: Schema.applyPreset(saved.studio.defaults, {}, lookSettings, false)
                active: Schema.matchesPreset(saved.studio.defaults, saved.studio.draft, {
                    s: lookSettings
                })
                deletable: true
                renamable: true
                onRenamed: name => saved.studio.renameUserPreset(index, name)
                onPicked: saved.studio.applyLook(lookSettings)
                onRemoved: saved.studio.removeUserPreset(index)
            }
        }
    }
    Text {
        visible: !saved.favoritesOnly && saved.list.length === 0
        text: "No saved looks yet."
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }

    Flow {
        visible: !saved.favoritesOnly
        width: parent.width
        spacing: 8
        Rectangle {
            width: Math.max(140, Math.min(260, saved.width - 280))
            height: 32
            radius: 8
            color: Theme.sunk
            border.color: nameInput.activeFocus ? "#66d1e5bd" : Theme.line2
            border.width: 1
            TextInput {
                id: nameInput
                objectName: "userPresetName"
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 12
                clip: true
                onAccepted: saved.save()
            }
            Text {
                anchors.fill: nameInput
                verticalAlignment: Text.AlignVCenter
                visible: nameInput.text === ""
                text: "My look"
                color: Theme.dim
                font: nameInput.font
            }
        }
        StudioButton {
            primary: true
            text: "Save"
            areaName: "saveUserPreset"
            onClicked: saved.save()
        }
        StudioButton {
            compact: true
            text: "Copy as JSON"
            onClicked: {
                clipboard.text = Schema.exportPreset(nameInput.text.trim() || "My look", saved.studio.draft, saved.studio.defaults);
                clipboard.selectAll();
                clipboard.copy();
                saved.message = "Copied.";
            }
        }
        StudioButton {
            compact: true
            text: "Import JSON"
            onClicked: saved.importing = !saved.importing
        }
    }

    Rectangle {
        visible: saved.importing
        width: parent.width
        height: 72
        radius: 8
        color: Theme.sunk
        border.color: Theme.line2
        border.width: 1
        TextEdit {
            id: importInput
            anchors.fill: parent
            anchors.margins: 8
            color: Theme.text
            font.family: "monospace"
            font.pixelSize: 11
            wrapMode: TextEdit.WrapAnywhere
            clip: true
        }
    }
    Row {
        visible: saved.importing
        spacing: 8
        StudioButton {
            primary: true
            text: "Import"
            onClicked: {
                try {
                    saved.studio.addUserPreset(Schema.importPreset(importInput.text, saved.studio.defaults));
                    importInput.text = "";
                    saved.importing = false;
                    saved.message = "";
                } catch (error) {
                    saved.message = error.message || "That is not a valid look.";
                }
            }
        }
    }
    Text {
        visible: saved.message !== ""
        text: saved.message
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }
    Text {
        visible: !saved.favoritesOnly
        width: parent.width
        text: "To share a saved look, select it, then Copy as JSON. Others can paste it into Import JSON. Custom QML files are not included. Want it bundled for everyone? Submit the JSON and a screenshot in a pull request."
        wrapMode: Text.WordWrap
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }
    StudioButton {
        visible: !saved.favoritesOnly
        text: "How to contribute a preset ↗"
        onClicked: Qt.openUrlExternally(Schema.SHARE_URL)
    }
    TextEdit {
        id: clipboard
        visible: false
    }
}
