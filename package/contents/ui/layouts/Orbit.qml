import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import ".."
import "../../code/Layouts.js" as Layouts
import "../../code/OrbitMotion.js" as OrbitMotion

// Square ring box with the cover in the centre and the visualizer around it;
// centred title/artist, progress and dock below. `orbitCenter` can move the
// title into the ring (with or without the cover) or leave the ring empty.
Item {
    id: root
    required property var view
    readonly property var cfg: view.configuration
    readonly property bool bg: cfg.showBg
    readonly property string center: cfg.orbitCenter ?? "cover"
    readonly property bool textInside: center === "coverText" || center === "text"
    readonly property bool coverInside: center === "cover" || center === "coverText"
    // The ring stays square in a taller or wider host and gives way to whatever
    // the texts, progress and dock below it need.
    readonly property real box: Math.max(0, Math.min(width - (bg ? 60 : 28), height - (bg ? 26 : 8) - column.spacing * 3 - (textInside ? 0 : texts.implicitHeight) - progress.implicitHeight - dock.implicitHeight))
    readonly property real coverSize: Math.round(Math.min(box * 0.56, box * 0.38 * (cfg.artScale ?? 100) / 100))
    // Diameter of the ring's hole: the cover, or room for the title inside.
    readonly property real hole: center === "cover" ? coverSize : Math.round(box * 0.6)
    readonly property real ringRadius: OrbitMotion.geometry({
        width: box,
        height: box,
        coverRatio: box > 0 ? hole / box : 0.38,
        orbitReach: 1
    }).inner
    // Square inscribed in the hole, where the centred contents must fit.
    readonly property real inner: Math.max(0, Math.floor(hole * Math.SQRT1_2))
    implicitWidth: Layouts.size(cfg)[0]
    implicitHeight: Layouts.size(cfg)[1]

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.leftMargin: root.bg ? 16 : 4
        anchors.rightMargin: root.bg ? 16 : 4
        anchors.topMargin: root.bg ? 14 : 4
        anchors.bottomMargin: root.bg ? 12 : 4
        spacing: 8

        Item {
            Layout.preferredWidth: root.box
            Layout.preferredHeight: root.box
            Layout.alignment: Qt.AlignHCenter

            // Light pooled on the ring's base circle, brighter with the bass.
            Shape {
                id: glowRing
                objectName: "orbitGlowRing"
                readonly property real band: Math.max(6, root.ringRadius * 0.28)
                readonly property real outer: root.ringRadius + band
                readonly property color tint: orbit.glowTint.a > 0 ? orbit.glowTint : (orbit.colorStops[0] ?? root.view.waveColor)
                visible: (root.cfg.orbitGlowRing ?? false) && root.box > 0
                anchors.fill: parent
                opacity: (root.cfg.reducedMotion ?? false) ? 0.85 : 0.6 + Math.min(1, root.view.visualizer.bass ?? 0) * 0.4
                ShapePath {
                    strokeWidth: -1
                    fillGradient: RadialGradient {
                        centerX: root.box / 2
                        centerY: root.box / 2
                        centerRadius: glowRing.outer
                        focalX: centerX
                        focalY: centerY
                        GradientStop {
                            position: 0
                            color: "transparent"
                        }
                        GradientStop {
                            position: Math.max(0, (root.ringRadius - glowRing.band) / glowRing.outer)
                            color: "transparent"
                        }
                        GradientStop {
                            position: Math.max(0, (root.ringRadius - 2) / glowRing.outer)
                            color: Qt.rgba(glowRing.tint.r, glowRing.tint.g, glowRing.tint.b, 0.55)
                        }
                        GradientStop {
                            position: root.ringRadius / glowRing.outer
                            color: Qt.rgba(glowRing.tint.r, glowRing.tint.g, glowRing.tint.b, 0.95)
                        }
                        GradientStop {
                            position: Math.min(1, (root.ringRadius + 2) / glowRing.outer)
                            color: Qt.rgba(glowRing.tint.r, glowRing.tint.g, glowRing.tint.b, 0.45)
                        }
                        GradientStop {
                            position: 1
                            color: "transparent"
                        }
                    }
                    PathAngleArc {
                        centerX: root.box / 2
                        centerY: root.box / 2
                        radiusX: glowRing.outer
                        radiusY: glowRing.outer
                        sweepAngle: 360
                    }
                }
            }

            OrbitView {
                id: orbit
                simpleRender: root.cfg.simpleRender ?? false
                objectName: "orbitCanvas"
                anchors.fill: parent
                coverRatio: root.box > 0 ? root.hole / root.box : 0.38
                bars: root.view.visualizer.bars ?? []
                numBars: root.view.visualizer.numBars ?? 24
                maxRange: root.view.visualizer.maxRange ?? 1000
                hasAudio: root.view.visualizer.hasAudio ?? false
                backendFailed: root.view.visualizer.backendFailed ?? false
                visualFrameTime: root.view.visualFrameTime
                high: root.view.visualizer.high ?? 0
                waveColor: root.view.waveColor
                coverColor1: root.view.coverColor1
                coverColor2: root.view.coverColor2
                vizColorMode: root.cfg.vizColorMode ?? "solid"
                vizPalette: root.cfg.vizColorMode === "custom" ? (root.cfg.vizCustomColors ?? "") : (root.cfg.vizPalette ?? "aurora")
                glowColors: root.cfg.glowColorMode === "custom" ? (root.cfg.glowCustomColors ?? "") : ""
                hueReactive: root.cfg.hueReactive ?? false
                lineWidth: root.cfg.lineWidth
                fillWave: root.cfg.fillWave
                glowWave: root.cfg.glowWave && !root.view.batterySaving
                bloom: root.cfg.bloom ?? 1
                reducedMotion: root.cfg.reducedMotion ?? false
                orbitStyle: root.cfg.orbitStyle ?? "bars"
                orbitReach: root.cfg.orbitReach ?? 1
                orbitRotate: root.cfg.orbitRotate ?? true
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: root.textInside ? root.inner : implicitWidth
                spacing: 4

                LayoutArt {
                    id: art
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                    visible: shown && root.coverInside
                    view: root.view
                    // A wide cover keeps the square cover's diagonal, so it
                    // stays inside the ring's hole.
                    size: (root.textInside ? Math.max(0, Math.min(root.hole * 0.42, root.inner - innerTexts.implicitHeight - parent.spacing)) : root.coverSize) * Math.SQRT2 / Math.hypot(ratio, 1)
                    ringShrink: 8
                    // The cover breathes with the bass, which arrives with audio frames.
                    scale: (root.cfg.orbitCoverPulse ?? true) && !(root.cfg.reducedMotion ?? false) ? 1 + (root.view.visualizer.bass ?? 0) * 0.07 : 1
                }
                LayoutTexts {
                    id: innerTexts
                    visible: root.textInside
                    view: root.view
                    titleFactor: 1.1
                    artistSize: 0.9
                    alignmentOverride: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }
        }
        LayoutTexts {
            id: texts
            visible: !root.textInside
            view: root.view
            titleFactor: 1.3
            artistSize: 0.95
            alignmentOverride: Text.AlignHCenter
            Layout.fillWidth: true
        }
        LayoutProgress {
            id: progress
            view: root.view
            artShown: art.visible
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
        }
        LayoutDock {
            id: dock
            view: root.view
            Layout.alignment: Qt.AlignHCenter
        }
        Item {
            Layout.fillHeight: true
        }
    }
}
