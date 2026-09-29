import QtQuick

VisualizerCore {
    configuration: plasmoid.configuration
    plasmoidVisible: plasmoid.visible === undefined ? true : plasmoid.visible
    commandSourceComponent: Component {
        PlasmaCommandSource {}
    }
}
