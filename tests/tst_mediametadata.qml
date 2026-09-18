import QtQuick
import QtTest
import "../package/contents/ui"
import "../package/contents/code/AudioFormat.js" as AudioFormat
import "../package/contents/code/MediaSource.js" as MediaSource

TestCase {
    name: "MediaMetadata"
    when: windowShown
    width: 500
    height: 600
    Component {
        id: lookupComponent
        MediaLookup {
            commandSourceComponent: Component {
                Item {
                    property var connectedSources: []
                    signal newData(string source, var data)
                    function connectSource(source) {
                        connectedSources = [source];
                    }
                    function disconnectSource(source) {
                        connectedSources = connectedSources.filter(s => s !== source);
                    }
                    function cancelSource(source) {
                        disconnectSource(source);
                    }
                }
            }
        }
    }
    function test_formatEvidence() {
        compare(AudioFormat.badges({}), []);
        compare(AudioFormat.badges({
            "xesam:url": "file:///music.flac"
        }), []);
        compare(AudioFormat.badges({
            "xesam:audioCodec": "flac",
            "xesam:audioSampleRate": 96000,
            "xesam:audioBitsPerSample": 24
        }), ["FLAC", "Lossless", "96kHz/24bit"]);
        compare(AudioFormat.badges({
            "xesam:audioBitrate": 320000
        }), ["320 kbps"]);
        compare(AudioFormat.badges({
            "codec": "dsd128"
        }), ["DSD128"]);
        compare(AudioFormat.badges({
            "sampleRate": -1,
            "bitrate": "invalid",
            "bitsPerSample": 999
        }), []);
    }
    function test_browserSourceName() {
        compare(MediaSource.displayName("Mozilla Zen", "zen", "", {
            "xesam:url": "https://music.youtube.com/watch?v=abc"
        }), "YouTube Music");
        compare(MediaSource.displayName("Mozilla Firefox", "firefox", "", {
            "xesam:url": "https://www.youtube.com/watch?v=abc"
        }), "YouTube");
        compare(MediaSource.displayName("Chromium", "chromium", "", {
            "xesam:url": "https://artist.bandcamp.com/track/song"
        }), "Bandcamp");
        compare(MediaSource.displayName("Brave", "brave", "", {
            "xesam:url": "https://example.org/music"
        }), "example.org");
        compare(MediaSource.displayName("Mozilla Zen", "zen", "", {}), "Mozilla Zen");
        compare(MediaSource.displayName("Spotify", "spotify", "", {
            "xesam:url": "https://music.youtube.com/watch?v=abc"
        }), "Spotify");
        compare(MediaSource.siteHost("Mozilla Zen", "zen", "", {
            "xesam:url": "https://music.youtube.com/watch?v=abc"
        }), "music.youtube.com");
        compare(MediaSource.siteHost("Mozilla Zen", "zen", "", {
            "xesam:url": "https://www.youtube.com/watch?v=abc"
        }), "www.youtube.com");
        compare(MediaSource.displayName("Mozilla Zen", "zen", "", {
            "xesam:url": "https://music.apple.com/album/example"
        }), "Apple Music");
        compare(MediaSource.siteHost("Mozilla Zen", "zen", "", {
            "xesam:url": "https://unknown.example/song"
        }), "unknown.example");
        compare(MediaSource.siteHost("Spotify", "spotify", "", {
            "xesam:url": "https://music.youtube.com/watch?v=abc"
        }), "");
    }
    function test_lookupLifecycle() {
        const lookup = createTemporaryObject(lookupComponent, this, {
            active: true,
            payload: {
                artist: "First"
            }
        });
        const worker = findChild(lookup, "mediaLookupWorker");
        tryVerify(() => lookup.command !== "");
        const stale = lookup.command;
        lookup.payload = {
            artist: "Second"
        };
        tryVerify(() => lookup.command !== "" && lookup.command !== stale);
        worker.item.newData(stale, {
            stdout: '{"status":"ready","summary":"old"}'
        });
        compare(lookup.status, "loading");
        worker.item.newData(lookup.command, {
            stdout: '{"status":"ready","summary":"new"}'
        });
        compare(lookup.result.summary, "new");
        lookup.active = false;
        compare(lookup.status, "idle");
        compare(lookup.result, {});
    }
    function test_popupLoads() {
        const view = {
            Window: {
                window: null
            },
            displayTrack: "Title",
            artist: "Artist",
            album: "Album",
            year: "",
            genre: "",
            artUrl: "",
            desktopEntry: "",
            fallbackIcon: null,
            zoomOpen: true,
            visible: true,
            shouldShow: true,
            samplePlayback: true,
            hasPlayer: true,
            visualizer: {},
            playerSelector: {},
            trackIdentity: "one",
            formatBadges: ["FLAC"]
        };
        const component = Qt.createComponent("../package/contents/ui/ArtworkLightbox.qml");
        compare(component.status, Component.Ready, component.errorString());
        const popup = createTemporaryObject(component, this, {
            view: view
        });
        verify(popup !== null);
        compare(popup.visible, true);
        const queue = findChild(popup.contentItem, "playQueue");
        const info = findChild(popup.contentItem, "artistInfo");
        queue.expanded = true;
        info.expanded = true;
        wait(100);
        verify(queue.width > 100);
        verify(info.height > 50);
        popup.close();
    }
}
