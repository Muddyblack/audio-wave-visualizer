pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle {
    id: root
    color: "#1e1e2e"
    property var draft: ({})
    property var screenNames: []
    property string errorMessage: ""
    property int currentTabIndex: 0
    signal apply(var draft)
    signal reset
    signal close

    // Cycled per group, purely so a busy page of rows reads as sections at a
    // glance instead of one undifferentiated list (same trick the ai-usage
    // widget uses for its provider dots).
    readonly property var accents: ["#b4befe", "#89b4fa", "#a6e3a1", "#fab387", "#f5c2e7"]

    readonly property var groups: [
        {
            title: "Desktop",
            keys: ["monitor", "widgetWidth", "widgetHeight", "verticalPosition", "desktopLayer", "pauseWhenCovered", "alwaysVisible"]
        },
        {
            title: "Layout",
            keys: ["layoutMode", "titleSize", "textAlign", "artScale", "posterAlign", "posterLines", "posterVizBehind", "posterVizOpacity", "posterClock"]
        },
        {
            title: "Audio",
            keys: ["numBars", "framerate", "sensitivity", "noiseReduction", "inputMethod"]
        },
        {
            title: "Wave and media",
            keys: ["visualizerType", "progressBarStyle", "showTimes", "timeFormat", "showMpris", "showArtThumb", "lineWidth", "fillWave", "glowWave", "vizDirection", "ribbonCurvature", "ribbonFullness", "reducedMotion", "simpleRender"]
        },
        {
            title: "Colors",
            keys: ["waveColor", "textColor", "useSystemAccent", "customColor", "useSystemText", "customTextColor", "useSystemControls", "customControlColor", "useSystemDockBg", "customDockBgColor", "vizColorMode", "vizPalette", "hueReactive", "bloom", "accentFromArt"]
        },
        {
            title: "Background",
            keys: ["showBg", "bgColor", "bgRadius", "artBg", "artBgDim", "artBgBlur", "artBgTransparency", "artBgKeepThumb"]
        }
    ]
    readonly property var ranges: ({
            widgetWidth: [160, 1600, 10],
            widgetHeight: [64, 600, 2],
            verticalPosition: [0, 1, 0.01],
            numBars: [8, 128, 2],
            framerate: [5, 144, 1],
            sensitivity: [10, 300, 5],
            noiseReduction: [0, 1, 0.05],
            lineWidth: [1, 8, 0.1],
            bloom: [0, 1.5, 0.05],
            titleSize: [9, 16, 1],
            artScale: [60, 130, 5],
            posterLines: [1, 2, 1],
            posterVizOpacity: [0.1, 0.8, 0.05],
            ribbonCurvature: [0.5, 1.25, 0.05],
            ribbonFullness: [0.6, 1.3, 0.05],
            bgRadius: [0, 30, 1],
            artBgDim: [0, 1, 0.01],
            artBgBlur: [0, 1, 0.01],
            artBgTransparency: [0, 1, 0.01]
        })
    function choices(key) {
        if (key === "monitor")
            return [
                {
                    label: "First available display",
                    value: ""
                },
                {
                    label: "All displays (shared audio)",
                    value: "all"
                }
            ].concat(screenNames.map(name => ({
                        label: name,
                        value: name
                    })));
        if (key === "inputMethod")
            return ["auto", "pipewire", "pulse", "alsa"].map(value => ({
                        label: value,
                        value: value
                    }));
        if (key === "visualizerType")
            return ["Smooth wave", "Rounded bars", "Mirror bars", "Tech line", "Floating dots", "Floating dots bold", qsTr("Peak Bars"), qsTr("LED Meter"), qsTr("Mountain"), qsTr("Oscilloscope"), qsTr("Ribbon"), qsTr("Radial Burst"), qsTr("Pixel Matrix"), qsTr("Pulse Orb"), qsTr("Sparkles"), qsTr("Silk Ribbon")].map((label, value) => ({
                        label: label,
                        value: value
                    }));
        if (key === "progressBarStyle")
            return ["Glassy sleek", "Ultra minimal", "Glowing pulse", "Bold pill", "Waveform", qsTr("Squiggle"), qsTr("Segmented"), qsTr("Dotted"), qsTr("Capsule"), qsTr("Time only"), qsTr("Cover ring")].map((label, value) => ({
                        label: label,
                        value: value
                    }));
        const extra = {
            layoutMode: [[qsTr("Classic"), "classic"], [qsTr("Mirrored"), "mirrored"], [qsTr("Inline"), "inline"], [qsTr("Hero wave"), "hero"], [qsTr("Stacked"), "stacked"], [qsTr("Poster"), "poster"], [qsTr("Slim strip"), "strip"]],
            textAlign: [[qsTr("Left"), "left"], [qsTr("Centre"), "center"], [qsTr("Right"), "right"]],
            posterAlign: [[qsTr("Left"), "left"], [qsTr("Centre"), "center"]],
            timeFormat: [[qsTr("1:31 · 3:58"), "total"], [qsTr("1:31 · -2:27"), "remaining"]],
            vizDirection: [[qsTr("Up"), "up"], [qsTr("Down"), "down"]],
            vizColorMode: [[qsTr("Accent"), "solid"], [qsTr("Gradient"), "gradient"], [qsTr("From cover"), "cover"], [qsTr("Palette"), "palette"], [qsTr("Rainbow"), "rainbow"]],
            vizPalette: [[qsTr("Aurora"), "aurora"], [qsTr("Ember"), "ember"], [qsTr("Ice"), "ice"], [qsTr("Grove"), "grove"], [qsTr("Iris"), "iris"], [qsTr("Coral"), "coral"]]
        };
        return (extra[key] || []).map(pair => ({
                    label: pair[0],
                    value: pair[1]
                }));
    }
    function label(key) {
        const labels = {
            showTimes: qsTr("Time labels"),
            layoutMode: qsTr("Layout"),
            artScale: qsTr("Cover size (%)"),
            posterLines: qsTr("Poster title lines"),
            posterVizBehind: qsTr("Poster visualizer texture"),
            posterVizOpacity: qsTr("Poster texture strength"),
            posterClock: qsTr("Poster large clock"),
            timeFormat: qsTr("Time format"),
            vizDirection: qsTr("Direction"),
            vizColorMode: qsTr("Wave colours"),
            vizPalette: qsTr("Palette"),
            hueReactive: qsTr("Music-reactive hue"),
            bloom: qsTr("Bloom"),
            ribbonCurvature: qsTr("Ribbon curvature"),
            ribbonFullness: qsTr("Ribbon fullness"),
            accentFromArt: qsTr("Use accent from cover"),
            reducedMotion: qsTr("Reduce decorative motion"),
            simpleRender: qsTr("Use software renderer"),
            verticalPosition: "Vertical position",
            desktopLayer: "Behind application windows",
            showMpris: "Show media information",
            numBars: "Number of bars",
            noiseReduction: "Smoothing",
            artBg: "Album art background",
            artBgDim: "Art darkness",
            artBgKeepThumb: "Keep album thumbnail",
            showBg: "Show background",
            waveColor: "Accent color",
            textColor: "Theme text color"
        };
        const words = key.replace(/([A-Z])/g, " $1");
        return labels[key] || words[0].toUpperCase() + words.slice(1);
    }
    function setValue(key, value) {
        draft = Object.assign({}, draft, {
            [key]: value
        });
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Controls.Label {
                text: "Audio Visualizer"
                color: "#cdd6f4"
                font.pixelSize: 19
                font.bold: true
            }
            Controls.Label {
                text: "Apply saves local overrides. Reset returns to your configured defaults."
                color: "#a6adc8"
                font.pixelSize: 11
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }

        Flickable {
            id: tabFlickable
            Layout.fillWidth: true
            implicitHeight: 38
            contentWidth: Math.max(width, tabRow.implicitWidth)
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            RowLayout {
                id: tabRow
                width: Math.max(tabFlickable.width, implicitWidth)
                height: parent.height
                spacing: 6

                Repeater {
                    model: root.groups

                    Rectangle {
                        id: tabButton
                        required property var modelData
                        required property int index
                        readonly property bool isCurrent: root.currentTabIndex === tabButton.index
                        readonly property color accent: root.accents[tabButton.index % root.accents.length]

                        objectName: "tabButton_" + tabButton.index
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        implicitWidth: tabButtonContent.implicitWidth + 22
                        implicitHeight: 34
                        radius: 10
                        color: isCurrent ? Qt.alpha(tabButton.accent, 0.16) : tabMouse.containsMouse ? "#252538" : "#181825"
                        border.width: 1
                        border.color: isCurrent ? tabButton.accent : tabMouse.containsMouse ? "#45475a" : "#313244"

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTabIndex = tabButton.index
                        }

                        RowLayout {
                            id: tabButtonContent
                            anchors.centerIn: parent
                            spacing: 6

                            Rectangle {
                                width: 7
                                height: 7
                                radius: 3.5
                                color: tabButton.accent
                                opacity: tabButton.isCurrent ? 1.0 : 0.6
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Controls.Label {
                                text: tabButton.modelData.title
                                color: tabButton.isCurrent ? tabButton.accent : tabMouse.containsMouse ? "#cdd6f4" : "#a6adc8"
                                font.pixelSize: 11
                                font.bold: tabButton.isCurrent
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
        }

        StackLayout {
            id: tabStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentTabIndex

            Repeater {
                model: root.groups

                Controls.ScrollView {
                    id: tabScrollView
                    required property var modelData
                    required property int index
                    readonly property color accent: root.accents[tabScrollView.index % root.accents.length]

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: availableWidth
                    clip: true

                    Rectangle {
                        id: card
                        width: tabScrollView.availableWidth
                        implicitHeight: cardLayout.implicitHeight + 28
                        radius: 20
                        color: "#181825"

                        ColumnLayout {
                            id: cardLayout
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 11

                            Rectangle {
                                id: chip
                                Layout.alignment: Qt.AlignLeft
                                implicitHeight: 26
                                implicitWidth: chipRow.implicitWidth + 24
                                radius: height / 2
                                color: Qt.alpha(tabScrollView.accent, 0.16)

                                RowLayout {
                                    id: chipRow
                                    anchors.centerIn: parent
                                    spacing: 7
                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: tabScrollView.accent
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                    Controls.Label {
                                        text: tabScrollView.modelData.title
                                        color: tabScrollView.accent
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }
                            }

                            Repeater {
                                model: tabScrollView.modelData.keys
                                RowLayout {
                                    id: row
                                    required property string modelData
                                    readonly property var options: root.choices(modelData)
                                    readonly property var range: root.ranges[modelData]
                                    readonly property var value: root.draft[modelData]
                                    Layout.fillWidth: true
                                    spacing: 10
                                    Controls.Label {
                                        text: root.label(row.modelData)
                                        color: "#a6adc8"
                                        font.pixelSize: 12
                                        Layout.preferredWidth: 190
                                        wrapMode: Text.Wrap
                                    }
                                    Loader {
                                        Layout.fillWidth: true
                                        sourceComponent: row.options.length ? combo : typeof row.value === "boolean" ? toggle : row.range ? number : colorField
                                    }
                                    Component {
                                        id: combo
                                        StyledComboBox {
                                            model: row.options
                                            textRole: "label"
                                            currentIndex: Math.max(0, row.options.findIndex(option => option.value === row.value))
                                            onActivated: index => root.setValue(row.modelData, row.options[index].value)
                                        }
                                    }
                                    Component {
                                        id: toggle
                                        RowLayout {
                                            Item {
                                                Layout.fillWidth: true
                                            }
                                            StyledSwitch {
                                                checked: row.value === true
                                                onToggled: root.setValue(row.modelData, checked)
                                            }
                                        }
                                    }
                                    Component {
                                        id: number
                                        RowLayout {
                                            spacing: 10
                                            StyledSlider {
                                                Layout.fillWidth: true
                                                from: row.range[0]
                                                to: row.range[1]
                                                stepSize: row.range[2]
                                                value: Number(row.value) || 0
                                                onMoved: root.setValue(row.modelData, Math.round(value * 100) / 100)
                                            }
                                            Controls.Label {
                                                text: Number(row.value).toFixed(row.range[2] < 1 ? 2 : 0)
                                                color: "#cdd6f4"
                                                font.pixelSize: 12
                                                horizontalAlignment: Text.AlignRight
                                                Layout.preferredWidth: 38
                                            }
                                        }
                                    }
                                    Component {
                                        id: colorField
                                        RowLayout {
                                            spacing: 8
                                            Rectangle {
                                                width: 24
                                                height: 24
                                                radius: 12
                                                color: row.value || "#ffffff"
                                                border.width: 1
                                                border.color: "#45475a"
                                                Layout.alignment: Qt.AlignVCenter
                                            }
                                            StyledTextField {
                                                Layout.fillWidth: true
                                                text: String(row.value || "")
                                                placeholderText: "#RRGGBB or #AARRGGBB"
                                                validator: RegularExpressionValidator {
                                                    regularExpression: /^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/
                                                }
                                                onTextEdited: if (acceptableInput)
                                                    root.setValue(row.modelData, text)
                                            }
                                            StyledButton {
                                                text: "Pick"
                                                onClicked: picker.open()
                                            }
                                            ColorDialog {
                                                id: picker
                                                selectedColor: row.value || "#ffffff"
                                                options: ColorDialog.ShowAlphaChannel
                                                onAccepted: root.setValue(row.modelData, selectedColor.toString())
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: root.errorMessage !== ""
            Layout.fillWidth: true
            implicitHeight: errorLabel.implicitHeight + 16
            radius: 14
            color: "#3a2530"
            border.width: 1
            border.color: "#f38ba8"
            Controls.Label {
                id: errorLabel
                anchors.fill: parent
                anchors.margins: 8
                text: root.errorMessage
                color: "#f38ba8"
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            StyledButton {
                objectName: "resetSettings"
                text: "Reset to defaults"
                onClicked: root.reset()
            }
            Item {
                Layout.fillWidth: true
            }
            StyledButton {
                objectName: "closeSettings"
                text: "Close"
                onClicked: root.close()
            }
            StyledButton {
                objectName: "applySettings"
                text: "Apply"
                accent: true
                onClicked: root.apply(root.draft)
            }
        }
    }
}
