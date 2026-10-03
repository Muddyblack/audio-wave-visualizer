import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls
import "../code/TrackInfo.js" as TrackInfo

Item {
    id: root
    required property var view
    property string mode: "tooltip"
    readonly property bool back: mode === "back"
    readonly property bool drawer: mode === "drawer"
    readonly property bool artwork: mode === "artwork"
    readonly property color foreground: back ? view.textColor : "#f1f4f8"
    readonly property color muted: back ? Qt.rgba(foreground.r, foreground.g, foreground.b, .75) : "#bac4d2"
    function fieldList() {
        const fields = view.configuration?.detailFields ?? "album,genre,format,player";
        return (Array.isArray(fields) ? fields : String(fields).split(",")).map(field => String(field).trim()).filter(Boolean);
    }
    property string selectedRecordingId: ""
    onInfoPayloadChanged: {
        selectedRecordingId = "";
        if (scroll.contentItem)
            scroll.contentItem.contentY = 0;
    }
    readonly property var infoPayload: TrackInfo.payload(root.view)
    MediaLookup {
        id: lookup
        objectName: root.artwork ? "artistInfoLookup" : "trackDetailsLookup"
        mode: "info"
        active: root.visible && root.view.visible && root.view.shouldShow && (root.artwork ? !!root.view.zoomOpen : root.back ? !!root.view.flipped : !!root.view.detailsVisible) && (root.view.configuration?.onlineTrackInfo ?? false) && !root.view.samplePlayback && (!!payload.artist || !!payload.track)
        payload: Object.assign({}, root.infoPayload, {
            recordingId: root.selectedRecordingId
        })
        commandSourceComponent: root.view.visualizer?.commandSourceComponent ?? null
    }
    function linkAttribute(url) {
        return String(url).replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;");
    }
    function metadataText(key) {
        const value = (view.metadata ?? {})[key];
        return Array.isArray(value) ? value.join(", ") : String(value ?? "");
    }
    function detail(label, value) {
        return value ? [label, value] : null;
    }
    readonly property string detailAlbum: infoPayload.album || lookup.result.album || ""
    readonly property string detailArtist: infoPayload.artist || lookup.result.matchedArtist || ""
    readonly property string detailYear: view.year || lookup.result.year || ""
    readonly property bool showSummary: fieldList().indexOf("summary") >= 0 && !!lookup.result.summary
    // Rows without advertised data are left out.
    function rowFor(key) {
        switch (key) {
        case "albumArtist":
            return detail(qsTr("Album artist"), metadataText("xesam:albumArtist"));
        case "composer":
            return detail(qsTr("Composer"), metadataText("xesam:composer") || lookup.result.composer || "");
        case "lyricist":
            return detail(qsTr("Lyricist"), metadataText("xesam:lyricist") || lookup.result.lyricist || "");
        case "writers":
            return detail(qsTr("Writers"), lookup.result.writers || "");
        case "producers":
            return detail(qsTr("Producers"), lookup.result.producers || "");
        case "performers":
            return detail(qsTr("Performers"), lookup.result.performers || "");
        case "arrangers":
            return detail(qsTr("Arrangers"), lookup.result.arrangers || "");
        case "label":
            return detail(qsTr("Label"), lookup.result.label || "");
        case "country":
            return detail(qsTr("Country"), lookup.result.country || "");
        case "editionDate":
            return detail(qsTr("Edition date"), lookup.result.editionDate || "");
        case "recordingNote":
            return detail(qsTr("Version"), lookup.result.recordingNote || "");
        case "isrc":
            return detail(qsTr("ISRC"), lookup.result.isrc || "");
        case "trackCount":
            return detail(qsTr("Album tracks"), lookup.result.trackCount ? String(lookup.result.trackCount) : "");
        case "disc":
            return detail(qsTr("Disc"), Number(metadataText("xesam:discNumber")) > 0 ? metadataText("xesam:discNumber") : lookup.result.discNumber ? String(lookup.result.discNumber) : "");
        case "bpm":
            return detail(qsTr("BPM"), Number(metadataText("xesam:audioBPM")) > 0 ? metadataText("xesam:audioBPM") : "");
        case "comment":
            return detail(qsTr("Comment"), metadataText("xesam:comment"));
        case "date":
            return detail(qsTr("Released"), metadataText("xesam:contentCreated").slice(0, 10) || lookup.result.releaseDate || "");
        case "releaseType":
            return detail(qsTr("Type"), lookup.result.releaseType || "");
        case "format":
            return (view.formatBadges ?? []).length ? [qsTr("Format"), view.formatBadges.join(" · ")] : null;
        case "album":
            return detailAlbum !== "" ? [qsTr("Album"), detailAlbum + (detailYear !== "" ? " (" + detailYear + ")" : "")] : null;
        case "track":
            return view.trackNumber > 0 ? [qsTr("Track"), String(view.trackNumber)] : lookup.result.trackNumber ? [qsTr("Track"), String(lookup.result.trackNumber)] : null;
        case "genre":
            return detail(qsTr("Genre"), view.genre || (lookup.result.genres ?? []).join(", "));
        case "length":
            return !!view.lengthText ? [qsTr("Length"), view.lengthText] : null;
        case "player":
            return !!view.sourceName ? [qsTr("Source"), view.sourceName] : null;
        default:
            return null;
        }
    }
    readonly property var rows: fieldList().map(rowFor).filter(Boolean)
    readonly property var sections: [
        {
            title: qsTr("Song"),
            keys: ["genre", "length", "bpm", "recordingNote", "comment"]
        },
        {
            title: qsTr("Credits"),
            keys: ["albumArtist", "composer", "lyricist", "writers", "producers", "performers", "arrangers"]
        },
        {
            title: qsTr("Release"),
            keys: ["album", "date", "releaseType", "track", "disc", "trackCount", "label", "country", "editionDate", "isrc"]
        },
        {
            title: qsTr("Playback"),
            keys: ["format", "player"]
        }
    ].map(section => ({
                title: section.title,
                rows: section.keys.filter(key => fieldList().indexOf(key) >= 0).map(rowFor).filter(Boolean)
            })).filter(section => section.rows.length)
    readonly property string notice: TrackInfo.notice(lookup.status, lookup.result)
    readonly property bool showLyric: (view.configuration?.showLyrics ?? false) && !!view.lyricDisplayLine
    implicitWidth: drawer ? 380 : 310
    implicitHeight: artwork ? content.implicitHeight + 24 : Math.min(mode === "tooltip" ? 300 : 480, content.implicitHeight + 28)

    Rectangle {
        anchors.fill: parent
        objectName: "trackInfoBackground"
        visible: !root.artwork && !root.back
        color: "#f5141a24"
        radius: root.back ? Math.max(0, root.view.configuration?.bgRadius ?? 14) : 14
        border.color: "#30ffffff"
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: 32
            height: 3
            radius: 2
            color: "#8293ac"
            visible: root.drawer
        }
    }
    HoverHandler {
        enabled: !root.back && !root.artwork
        onHoveredChanged: if (root.view.detailsHovered !== undefined)
            root.view.detailsHovered = hovered
    }
    Component.onDestruction: if (!back && !artwork && view.detailsHovered !== undefined)
        view.detailsHovered = false

    Controls.ScrollView {
        id: scroll
        objectName: "trackInfoScroll"
        anchors.fill: parent
        anchors.margins: root.back ? 10 : 14
        anchors.rightMargin: root.back ? 30 : 14
        clip: true
        contentWidth: availableWidth
        contentHeight: content.implicitHeight
        Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff
        Controls.ScrollBar.vertical.policy: contentHeight > availableHeight ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff
        ColumnLayout {
            id: content
            width: scroll.availableWidth
            spacing: root.back ? 8 : 12
            RowLayout {
                visible: !root.artwork
                Layout.fillWidth: true
                spacing: 10
                ArtView {
                    Layout.preferredWidth: root.back ? 32 : 44
                    Layout.preferredHeight: Layout.preferredWidth
                    view: root.artwork ? null : root.view
                    flipHoverEnabled: false
                    artUrl: root.view.artUrl
                    desktopEntry: root.view.desktopEntry
                    fallbackIcon: root.view.fallbackIcon
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        Layout.fillWidth: true
                        text: root.view.displayTrack
                        textFormat: Text.PlainText
                        color: root.foreground
                        font.pixelSize: root.back ? 12 : 14
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !!text
                        text: root.detailArtist
                        textFormat: Text.PlainText
                        color: root.muted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
            }
            ColumnLayout {
                objectName: "detailRows"
                Layout.fillWidth: true
                spacing: 12
                Repeater {
                    model: root.sections
                    ColumnLayout {
                        id: section
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 5
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: section.modelData.title.toUpperCase()
                                color: root.muted
                                font.pixelSize: 9
                                font.letterSpacing: 1
                                font.bold: true
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, .15)
                            }
                        }
                        Repeater {
                            model: section.modelData.rows
                            RowLayout {
                                id: row
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 10
                                Text {
                                    Layout.preferredWidth: Math.min(78, scroll.availableWidth * .32)
                                    Layout.alignment: Qt.AlignTop
                                    text: row.modelData[0]
                                    textFormat: Text.PlainText
                                    wrapMode: Text.Wrap
                                    color: root.muted
                                    font.pixelSize: 11
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData[1]
                                    textFormat: Text.PlainText
                                    color: root.foreground
                                    font.pixelSize: 11
                                    wrapMode: Text.Wrap
                                    maximumLineCount: root.mode === "tooltip" ? 2 : 20
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                visible: root.showSummary
                text: lookup.result.summary || ""
                textFormat: Text.PlainText
                color: root.muted
                font.pixelSize: 11
                wrapMode: Text.Wrap
                maximumLineCount: root.mode === "tooltip" ? 3 : 100
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: root.showLyric
                text: root.view.lyricDisplayLine || ""
                textFormat: Text.PlainText
                color: root.foreground
                font.italic: true
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }
            Text {
                Layout.fillWidth: true
                visible: !!root.notice
                text: root.notice
                textFormat: Text.PlainText
                color: root.muted
                font.pixelSize: 10
                wrapMode: Text.Wrap
            }
            Controls.ComboBox {
                Layout.fillWidth: true
                visible: model.length > 0
                model: lookup.result.candidates || []
                textRole: "label"
                currentIndex: -1
                displayText: qsTr("Choose a recording…")
                onActivated: index => root.selectedRecordingId = model[index].id
            }
            Controls.Button {
                visible: lookup.status === "error" || !!lookup.result.partial
                text: qsTr("Retry lookup")
                onClicked: lookup.reset()
            }
            Text {
                Layout.fillWidth: true
                visible: !!text
                text: [lookup.result.recordingUrl ? '<a href="' + root.linkAttribute(lookup.result.recordingUrl) + '">Recording · MusicBrainz</a>' : '', lookup.result.albumUrl ? '<a href="' + root.linkAttribute(lookup.result.albumUrl) + '">Album · MusicBrainz</a>' : '', lookup.result.catalogUrl ? '<a href="' + root.linkAttribute(lookup.result.catalogUrl) + '">Apple Music</a>' : '', root.showSummary && lookup.result.artistUrl ? '<a href="' + root.linkAttribute(lookup.result.artistUrl) + '">Wikipedia · CC BY-SA</a>' : ''].filter(Boolean).join("  ·  ")
                textFormat: Text.RichText
                linkColor: root.back ? root.view.waveColor : "#b7d5ff"
                font.pixelSize: 10
                wrapMode: Text.Wrap
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
        }
    }
}
