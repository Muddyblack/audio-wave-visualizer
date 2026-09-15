import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

VisualizerCore {
    configuration: plasmoid.configuration
    plasmoidVisible: plasmoid.visible === undefined ? true : plasmoid.visible
    commandSourceComponent: Component {
        Plasma5Support.DataSource {
            engine: "executable"
            connectedSources: []
        }
    }
}
