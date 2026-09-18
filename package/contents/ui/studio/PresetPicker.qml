import QtQuick
import "Theme.js" as Theme
import "Schema.js" as Schema

Column {
    id: picker
    required property var studio
    readonly property int columns: Math.max(1, Math.floor((width + 8) / 158))
    readonly property real tileWidth: (width - (columns - 1) * 8) / columns
    readonly property bool favoritesOnly: studio.presetFilter === "favorites"
    readonly property var looks: (studio.presetFilter === "daily" ? [studio.daily] : Schema.PRESETS).filter(p => favoritesOnly ? studio.favorites.indexOf(p.id) !== -1 : studio.presetFilter === "all" || studio.presetFilter === "daily" || p.cat.indexOf(studio.presetFilter) !== -1)
    spacing: 10

    PresetTools {
        width: parent.width
        studio: picker.studio
        showFilter: !picker.favoritesOnly && picker.studio.presetFilter !== "daily"
    }
    Text {
        width: parent.width
        visible: picker.studio.presetFilter === "daily"
        text: picker.studio.daily.note + ". The same look all day; changes tomorrow. Save it to keep it."
        wrapMode: Text.WordWrap
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }
    Flow {
        width: parent.width
        spacing: 8
        Repeater {
            model: picker.looks
            PresetTile {
                required property var modelData
                readonly property var look: modelData
                objectName: "preset_" + look.id
                width: picker.tileWidth
                studio: picker.studio
                name: look.name
                backdrop: look.bd
                settings: Schema.applyPreset(picker.studio.defaults, {}, look.s, false)
                active: Schema.matchesPreset(picker.studio.defaults, picker.studio.draft, look)
                favorite: picker.studio.favorites.indexOf(look.id) !== -1
                onFavoriteToggled: {
                    if (look.id === picker.studio.daily.id)
                        picker.studio.saveDaily();
                    picker.studio.toggleFavorite(look.id);
                }
                onPicked: picker.studio.applyLook(look.s)
            }
        }
    }
    StudioButton {
        visible: picker.studio.presetFilter === "daily"
        readonly property bool saved: picker.studio.userPresetList().some(p => p.id === picker.studio.daily.id)
        text: saved ? "Saved to My presets" : "Save today’s look"
        enabled: !saved
        onClicked: picker.studio.saveDaily()
    }
    Column {
        width: parent.width
        spacing: 8
        visible: picker.studio.presetFilter === "daily"
        Row {
            spacing: 8
            StudioSwitch {
                checked: picker.studio.draft.autoDailyLook ?? false
                onToggled: checked => picker.studio.update({
                        autoDailyLook: checked
                    })
            }
            Text {
                text: "Apply today’s look automatically"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }
        Text {
            width: parent.width
            text: "After you apply settings, changes the look once per day on startup or while running. Manual changes stay until tomorrow. Audio settings and placement are kept."
            color: Theme.muted
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }
    Loader {
        width: parent.width
        active: picker.favoritesOnly
        visible: active
        sourceComponent: UserPresets {
            studio: picker.studio
            favoritesOnly: true
        }
    }
    Text {
        width: parent.width
        visible: picker.favoritesOnly && picker.looks.length === 0 && !picker.studio.userPresetList().some(p => picker.studio.favorites.indexOf(p.id) !== -1)
        text: "Star a built-in or saved look to find it here."
        color: Theme.muted
        wrapMode: Text.WordWrap
        font.pixelSize: 12
    }
}
