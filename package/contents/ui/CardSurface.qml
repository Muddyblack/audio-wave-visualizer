import QtQuick
import QtQuick.Effects

// Cached card layers remain separate from the animated foreground.
Item {
    id: root
    required property var configuration
    property string artUrl: ""
    property bool hasPlayer: false

    // ── Background card source (rendered offscreen, used by backgroundCardEffect) ──
    // Art image source — must be a sibling, not child of backgroundCard
    Image {
        id: bgArtImg
        anchors.fill: parent
        source: (root.configuration.showMpris && root.configuration.artBg) ? root.artUrl : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
    }

    Rectangle {
        id: backgroundCard
        anchors.fill: parent
        visible: false
        radius: root.configuration.bgRadius
        color: "transparent"
        clip: true

        // Crisp art fill — light blur keeps the cover clearly recognizable
        // (premium "bold cover" look) while still softening hard detail so
        // the wave/text read on top. Brighter + saturated vs the old heavy
        // frosted treatment.
        MultiEffect {
            anchors.fill: parent
            source: bgArtImg
            blurEnabled: true
            // User-controlled blur (0 = crisp cover, 1 = heavy frost).
            blur: root.configuration.artBgBlur
            blurMax: 48
            saturation: 0.85
            opacity: (root.configuration.artBg && bgArtImg.status === Image.Ready) ? 1.0 : 0.0
            Behavior on blur {
                NumberAnimation {
                    duration: 250
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 400
                }
            }
        }

        // Whether the album art is actually being used as the fill right now.
        property bool artMode: root.configuration.artBg && bgArtImg.status === Image.Ready

        // Solid-colour fill — ONLY when not in art mode (art mode has its
        // own image fill above). Kept as its own rectangle (no gradient on
        // it) so there's never a color↔gradient conflict on a single
        // Rectangle, which was painting the whole card black.
        //
        // While idle (no MPRIS player at all — nothing to show art or a
        // custom colour for) fall back to a soft glass tint instead of the
        // raw configured bgColor, which otherwise defaults to near-black
        // and reads as a dead solid box. This mirrors the dock's default
        // glass look and keeps the idle state looking clean rather than
        // just "off". Once a player appears, the user's configured
        // background (colour or art) takes over as before.
        Rectangle {
            anchors.fill: parent
            visible: !backgroundCard.artMode
            color: root.hasPlayer ? root.configuration.bgColor : Qt.rgba(1, 1, 1, 0.06)
        }

        // NOTE: the art-darkness scrim is intentionally NOT here. backgroundCard
        // is visible:false and used only as a texture source for
        // backgroundCardEffect, so changing a child's opacity inside it does
        // not re-trigger the MultiEffect's texture capture (blur works because
        // it's a live property on the effect pipeline; child opacity does not).
        // The scrim lives in the live scene on top of the effect instead —
        // see `artScrim` below.

        // Border on top
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: root.configuration.bgRadius
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
        }
    }

    MultiEffect {
        id: backgroundCardEffect
        anchors.fill: parent
        source: backgroundCard
        visible: root.configuration.showBg

        // Round the whole composited card (art + tint + border) in one pass.
        maskEnabled: true
        maskSource: cardRoundMask

        // Background card transparency — art + blur fade together as one layer.
        // Wave, text and controls remain fully opaque on top.
        opacity: root.configuration.artBgTransparency
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
    }

    // Rounded-rectangle alpha mask for backgroundCardEffect. Rendered to a
    // texture (layer.enabled) so the MultiEffect can sample it; never shown.
    Rectangle {
        id: cardRoundMask
        anchors.fill: parent
        radius: root.configuration.bgRadius
        color: "black"
        visible: false
        layer.enabled: true
    }

    // Art-darkness scrim — LIVE in the scene (not inside the captured
    // backgroundCard source), so its opacity reacts instantly to the slider.
    // A plain Rectangle's own rounded gradient fill stays inside its corners
    // (the earlier corner-leak only affected clipped CHILDREN), so radius +
    // antialiasing is enough here without a separate mask pass.
    Rectangle {
        id: artScrim
        anchors.fill: parent
        antialiasing: true
        radius: root.configuration.bgRadius
        visible: root.configuration.showBg && root.configuration.artBg && bgArtImg.status === Image.Ready
        // 0 = art fully visible · 1 = strongly dimmed for readability.
        // Also inherits the background transparency so it fades with the card.
        opacity: root.configuration.artBgDim * root.configuration.artBgTransparency
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(0, 0, 0, 0.72)
            }
            GradientStop {
                position: 0.5
                color: Qt.rgba(0, 0, 0, 0.85)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(0, 0, 0, 0.98)
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
    }
}
