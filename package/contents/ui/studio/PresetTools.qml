import QtQuick
import "Schema.js" as Schema
import "Theme.js" as Theme

Item {
    id: tools
    required property var studio
    property bool showFilter: false
    implicitHeight: showFilter && width < 320 ? 66 : 32
    StudioSelect {
        visible: tools.showFilter
        width: Math.min(170, tools.width)
        options: Schema.FILTERS.map(p => [p[0], p[0] === "all" ? "All categories" : p[1]])
        value: tools.studio.presetFilter
        Accessible.name: "Preset category"
        onChosen: value => tools.studio.presetFilter = value
    }
    Row {
        anchors.right: parent.right
        y: tools.showFilter && tools.width < 320 ? 42 : 6
        spacing: 8
        StudioSwitch {
            checked: tools.studio.keepColors
            onToggled: checked => tools.studio.keepColors = checked
        }
        Text {
            text: "Keep my colours"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }
}
