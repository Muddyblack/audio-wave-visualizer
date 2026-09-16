import QtQuick
import QtQuick.Shapes
import "../code/ColourStyle.js" as ColourStyle

// Preserve the rounded-cover ring while circular covers get a gradient dial.
CoverRing {
    id: root
    circularDial: cornerRadius >= Math.min(width, height) / 2 - 5
    property var colorStops: []
    property color endColor: Qt.lighter(accentColor, 1.5)
    Shape {
        anchors.fill: parent
        visible: root.circularDial
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: "transparent"
            strokeColor: "#26ffffff"
            strokeWidth: root.band
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: Math.max(0, (root.width - root.band) / 2)
                radiusY: Math.max(0, (root.height - root.band) / 2)
                startAngle: -90
                sweepAngle: 360
            }
        }
        ShapePath {
            strokeColor: "transparent"
            fillGradient: ConicalGradient {
                centerX: root.width / 2
                centerY: root.height / 2
                angle: 90
                GradientStop {
                    position: 0
                    color: root.colorStops.length ? ColourStyle.sample(root.colorStops, 1) : root.endColor
                }
                GradientStop {
                    position: 0.2
                    color: root.colorStops.length ? ColourStyle.sample(root.colorStops, 0.8) : ColourStyle.sample([root.endColor, root.accentColor], 0.2)
                }
                GradientStop {
                    position: 0.4
                    color: root.colorStops.length ? ColourStyle.sample(root.colorStops, 0.6) : ColourStyle.sample([root.endColor, root.accentColor], 0.4)
                }
                GradientStop {
                    position: 0.6
                    color: root.colorStops.length ? ColourStyle.sample(root.colorStops, 0.4) : ColourStyle.sample([root.endColor, root.accentColor], 0.6)
                }
                GradientStop {
                    position: 0.8
                    color: root.colorStops.length ? ColourStyle.sample(root.colorStops, 0.2) : ColourStyle.sample([root.endColor, root.accentColor], 0.8)
                }
                GradientStop {
                    position: 1
                    color: root.colorStops.length ? ColourStyle.sample(root.colorStops, 0) : root.accentColor
                }
            }
            startX: root.width / 2
            startY: 0
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.width / 2
                radiusY: root.height / 2
                startAngle: -90
                sweepAngle: root.progress * 360
                moveToStart: false
            }
            PathLine {
                x: root.width / 2 + Math.cos((root.progress * 2 - .5) * Math.PI) * Math.max(0, root.width / 2 - root.band)
                y: root.height / 2 + Math.sin((root.progress * 2 - .5) * Math.PI) * Math.max(0, root.height / 2 - root.band)
            }
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: Math.max(0, root.width / 2 - root.band)
                radiusY: Math.max(0, root.height / 2 - root.band)
                startAngle: -90 + root.progress * 360
                sweepAngle: -root.progress * 360
                moveToStart: false
            }
            PathLine {
                x: root.width / 2
                y: 0
            }
        }
    }
    Rectangle {
        objectName: "arcPlayhead"
        visible: root.circularDial && root.progress > 0
        width: Math.max(4, root.band * 2)
        height: width
        radius: width / 2
        color: root.colorStops.length ? ColourStyle.sample(root.colorStops, 1) : root.endColor
        x: root.width / 2 + Math.cos((root.progress * 2 - .5) * Math.PI) * (root.width - root.band) / 2 - width / 2
        y: root.height / 2 + Math.sin((root.progress * 2 - .5) * Math.PI) * (root.height - root.band) / 2 - height / 2
    }
}
