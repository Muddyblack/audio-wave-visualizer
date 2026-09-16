import QtQuick
import QtQuick.LocalStorage
import "../code/Lyrics.js" as Lyrics

// Opt-in lyrics: local sidecars / ID3 first, then LRCLIB. The owner creates
// this only for an enabled lyrics display. Online results,
// including misses, are cached on disk with LocalStorage; misses are retried
// after a day. Transport failures use a Python HTTPS fallback and bounded retries.
Item {
    id: root
    property Component commandSourceComponent: null
    property string fileUrl: ""
    property string language: "auto"
    property bool karaokeActive: false
    property bool synced: true
    property string localWarning: ""
    property string _command: ""
    property string _commandKey: ""
    property string _commandMode: ""
    property int _generation: 0
    property var _secondary: ({})
    property var player: null
    property bool isPlaying: false
    property string track: ""
    property string artist: ""
    property string album: ""
    property real positionUnitsPerSecond: 0
    property real visualFrameTime: 0
    property real timingOffset: 0
    property var lines: []
    property string status: "idle"
    property int _retryCount: 0
    property var _request: null
    function cancelRequest() {
        localTimeout.stop();
        networkTimeout.stop();
        retry.stop();
        if (_command) {
            const command = _command;
            _command = "";
            localReader.cancelSource(command);
            localReader.disconnectSource(command);
        }
        if (!_request)
            return;
        const request = _request;
        _request = null;
        request.onreadystatechange = function () {};
        request.abort();
    }
    Component.onDestruction: cancelRequest()

    readonly property int durationSeconds: clock.lengthValue > 0 ? Math.round(clock.lengthValue / clock.unitsPerSecond) : 0
    readonly property string onlineKey: track !== "" && artist !== "" ? [track, artist, album, durationSeconds].join("") : ""
    readonly property string requestKey: onlineKey === "" && fileUrl === "" ? "" : [onlineKey, fileUrl, language].join("\u001e")
    readonly property real positionSeconds: clock.displayedPosition / clock.unitsPerSecond + Math.max(-10, Math.min(10, timingOffset))
    readonly property int currentIndex: {
        if (!synced)
            return -1;
        const seconds = positionSeconds;
        let index = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].time > seconds)
                break;
            index = i;
        }
        return index;
    }
    readonly property string currentLine: currentIndex >= 0 ? lines[currentIndex].text : ""

    PlaybackClock {
        id: clock
        objectName: "lyricsClock"
        unitScale: root.positionUnitsPerSecond
        updateInterval: root.karaokeActive && root.lines.some(line => line.words && line.words.length) ? 33 : 1000
        player: root.player
        playing: root.isPlaying
        track: root.requestKey
        active: root.synced && root.lines.length > 0
    }
    onVisualFrameTimeChanged: {
        if (clock.active && isPlaying)
            clock.tick();
    }

    // Metadata often arrives in several updates; request once it settles.
    Timer {
        id: settle
        interval: 400
        onTriggered: root.load()
    }
    onRequestKeyChanged: {
        cancelRequest();
        _retryCount = 0;
        lines = [];
        status = onlineKey === "" && fileUrl === "" ? "idle" : "loading";
        synced = true;
        _secondary = ({});
        localWarning = "";
        settle.restart();
    }

    function parse(text) {
        return Lyrics.parse(text);
    }

    function quote(text) {
        return "'" + String(text).replace(/'/g, "'\\''") + "'";
    }

    function runHelper(argument, mode) {
        if (!localReader.item)
            return false;
        const script = decodeURIComponent(Qt.resolvedUrl("../code/local_lyrics.sh").toString().replace(/^file:\/\//, ""));
        _commandKey = requestKey;
        _commandMode = mode;
        // The generation also distinguishes repeated visits to the same song.
        _command = "bash " + quote(script) + " " + argument + " " + quote(language) + " # " + (++_generation);
        localReader.connectSource(_command);
        localTimeout.restart();
        return true;
    }

    function decorate(values, secondary) {
        for (const field of ["translation", "romanized", "reading"])
            Lyrics.attach(values, secondary[field] || "", field);
        return values;
    }

    function acceptSynced(text, convert) {
        synced = true;
        lines = decorate(parse(text), _secondary);
        status = lines.length ? "ready" : "missing";
        // Bound the shell argument; a missing optional converter never hides lyrics.
        if (convert && lines.length && text.length < 24000 && (language !== "auto" || /[\u3040-\u30ff]/.test(text)))
            runHelper("--readings " + quote(text), "readings");
    }

    CommandSource {
        id: localReader
        objectName: "lyricsLocalReader"
        sourceComponent: root.commandSourceComponent
        onNewData: function (source, data) {
            if (source !== root._command || root._commandKey !== root.requestKey)
                return;
            const mode = root._commandMode;
            root._command = "";
            localTimeout.stop();
            disconnectSource(source);
            let value = ({});
            try {
                value = JSON.parse(data["stdout"] || "{}");
            } catch (error) {}
            if (mode === "online") {
                root.finishOnline(value.status || 0, value.body || {});
                return;
            }
            root.localWarning = value.warning || "";
            if (mode === "readings") {
                root.lines = root.decorate(root.lines.slice(), Object.assign({}, value, root._secondary));
                return;
            }
            root._secondary = value;
            if (value.synced && root.parse(value.synced).length) {
                root.acceptSynced(value.synced, false);
            } else if (value.plain) {
                root.synced = false;
                const romanized = String(value.romanized || "").split("\n");
                const reading = String(value.reading || "").split("\n");
                root.lines = value.plain.split(/\r?\n/).map((text, i) => ({
                            text: text,
                            time: 0,
                            words: [],
                            romanized: romanized[i] || "",
                            reading: reading[i] || ""
                        }));
                root.status = "ready";
            } else {
                root.loadOnline();
            }
        }
    }

    Timer {
        id: localTimeout
        interval: root._commandMode === "online" ? 15000 : 5000
        onTriggered: {
            const mode = root._commandMode;
            root.cancelRequest();
            if (mode === "local")
                root.loadOnline();
            else if (mode === "online")
                root.onlineFailed();
        }
    }

    function load() {
        settle.stop();
        cancelRequest();
        if (fileUrl.startsWith("file:") && runHelper(quote(fileUrl), "local"))
            return;
        loadOnline();
    }

    function database() {
        return LocalStorage.openDatabaseSync("PlasmaAudioVisualizerLyrics", "1", "Synced lyrics cache", 2000000);
    }

    function loadOnline() {
        const key = onlineKey;
        const generationKey = requestKey;
        if (key === "") {
            status = fileUrl === "" ? "idle" : "missing";
            return;
        }
        let cached = null;
        try {
            database().transaction(tx => {
                tx.executeSql("CREATE TABLE IF NOT EXISTS lyrics_v2(key TEXT PRIMARY KEY, synced TEXT, plain TEXT, fetched INTEGER)");
                // Preserve previously downloaded lyrics, but retry old misses:
                // the old cache also recorded plain-only and malformed replies as misses.
                tx.executeSql("CREATE TABLE IF NOT EXISTS lyrics(key TEXT PRIMARY KEY, synced TEXT, fetched INTEGER)");
                tx.executeSql("INSERT OR IGNORE INTO lyrics_v2 SELECT key, synced, '', fetched FROM lyrics WHERE synced != ''");
                const result = tx.executeSql("SELECT synced, plain, fetched FROM lyrics_v2 WHERE key = ?", [key]);
                if (result.rows.length)
                    cached = result.rows.item(0);
            });
        } catch (error) {
            cached = null;
        }
        if (cached && (cached.synced !== "" || cached.plain !== "" || Date.now() - cached.fetched < 86400000)) {
            acceptOnline(cached.synced, cached.plain);
            return;
        }
        status = "loading";
        const request = createRequest();
        _request = request;
        request.open("GET", "https://lrclib.net/api/get?" + onlineQuery());
        request.setRequestHeader("Lrclib-Client", "plasma-audio-visualizer (https://github.com/Muddyblack/audio-wave-visualizer)");
        request.onreadystatechange = () => {
            if (!root || request.readyState !== XMLHttpRequest.DONE || request !== root._request || generationKey !== root.requestKey)
                return;
            networkTimeout.stop();
            root._request = null;
            request.onreadystatechange = function () {};
            if (request.status === 0) {
                root.fallbackOnline();
                return;
            }
            let value = ({});
            if (request.status === 200) {
                try {
                    value = JSON.parse(request.responseText);
                } catch (error) {
                    root.onlineFailed();
                    return;
                }
            }
            root.finishOnline(request.status, value);
        };
        networkTimeout.restart();
        request.send();
    }

    function createRequest() {
        return new XMLHttpRequest();
    }

    function onlineQuery() {
        return "track_name=" + encodeURIComponent(track) + "&artist_name=" + encodeURIComponent(artist) + (album !== "" ? "&album_name=" + encodeURIComponent(album) : "") + (durationSeconds > 0 ? "&duration=" + durationSeconds : "");
    }

    function fallbackOnline() {
        if (!runHelper("--online " + quote(onlineQuery()), "online"))
            onlineFailed();
    }

    function onlineFailed() {
        status = "error";
        if (_retryCount < 2) {
            ++_retryCount;
            retry.restart();
        }
    }

    function acceptOnline(syncedText, plainText) {
        if (syncedText && parse(syncedText).length) {
            acceptSynced(syncedText, true);
        } else if (plainText) {
            synced = false;
            lines = plainText.split(/\r?\n/).map(text => ({
                        text: text,
                        time: 0,
                        words: []
                    }));
            status = "ready";
        } else {
            acceptSynced("", false);
        }
    }

    function finishOnline(code, value) {
        if (code !== 200 && code !== 404) {
            onlineFailed();
            return;
        }
        if (code === 200 && (!value || typeof value !== "object" || Array.isArray(value) || !("syncedLyrics" in value || "plainLyrics" in value || value.instrumental === true))) {
            onlineFailed();
            return;
        }
        const syncedText = code === 200 && typeof value.syncedLyrics === "string" ? value.syncedLyrics : "";
        const plainText = code === 200 && typeof value.plainLyrics === "string" ? value.plainLyrics : "";
        try {
            database().transaction(tx => tx.executeSql("INSERT OR REPLACE INTO lyrics_v2 VALUES (?, ?, ?, ?)", [onlineKey, syncedText, plainText, Date.now()]));
        } catch (error) {}
        acceptOnline(syncedText, plainText);
    }

    Timer {
        id: networkTimeout
        objectName: "lyricsNetworkTimeout"
        interval: 15000
        onTriggered: {
            root.cancelRequest();
            root.fallbackOnline();
        }
    }

    Timer {
        id: retry
        objectName: "lyricsRetry"
        interval: 3000 * root._retryCount
        onTriggered: root.loadOnline()
    }
}
