import QtQuick
import QtQuick.Shapes

// Small filled icons stay as scene-graph geometry when the card is scaled.
Item {
    id: icon
    property string path: ""
    property color color: "white"
    property real designSize: 24

    Shape {
        width: icon.designSize
        height: icon.designSize
        antialiasing: true
        transform: Scale {
            xScale: icon.width / icon.designSize
            yScale: icon.height / icon.designSize
        }
        ShapePath {
            strokeColor: "transparent"
            fillColor: icon.color
            PathSvg {
                path: icon.path
            }
        }
    }
}
