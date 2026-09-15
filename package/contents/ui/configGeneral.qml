import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    id: root

    property alias cfg_visualizerType: visualizerTypeCombo.currentIndex
    property alias cfg_progressBarStyle: progressBarStyleCombo.currentIndex
    property alias cfg_numBars: numBarsSpin.value
    property alias cfg_sensitivity: sensitivitySlider.value
    property alias cfg_framerate: framerateSpin.value
    property alias cfg_noiseReduction: noiseReductionSlider.value
    // ComboBox.currentValue is read-only, so this one is a plain property the
    // combo writes into (the Default pairing is what KCM resets to).
    property string cfg_inputMethod: "auto"
    property string cfg_inputMethodDefault: "auto"

    property alias cfg_showTimes: showTimesCheckBox.checked
    property string cfg_timeFormat: "total"
    property string cfg_timeFormatDefault: "total"
    property string cfg_vizDirection: "up"
    property string cfg_vizDirectionDefault: "up"
    property string cfg_vizColorMode: "solid"
    property string cfg_vizColorModeDefault: "solid"
    property string cfg_vizPalette: "aurora"
    property string cfg_vizPaletteDefault: "aurora"
    property alias cfg_hueReactive: hueReactiveCheckBox.checked
    property alias cfg_bloom: bloomSlider.value
    property alias cfg_ribbonCurvature: ribbonCurvatureSlider.value
    property alias cfg_ribbonFullness: ribbonFullnessSlider.value
    property alias cfg_accentFromArt: accentFromArtCheckBox.checked
    property alias cfg_reducedMotion: reducedMotionCheckBox.checked
    property alias cfg_simpleRender: simpleRenderCheckBox.checked

    property alias cfg_showMpris: showMprisCheckBox.checked
    property alias cfg_alwaysVisible: alwaysVisibleCheckBox.checked
    property alias cfg_useSystemAccent: useSystemAccentCheckBox.checked
    property alias cfg_customColor: customColorButton.color
    property alias cfg_lineWidth: lineWidthSlider.value
    property alias cfg_fillWave: fillWaveCheckBox.checked
    property alias cfg_glowWave: glowWaveCheckBox.checked
    property alias cfg_useSystemText: useSystemTextCheckBox.checked
    property alias cfg_customTextColor: customTextColorButton.color
    property alias cfg_useSystemControls: useSystemControlsCheckBox.checked
    property alias cfg_customControlColor: customControlColorButton.color
    property alias cfg_useSystemDockBg: useSystemDockBgCheckBox.checked
    property alias cfg_customDockBgColor: customDockBgColorButton.color

    property alias cfg_showBg: showBgCheckBox.checked
    property alias cfg_bgColor: bgColorButton.color
    property alias cfg_bgRadius: bgRadiusSlider.value
    property alias cfg_artBg: artBgCheckBox.checked
    property alias cfg_artBgDim: artBgDimSlider.value
    property alias cfg_artBgBlur: artBgBlurSlider.value
    property alias cfg_artBgTransparency: artBgTransparencySlider.value
    property alias cfg_showArtThumb: showArtThumbCheckBox.checked
    property alias cfg_artBgKeepThumb: artBgKeepThumbCheckBox.checked

    Kirigami.FormLayout {
        // Cava Settings Section
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Audio Visualizer (Cava)")
        }

        QQC.SpinBox {
            id: numBarsSpin
            Kirigami.FormData.label: i18n("Number of Bars:")
            from: 8
            to: 128
            stepSize: 2
        }

        QQC.SpinBox {
            id: framerateSpin
            Kirigami.FormData.label: i18n("Framerate (Hz):")
            from: 15
            to: 144
            stepSize: 5
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Sensitivity:")
            QQC.Slider {
                id: sensitivitySlider
                from: 10
                to: 300
                stepSize: 5
                Layout.fillWidth: true
            }
            QQC.Label {
                text: sensitivitySlider.value + "%"
                Layout.minimumWidth: 40
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Smoothing (Noise Reduction):")
            QQC.Slider {
                id: noiseReductionSlider
                from: 0.0
                to: 1.0
                stepSize: 0.05
                Layout.fillWidth: true
            }
            QQC.Label {
                text: noiseReductionSlider.value.toFixed(2)
                Layout.minimumWidth: 40
            }
        }

        QQC.ComboBox {
            id: inputMethodCombo
            Kirigami.FormData.label: i18n("Audio Input:")
            textRole: "label"
            valueRole: "value"
            model: [
                {
                    label: i18n("Auto-detect"),
                    value: "auto"
                },
                {
                    label: i18n("PipeWire"),
                    value: "pipewire"
                },
                {
                    label: i18n("PulseAudio"),
                    value: "pulse"
                },
                {
                    label: i18n("ALSA (snd_aloop)"),
                    value: "alsa"
                }
            ]
            onActivated: root.cfg_inputMethod = currentValue
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(root.cfg_inputMethod))
        }

        QQC.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 18
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            text: i18n("Auto-detect tries PipeWire, then PulseAudio, then ALSA, and keeps the first one cava can actually capture from.")
        }

        // Visual Settings Section
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Appearance & Layout")
        }

        QQC.CheckBox {
            id: showMprisCheckBox
            Kirigami.FormData.label: i18n("Layout:")
            text: i18n("Show album art and track info")
        }

        QQC.CheckBox {
            id: alwaysVisibleCheckBox
            Kirigami.FormData.label: i18n("Visibility:")
            text: i18n("Keep widget visible when nothing is playing")
        }

        QQC.CheckBox {
            id: showArtThumbCheckBox
            Kirigami.FormData.label: i18n("Album Art:")
            text: i18n("Show album art thumbnail")
            visible: showMprisCheckBox.checked
        }

        QQC.ComboBox {
            id: visualizerTypeCombo
            Kirigami.FormData.label: i18n("Visualizer Style:")
            model: [i18n("Smooth Wave"), i18n("Rounded Bars"), i18n("Mirror Bars"), i18n("Tech Line"), i18n("Floating Dots"), i18n("Floating Dots Bold"), i18n("Peak Bars"), i18n("LED Meter"), i18n("Mountain"), i18n("Oscilloscope"), i18n("Ribbon"), i18n("Radial Burst"), i18n("Pixel Matrix"), i18n("Pulse Orb"), i18n("Sparkles"), i18n("Silk Ribbon")]
        }

        QQC.ComboBox {
            Kirigami.FormData.label: i18n("Direction:")
            visible: [1, 6, 7, 8].indexOf(root.cfg_visualizerType) !== -1
            textRole: "label"
            valueRole: "value"
            model: [
                {
                    label: i18n("Up"),
                    value: "up"
                },
                {
                    label: i18n("Down"),
                    value: "down"
                }
            ]
            currentIndex: Math.max(0, ["up", "down"].indexOf(root.cfg_vizDirection))
            onActivated: root.cfg_vizDirection = currentValue
        }

        QQC.ComboBox {
            Kirigami.FormData.label: i18n("Wave colours:")
            visible: true
            textRole: "label"
            valueRole: "value"
            model: [
                {
                    label: i18n("Accent"),
                    value: "solid"
                },
                {
                    label: i18n("Gradient"),
                    value: "gradient"
                },
                {
                    label: i18n("From cover"),
                    value: "cover"
                },
                {
                    label: i18n("Palette"),
                    value: "palette"
                },
                {
                    label: i18n("Rainbow"),
                    value: "rainbow"
                }
            ]
            currentIndex: Math.max(0, ["solid", "gradient", "cover", "palette", "rainbow"].indexOf(root.cfg_vizColorMode))
            onActivated: root.cfg_vizColorMode = currentValue
        }

        QQC.ComboBox {
            Kirigami.FormData.label: i18n("Palette:")
            visible: root.cfg_vizColorMode === "palette"
            textRole: "label"
            valueRole: "value"
            model: [
                {
                    label: i18n("Aurora"),
                    value: "aurora"
                },
                {
                    label: i18n("Ember"),
                    value: "ember"
                },
                {
                    label: i18n("Ice"),
                    value: "ice"
                },
                {
                    label: i18n("Grove"),
                    value: "grove"
                },
                {
                    label: i18n("Iris"),
                    value: "iris"
                },
                {
                    label: i18n("Coral"),
                    value: "coral"
                }
            ]
            currentIndex: Math.max(0, ["aurora", "ember", "ice", "grove", "iris", "coral"].indexOf(root.cfg_vizPalette))
            onActivated: root.cfg_vizPalette = currentValue
        }

        QQC.CheckBox {
            id: hueReactiveCheckBox
            text: i18n("Music-reactive hue")
            visible: true
        }

        QQC.CheckBox {
            id: accentFromArtCheckBox
            text: i18n("Use accent from cover")
            visible: true
        }

        QQC.CheckBox {
            id: reducedMotionCheckBox
            text: i18n("Reduce decorative motion")
            visible: true
        }

        QQC.CheckBox {
            id: simpleRenderCheckBox
            text: i18n("Use software renderer")
            visible: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Bloom:")
            visible: root.cfg_glowWave
            QQC.Slider {
                id: bloomSlider
                from: 0
                to: 1.5
                stepSize: 0.05
                Layout.fillWidth: true
            }
            QQC.Label {
                text: Math.round(bloomSlider.value * 100) + "%"
                Layout.minimumWidth: 40
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Ribbon curvature:")
            visible: root.cfg_visualizerType === 15
            QQC.Slider {
                id: ribbonCurvatureSlider
                from: 0.5
                to: 1.25
                stepSize: 0.05
                Layout.fillWidth: true
            }
            QQC.Label {
                text: Math.round(ribbonCurvatureSlider.value * 100) + "%"
                Layout.minimumWidth: 40
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Ribbon fullness:")
            visible: root.cfg_visualizerType === 15
            QQC.Slider {
                id: ribbonFullnessSlider
                from: 0.6
                to: 1.3
                stepSize: 0.05
                Layout.fillWidth: true
            }
            QQC.Label {
                text: Math.round(ribbonFullnessSlider.value * 100) + "%"
                Layout.minimumWidth: 40
            }
        }

        QQC.ComboBox {
            id: progressBarStyleCombo
            Kirigami.FormData.label: i18n("Progress Bar Style:")
            model: [i18n("Glassy Sleek"), i18n("Ultra Minimal"), i18n("Glowing Pulse"), i18n("Bold Pill"), i18n("Waveform"), i18n("Squiggle"), i18n("Segmented"), i18n("Dotted"), i18n("Capsule"), i18n("Time only"), i18n("Cover ring")]
        }

        QQC.CheckBox {
            id: showTimesCheckBox
            Kirigami.FormData.label: i18n("Time labels:")
            text: i18n("Elapsed and total time under the bar")
        }

        QQC.ComboBox {
            Kirigami.FormData.label: i18n("Time format:")
            visible: root.cfg_showTimes || progressBarStyleCombo.currentIndex === 9
            textRole: "label"
            valueRole: "value"
            model: [
                {
                    label: i18n("1:31 · 3:58"),
                    value: "total"
                },
                {
                    label: i18n("1:31 · -2:27"),
                    value: "remaining"
                }
            ]
            currentIndex: Math.max(0, ["total", "remaining"].indexOf(root.cfg_timeFormat))
            onActivated: root.cfg_timeFormat = currentValue
        }

        QQC.CheckBox {
            id: fillWaveCheckBox
            Kirigami.FormData.label: i18n("Wave Style:")
            text: i18n("Fill waveform with transparent gradient")
        }

        QQC.CheckBox {
            id: glowWaveCheckBox
            Kirigami.FormData.label: i18n("Wave Glow:")
            text: i18n("Enable neon glow effect on wave")
        }

        QQC.CheckBox {
            id: useSystemAccentCheckBox
            Kirigami.FormData.label: i18n("Wave Color:")
            text: i18n("Use system accent color")
        }

        KQuickControls.ColorButton {
            id: customColorButton
            text: i18n("Custom Wave Color")
            visible: !useSystemAccentCheckBox.checked
        }

        QQC.CheckBox {
            id: useSystemTextCheckBox
            Kirigami.FormData.label: i18n("Text Color:")
            text: i18n("Use system text color")
        }

        KQuickControls.ColorButton {
            id: customTextColorButton
            text: i18n("Custom Text Color")
            visible: !useSystemTextCheckBox.checked
        }

        QQC.CheckBox {
            id: useSystemControlsCheckBox
            Kirigami.FormData.label: i18n("Controls Color:")
            text: i18n("Use system/default colors")
        }

        KQuickControls.ColorButton {
            id: customControlColorButton
            text: i18n("Custom Controls Color")
            visible: !useSystemControlsCheckBox.checked
        }

        QQC.CheckBox {
            id: useSystemDockBgCheckBox
            Kirigami.FormData.label: i18n("Dock Background:")
            text: i18n("Use default glass dock background")
        }

        KQuickControls.ColorButton {
            id: customDockBgColorButton
            text: i18n("Custom Dock Color")
            visible: !useSystemDockBgCheckBox.checked
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Line Width:")
            QQC.Slider {
                id: lineWidthSlider
                from: 1.0
                to: 8.0
                stepSize: 0.2
                Layout.fillWidth: true
            }
            QQC.Label {
                text: lineWidthSlider.value.toFixed(1)
                Layout.minimumWidth: 30
            }
        }

        // Background Settings Section
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Background Card")
        }

        QQC.CheckBox {
            id: showBgCheckBox
            Kirigami.FormData.label: i18n("Background:")
            text: i18n("Show background card")
        }

        QQC.CheckBox {
            id: artBgCheckBox
            Kirigami.FormData.label: i18n("Art Background:")
            text: i18n("Use album art as the background")
            enabled: showMprisCheckBox.checked
            visible: showBgCheckBox.checked
        }

        QQC.Label {
            Kirigami.FormData.label: ""
            visible: showBgCheckBox.checked && artBgCheckBox.checked
            text: i18n("Cover art fills the card. By default the small thumbnail is hidden since the art is already shown. Use the sliders below to tune blur and darkness.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        }

        QQC.CheckBox {
            id: artBgKeepThumbCheckBox
            Kirigami.FormData.label: ""
            text: i18n("Keep the sharp thumbnail over the background")
            // Lets the crisp cover sit on top of its own blurred/darkened self
            // (Spotify-style). Needs the thumbnail master toggle on too.
            enabled: showArtThumbCheckBox.checked
            visible: showBgCheckBox.checked && artBgCheckBox.checked && showMprisCheckBox.checked
        }

        QQC.Label {
            Kirigami.FormData.label: ""
            visible: showBgCheckBox.checked && artBgCheckBox.checked && !showMprisCheckBox.checked
            text: i18n("Enable “Show album art and track info” above to use art backgrounds.")
            font: Kirigami.Theme.smallFont
            color: Kirigami.Theme.neutralTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        }

        RowLayout {
            visible: showBgCheckBox.checked && artBgCheckBox.checked
            Kirigami.FormData.label: i18n("Art Blur:")
            QQC.Slider {
                id: artBgBlurSlider
                from: 0.0
                to: 1.0
                stepSize: 0.02
                Layout.fillWidth: true
            }
            QQC.Label {
                text: Math.round(artBgBlurSlider.value * 100) + "%"
                Layout.minimumWidth: 40
            }
        }

        RowLayout {
            visible: showBgCheckBox.checked && artBgCheckBox.checked
            Kirigami.FormData.label: i18n("Art Darkness:")
            QQC.Slider {
                id: artBgDimSlider
                from: 0.0
                to: 1.0
                stepSize: 0.02
                Layout.fillWidth: true
            }
            QQC.Label {
                text: Math.round(artBgDimSlider.value * 100) + "%"
                Layout.minimumWidth: 40
            }
        }

        RowLayout {
            visible: showBgCheckBox.checked
            Kirigami.FormData.label: i18n("Transparency:")
            QQC.Slider {
                id: artBgTransparencySlider
                from: 0.0
                to: 1.0
                stepSize: 0.02
                Layout.fillWidth: true
            }
            QQC.Label {
                text: Math.round(artBgTransparencySlider.value * 100) + "%"
                Layout.minimumWidth: 40
            }
        }

        KQuickControls.ColorButton {
            id: bgColorButton
            text: i18n("Background Color")
            visible: showBgCheckBox.checked && !artBgCheckBox.checked
        }

        RowLayout {
            visible: showBgCheckBox.checked
            Kirigami.FormData.label: i18n("Corner Radius:")
            QQC.Slider {
                id: bgRadiusSlider
                from: 0.0
                to: 30.0
                stepSize: 1.0
                Layout.fillWidth: true
            }
            QQC.Label {
                text: bgRadiusSlider.value + "px"
                Layout.minimumWidth: 40
            }
        }
    }
}
