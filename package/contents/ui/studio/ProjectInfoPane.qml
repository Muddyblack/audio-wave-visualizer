import QtQuick
import "I18n.js" as I18n
import ".." as Shared
import "Theme.js" as Theme
import "ProjectInfo.js" as Project
import "ProjectInfoRequests.js" as InfoRequests

Column {
    id: info
    required property var studio
    property var counts: ({})
    property var contributorList: []
    property var client: null
    property bool canRefresh: false
    // In Plasma the running package says its own version (metadata.json); the
    // generated module only serves the hosts that have no Plasmoid object.
    readonly property string currentVersion: (typeof Plasmoid !== "undefined" && Plasmoid.metaData && Plasmoid.metaData.version) ? Plasmoid.metaData.version : Project.currentVersion
    property string latestVersion: ""
    property string releaseCheckState: "Not checked"
    readonly property string versionStatus: latestVersion ? Project.releaseStatus(currentVersion, latestVersion) : releaseCheckState

    readonly property bool onlineEnabled: studio.onScreen
    spacing: 16

    function applyNetworkState(state) {
        counts = state.counts;
        contributorList = state.contributors;
        latestVersion = state.latestVersion;
        releaseCheckState = state.releaseState;
        canRefresh = state.canRefresh;
    }

    function cancelRequests() {
        if (client)
            client.pause();
        if (releaseCheckState === "Checking…")
            releaseCheckState = "Could not check for updates";
    }

    onOnlineEnabledChanged: {
        if (client) {
            if (visible && onlineEnabled)
                client.tick();
            else
                cancelRequests();
        }
    }
    onVisibleChanged: {
        if (client) {
            if (visible && onlineEnabled)
                client.tick();
            else
                cancelRequests();
        }
    }
    Component.onCompleted: {
        client = InfoRequests.create(Project, function () {
            return new XMLHttpRequest();
        }, function () {
            return Date.now();
        }, applyNetworkState);
        if (visible && onlineEnabled)
            client.tick();
    }
    Component.onDestruction: {
        if (client)
            client.dispose();
    }

    Timer {
        interval: 1000
        repeat: true
        running: info.visible && info.onlineEnabled && info.client !== null
        onTriggered: info.client.tick()
    }

    Row {
        width: parent.width
        spacing: 14
        Image {
            width: 64
            height: 64
            source: Qt.resolvedUrl("../../../icon.png")
            sourceSize.width: 128
            sourceSize.height: 128
            fillMode: Image.PreserveAspectFit
            Accessible.name: I18n.i18n("Plasma Audio Visualizer project icon")
        }
        Column {
            width: parent.width - 78
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            Text {
                width: parent.width
                text: Project.name
                wrapMode: Text.WordWrap
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
            Row {
                spacing: 7
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: Theme.sunk
                    Text {
                        objectName: "authorAvatarFallback"
                        anchors.centerIn: parent
                        text: "M"
                        color: Theme.brand
                        font.pixelSize: 12
                        visible: !avatar.ready
                    }
                    Shared.SoftwareCover {
                        id: avatar
                        objectName: "authorAvatar"
                        anchors.fill: parent
                        source: info.onlineEnabled ? Project.avatar : ""
                        imageSize: Qt.size(128, 128)
                        radius: 12
                        Accessible.name: I18n.i18n("%1 GitHub avatar", Project.author)
                    }
                }
                StudioButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.i18n("By %1 ↗", Project.author)
                    compact: true
                    onClicked: Qt.openUrlExternally(Project.profile)
                }
            }
        }
    }
    Text {
        width: parent.width
        text: I18n.i18n("An open-source music visualizer for Plasma and Hyprland. Explore the project, get updates, or help improve it.")
        wrapMode: Text.WordWrap
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }
    Rectangle {
        objectName: "projectVersion"
        width: parent.width
        height: versionContent.implicitHeight + 26
        radius: 10
        color: Theme.sunk
        border.color: Theme.line2
        Column {
            id: versionContent
            x: 13
            y: 13
            width: parent.width - 26
            spacing: 8
            Text {
                text: I18n.i18n("Installed version · %1", info.currentVersion)
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
            Text {
                objectName: "latestVersionLabel"
                text: I18n.i18n("Latest stable release · %1", info.latestVersion || "—")
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Text {
                objectName: "versionStatusLabel"
                width: parent.width
                text: I18n.i18n(info.versionStatus)
                wrapMode: Text.WordWrap
                color: info.versionStatus === "Update available" ? Theme.brand : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Flow {
                width: parent.width
                spacing: 8
                StudioButton {
                    text: info.versionStatus === "Update available" ? I18n.i18n("Get update ↗") : I18n.i18n("View latest release ↗")
                    compact: true
                    onClicked: Qt.openUrlExternally(Project.releasesPage)
                }
                StudioButton {
                    text: I18n.i18n("Check again")
                    compact: true
                    enabled: info.onlineEnabled && info.canRefresh
                    onClicked: info.client.refresh()
                }
            }
        }
    }
    Flow {
        width: parent.width
        spacing: 8
        Repeater {
            model: Project.statistics
            Rectangle {
                required property var modelData
                objectName: "stat_" + modelData.id
                width: info.width >= 570 ? (info.width - 16) / 3 : info.width >= 360 ? (info.width - 8) / 2 : info.width
                height: 82
                radius: 10
                color: statArea.containsMouse ? Theme.hover : Theme.sunk
                border.width: 1
                border.color: statArea.containsMouse ? Theme.brand : Theme.line2
                Image {
                    objectName: "statIcon_" + parent.modelData.id
                    x: 12
                    y: 12
                    width: 22
                    height: 22
                    source: Qt.resolvedUrl("icons/" + parent.modelData.icon)
                    sourceSize: Qt.size(44, 44)
                }
                Text {
                    x: 43
                    y: 8
                    text: info.counts[parent.modelData.id] || "—"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 21
                    font.weight: Font.DemiBold
                }
                Text {
                    x: 12
                    y: 48
                    width: parent.width - 30
                    text: I18n.i18n(parent.modelData.label) + " ↗"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: statArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.name: I18n.i18n("%1, open %2", (I18n.i18n(parent.modelData.label)), parent.modelData.href)
                    onClicked: Qt.openUrlExternally(parent.modelData.href)
                }
            }
        }
    }
    Rectangle {
        objectName: "projectLicense"
        width: parent.width
        height: 64
        radius: 10
        color: Theme.sunk
        border.color: Theme.line2
        border.width: 1
        Column {
            x: 13
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Text {
                text: I18n.i18n("License · %1", Project.license)
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
            Text {
                text: Project.licenseId + " · " + I18n.i18n("From the bundled LICENSE file")
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
    }
    Column {
        objectName: "contributorsSection"
        width: parent.width
        visible: info.contributorList.length > 0
        spacing: 8
        Row {
            width: parent.width
            spacing: 10
            Text {
                text: I18n.i18n("Contributors")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            StudioButton {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.i18n("See all on GitHub ↗")
                compact: true
                onClicked: Qt.openUrlExternally(Project.contributorsPage)
            }
        }
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: info.contributorList
                Rectangle {
                    id: contributorCard
                    required property var modelData
                    objectName: "contributor_" + modelData.login
                    width: info.width >= 570 ? (info.width - 16) / 3 : info.width >= 360 ? (info.width - 8) / 2 : info.width
                    height: 58
                    radius: 10
                    color: contributorArea.containsMouse ? Theme.hover : Theme.sunk
                    border.color: contributorArea.containsMouse ? Theme.brand : Theme.line2
                    border.width: 1
                    Rectangle {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34
                        height: 34
                        radius: 17
                        color: Theme.panelTop
                        Text {
                            anchors.centerIn: parent
                            text: contributorCard.modelData.login[0].toUpperCase()
                            color: Theme.brand
                            font.pixelSize: 13
                            visible: !contributorAvatar.ready
                        }
                        Shared.SoftwareCover {
                            id: contributorAvatar
                            anchors.fill: parent
                            source: info.onlineEnabled ? contributorCard.modelData.avatar : ""
                            imageSize: Qt.size(96, 96)
                            radius: 17
                            Accessible.name: I18n.i18n("%1 avatar", contributorCard.modelData.login)
                        }
                    }
                    Column {
                        x: 52
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 62
                        spacing: 2
                        Text {
                            width: parent.width
                            text: contributorCard.modelData.login
                            elide: Text.ElideRight
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: contributorCard.modelData.commits === 1 ? I18n.i18n("1 commit") : I18n.i18n("%1 commits", contributorCard.modelData.commits)
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }
                    MouseArea {
                        id: contributorArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.name: I18n.i18n("Open %1 on GitHub", contributorCard.modelData.login)
                        onClicked: Qt.openUrlExternally(contributorCard.modelData.profile)
                    }
                }
            }
        }
    }
    Column {
        width: parent.width
        spacing: 8
        Text {
            text: I18n.i18n("Support the project")
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: Project.funding
                Rectangle {
                    required property var modelData
                    objectName: "funding_" + modelData.id
                    width: info.width >= 570 ? (info.width - 16) / 3 : info.width >= 360 ? (info.width - 8) / 2 : info.width
                    height: 64
                    radius: 10
                    color: linkArea.containsMouse ? Theme.hover : Theme.sunk
                    border.width: 1
                    border.color: linkArea.containsMouse ? Theme.brand : Theme.line2
                    Image {
                        objectName: "fundingIcon_" + parent.modelData.id
                        x: 13
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        height: 26
                        source: Qt.resolvedUrl("icons/" + parent.modelData.icon)
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(52, 52)
                    }
                    Text {
                        x: 49
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 67
                        text: parent.modelData.label
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: linkArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.name: I18n.i18n("Support on %1", parent.modelData.label)
                        onClicked: Qt.openUrlExternally(parent.modelData.url)
                    }
                }
            }
        }
    }
    Flow {
        width: parent.width
        spacing: 8
        StudioButton {
            text: I18n.i18n("View source on GitHub ↗")
            compact: true
            onClicked: Qt.openUrlExternally(Project.repository)
        }
        StudioButton {
            text: I18n.i18n("Report an issue ↗")
            compact: true
            onClicked: Qt.openUrlExternally(Project.repository + "/issues")
        }
    }
}
