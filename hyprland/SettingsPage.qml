pragma ComponentBehavior: Bound
import QtQuick
import "../package/contents/ui/studio" as Studio
import "../package/contents/ui/studio/Theme.js" as Theme
import "../package/contents/ui/text"
import "../package/contents/ui/studio/Schema.js" as Schema

// Hyprland and Windows settings window: the shared studio over a draft, with
// Defaults and Reset at the left, like System Settings, and Close and Apply at
// the right. Apply saves local overrides.
Rectangle {
    id: root
    color: Theme.bg
    property var draft: ({})
    property var savedDraft: ({})
    property var defaults: ({})
    property var screenNames: []
    property string errorMessage: ""
    property alias currentTabIndex: studio.currentTabIndex
    // function(done(text)) running doctor.sh; supplied by the shell.
    property var diagnosticsRunner: null
    property Component commandSourceComponent: null
    property var liveVisualizer: null
    property var livePlayer: null
    property bool liveIsPlaying: false
    signal apply(var draft)
    signal close
    // With Apply instantly on, every change is saved once the edits settle, so
    // Reset returns to how the window opened instead of to the last save.
    property var openDraft: ({})
    readonly property bool liveApply: draft.liveApply !== false
    readonly property var resetPoint: liveApply ? openDraft : savedDraft
    readonly property bool pending: differs(draft, savedDraft)
    readonly property bool canDiscard: differs(draft, resetPoint)
    onDraftChanged: if (Object.keys(openDraft).length === 0)
        openDraft = draft

    function differs(a, b) {
        return Object.keys(a).some(k => JSON.stringify(a[k]) !== JSON.stringify(b[k]));
    }
    function settle() {
        openDraft = Schema.preservePreferences(Object.assign({}, openDraft), draft);
        const next = Schema.preservePreferences(Object.assign({}, liveApply ? draft : savedDraft), draft);
        if (differs(next, savedDraft))
            apply(next);
    }

    // Saves what instant apply has not reached yet; anything else unsaved asks first.
    function requestClose() {
        settle();
        if (liveApply || !pending)
            close();
        else
            closePrompt.visible = true;
    }

    function setValue(key, value) {
        draft = Object.assign({}, draft, {
            [key]: value
        });
    }

    Studio.Studio {
        id: studio
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: footer.top
        commandSourceComponent: root.commandSourceComponent
        liveVisualizer: root.liveVisualizer
        livePlayer: root.livePlayer
        liveIsPlaying: root.liveIsPlaying
        livePositionUnitsPerSecond: 1
        env: "hypr"
        draft: root.draft
        defaults: Object.keys(root.defaults).length ? root.defaults : root.draft
        screenNames: root.screenNames
        diagnosticsRunner: root.diagnosticsRunner
        previewAccent: root.draft.waveColor ?? "#b4befe"
        canDiscard: root.canDiscard
        onEdited: next => root.draft = next
        onDraftSettled: root.settle()
    }

    Rectangle {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 60
        color: Theme.panel
        Rectangle {
            width: parent.width
            height: 1
            color: Theme.line
        }
        Row {
            id: leftButtons
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Studio.StudioButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: "M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8 M3 3v5h5"
                text: I18n.i18n("Defaults")
                tooltip: I18n.i18n("Restore every setting to its default. Apply to keep it; Reset undoes it. Saved presets are kept.")
                areaName: "resetToDefaults"
                onClicked: root.draft = Schema.restoreDefaults(studio.defaults, root.draft)
            }
            Studio.StudioButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: "M3 7v6h6 M3 13a9 9 0 1 0 3-7.7L3 8"
                text: I18n.i18nc("undo the changes that are not applied yet", "Reset")
                tooltip: I18n.i18n("Discard unapplied changes")
                enabled: root.canDiscard
                areaName: "discardSettings"
                onClicked: root.draft = Object.assign({}, root.resetPoint)
            }
        }
        Text {
            anchors.left: leftButtons.right
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, liveSwitch.x - x - 16)
            text: root.errorMessage
            color: "#ff8a8a"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            elide: Text.ElideRight
        }
        Row {
            id: liveSwitch
            objectName: "liveApplySwitch"
            anchors.right: buttons.left
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Studio.StudioSwitch {
                anchors.verticalCenter: parent.verticalCenter
                checked: root.liveApply
                onToggled: on => root.setValue("liveApply", on)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.i18n("Apply instantly")
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }
        Row {
            id: buttons
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Studio.StudioButton {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.i18n("Close")
                areaName: "closeSettings"
                onClicked: root.requestClose()
            }
            Studio.StudioButton {
                anchors.verticalCenter: parent.verticalCenter
                primary: true
                enabled: root.pending
                text: I18n.i18n("Apply")
                areaName: "applySettings"
                onClicked: root.apply(root.draft)
            }
        }
    }

    Rectangle {
        id: closePrompt
        objectName: "closePrompt"
        anchors.fill: parent
        visible: false
        color: "#99000000"
        MouseArea {
            anchors.fill: parent
        }
        Rectangle {
            anchors.centerIn: parent
            width: Math.max(promptText.implicitWidth, promptButtons.implicitWidth) + 40
            height: promptText.implicitHeight + promptButtons.implicitHeight + 56
            radius: 10
            color: Theme.panel
            border.color: Theme.line2
            Text {
                id: promptText
                x: 20
                y: 20
                text: I18n.i18n("The current page has unsaved changes. Apply the changes or discard them?")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Row {
                id: promptButtons
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                spacing: 8
                Studio.StudioButton {
                    anchors.verticalCenter: parent.verticalCenter
                    primary: true
                    text: I18n.i18n("Apply")
                    areaName: "promptApply"
                    onClicked: {
                        closePrompt.visible = false;
                        root.apply(root.draft);
                        root.close();
                    }
                }
                Studio.StudioButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.i18n("Discard")
                    areaName: "promptDiscard"
                    onClicked: {
                        closePrompt.visible = false;
                        root.close();
                    }
                }
                Studio.StudioButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.i18n("Cancel")
                    areaName: "promptCancel"
                    onClicked: closePrompt.visible = false
                }
            }
        }
    }
}
