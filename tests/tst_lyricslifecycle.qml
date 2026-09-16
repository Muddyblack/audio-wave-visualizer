import QtQuick
import QtQuick.LocalStorage
import QtTest
import "../package/contents/ui" as Shared

TestCase {
    name: "LyricsLifecycle"
    Component {
        id: source
        Shared.LyricsSource {}
    }
    function request() {
        return {
            aborted: false,
            onreadystatechange: function () {},
            abort: function () {
                this.aborted = true;
            }
        };
    }
    Component {
        id: playerComponent
        QtObject {
            property real length: 180
            property real position: 0
        }
    }
    Component {
        id: commandComponent
        QtObject {
            property var connectedSources: []
            signal newData(string source, var data)
            function connectSource(source) {
                connectedSources = [source];
            }
            function disconnectSource(source) {
                connectedSources = connectedSources.filter(s => s !== source);
            }
        }
    }
    Component {
        id: onlineSource
        Shared.LyricsSource {
            property var requests: []
            property var testDatabase: null
            function database() {
                if (testDatabase)
                    return testDatabase;
                throw new Error("No persistent cache in network tests");
            }
            function createRequest() {
                const result = {
                    readyState: 0,
                    status: 0,
                    responseText: "",
                    aborted: false,
                    onreadystatechange: function () {},
                    open: function () {},
                    setRequestHeader: function () {},
                    send: function () {},
                    abort: function () {
                        this.aborted = true;
                    }
                };
                requests.push(result);
                return result;
            }
        }
    }

    function complete(request, status, body) {
        request.status = status;
        request.responseText = body;
        request.readyState = XMLHttpRequest.DONE;
        request.onreadystatechange();
    }

    function test_cacheMigrationAndPlainRoundTrip() {
        const lyrics = createTemporaryObject(onlineSource, this, {
            track: "Song",
            artist: "Artist"
        });
        const db = LocalStorage.openDatabaseSync("LyricsTest-" + Date.now() + "-" + Math.random(), "1", "Test", 100000);
        lyrics.testDatabase = db;
        db.transaction(tx => {
            tx.executeSql("CREATE TABLE lyrics(key TEXT PRIMARY KEY, synced TEXT, fetched INTEGER)");
            tx.executeSql("INSERT INTO lyrics VALUES (?, ?, ?)", [lyrics.onlineKey, "[00:01]Cached", Date.now()]);
        });
        lyrics.load();
        compare(lyrics.lines[0].text, "Cached");
        compare(lyrics.requests.length, 0);
        lyrics.track = "Plain";
        lyrics.load();
        complete(lyrics.requests[0], 200, JSON.stringify({
            plainLyrics: "Plain lyrics"
        }));
        lyrics.lines = [];
        lyrics.load();
        compare(lyrics.lines[0].text, "Plain lyrics");
        compare(lyrics.synced, false);
        compare(lyrics.requests.length, 1);
        lyrics.track = "Broken";
        lyrics.load();
        complete(lyrics.requests[1], 200, "{}");
        compare(lyrics.status, "error");
        db.transaction(tx => {
            compare(tx.executeSql("SELECT * FROM lyrics_v2 WHERE key = ?", [lyrics.onlineKey]).rows.length, 0);
            tx.executeSql("DROP TABLE lyrics_v2");
            tx.executeSql("DROP TABLE lyrics");
        });
    }

    function test_httpsFallbackAndStaleCompletion() {
        const lyrics = createTemporaryObject(onlineSource, this, {
            track: "Song",
            artist: "Artist",
            commandSourceComponent: commandComponent
        });
        lyrics.load();
        complete(lyrics.requests[0], 0, "");
        verify(lyrics._command.indexOf("--online") >= 0);
        const reader = findChild(lyrics, "lyricsLocalReader");
        const command = lyrics._command;
        reader.item.newData(command, {
            stdout: JSON.stringify({
                status: 200,
                body: {
                    syncedLyrics: "[00:01]Recovered"
                }
            })
        });
        compare(lyrics.status, "ready");
        compare(lyrics.lines[0].text, "Recovered");
        lyrics.track = "Other";
        reader.item.newData(command, {
            stdout: JSON.stringify({
                status: 200,
                body: {
                    syncedLyrics: "[00:01]Stale"
                }
            })
        });
        compare(lyrics.lines.length, 0);
    }

    function test_plainOnlineAndRetry() {
        const lyrics = createTemporaryObject(onlineSource, this, {
            track: "Song",
            artist: "Artist"
        });
        lyrics.load();
        complete(lyrics.requests[0], 503, "");
        compare(lyrics.status, "error");
        const retry = findChild(lyrics, "lyricsRetry");
        verify(retry.running);
        retry.stop();
        retry.triggered();
        complete(lyrics.requests[1], 200, JSON.stringify({
            plainLyrics: "First\nSecond"
        }));
        compare(lyrics.status, "ready");
        compare(lyrics.synced, false);
        compare(lyrics.currentIndex, -1);
        compare(lyrics.lines.length, 2);
        lyrics.load();
        complete(lyrics.requests[2], 200, "broken JSON");
        compare(lyrics.status, "error");
        verify(retry.running);
        lyrics.track = "Changed";
        verify(!retry.running);
        compare(lyrics._retryCount, 0);
    }

    function test_networkTimeoutAndRetryLimit() {
        const lyrics = createTemporaryObject(onlineSource, this, {
            track: "Song",
            artist: "Artist"
        });
        lyrics.load();
        const timeout = findChild(lyrics, "lyricsNetworkTimeout");
        verify(timeout.running);
        timeout.triggered();
        verify(lyrics.requests[0].aborted);
        compare(lyrics.status, "error");
        const retry = findChild(lyrics, "lyricsRetry");
        for (let i = 0; i < 2; ++i) {
            verify(retry.running);
            retry.stop();
            retry.triggered();
            complete(lyrics.requests[i + 1], 500, "");
        }
        verify(!retry.running);
        lyrics.load();
        complete(lyrics.requests[3], 404, "");
        compare(lyrics.status, "missing");
        verify(!retry.running);
    }

    function test_localLookupAndStaleResult() {
        const lyrics = createTemporaryObject(source, this, {
            commandSourceComponent: commandComponent,
            fileUrl: "file:///tmp/song.mp3"
        });
        wait(10);
        lyrics.load();
        const command = lyrics._command;
        verify(command.indexOf("local_lyrics.sh") >= 0);
        const reader = findChild(lyrics, "lyricsLocalReader");
        reader.item.newData(command, {
            stdout: JSON.stringify({
                synced: "[00:01]Local",
                translation: "[00:01]Translation"
            })
        });
        compare(lyrics.status, "ready");
        compare(lyrics.lines[0].translation, "Translation");
        lyrics.fileUrl = "file:///tmp/other.mp3";
        reader.item.newData(command, {
            stdout: JSON.stringify({
                synced: "[00:01]Stale"
            })
        });
        compare(lyrics.lines.length, 0);
        lyrics.load();
        reader.item.newData(lyrics._command, {
            stdout: JSON.stringify({
                plain: "Untimed\nSecond"
            })
        });
        compare(lyrics.synced, false);
        compare(lyrics.currentIndex, -1);
        compare(lyrics.lines[0].text, "Untimed");
    }

    function test_enhancedParsing() {
        const lyrics = createTemporaryObject(source, this);
        const lines = lyrics.parse("[offset:100]\n[00:01]<00:01>Hel<00:01.5>lo<00:02>\n[00:03]Next\n[00:03]Translation");
        compare(lines.length, 2);
        compare(lines[0].time, 0.9);
        compare(lines[0].text, "Hello");
        compare(lines[0].words[0].end, 1.4);
        compare(lines[0].words[1].start, 3);
        compare(lines[1].translation, "Translation");
    }

    function test_currentVerseFollowsSeeking() {
        const player = createTemporaryObject(playerComponent, this);
        const lyrics = createTemporaryObject(source, this, {
            player: player,
            positionUnitsPerSecond: 1
        });
        lyrics.lines = lyrics.parse("[00:01]First line\n[00:05]Second line\n[00:10]Third line");
        compare(lyrics.currentIndex, -1);
        player.position = 6;
        compare(lyrics.currentIndex, 1);
        compare(lyrics.currentLine, "Second line");
        lyrics.timingOffset = 5;
        compare(lyrics.currentLine, "Third line", "Positive offset advances lyrics");
        lyrics.timingOffset = -5;
        compare(lyrics.currentLine, "First line", "Negative offset delays lyrics");
        lyrics.timingOffset = 0;
        player.position = 2;
        compare(lyrics.currentIndex, 0);
        player.position = 12;
        compare(lyrics.currentIndex, 2);
        lyrics.lines = [];
        compare(lyrics.currentIndex, -1);
        compare(lyrics.currentLine, "");
    }

    function test_cancelOnMetadataAndDestruction() {
        const lyrics = createTemporaryObject(source, this);
        const pending = request();
        lyrics._request = pending;
        lyrics.track = 'A new track';
        lyrics.artist = 'Artist';
        verify(pending.aborted);
        compare(lyrics._request, null);
        const last = request();
        lyrics._request = last;
        lyrics.destroy();
        wait(10);
        verify(last.aborted);
    }
}
