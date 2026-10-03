import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "media",
    Path(__file__).resolve().parents[1] / "package/contents/code/media_metadata.py",
)
media = importlib.util.module_from_spec(spec)
spec.loader.exec_module(media)


class MediaTests(unittest.TestCase):
    def test_lookup_removes_only_known_artist_prefix(self):
        self.assertEqual(media.lookup_title("Altero - Feeling", "Altero"), "Feeling")
        self.assertEqual(
            media.lookup_title("Altero — Feeling (Live)", "Altero"), "Feeling (Live)"
        )
        self.assertEqual(
            media.lookup_title("Other - Feeling", "Altero"), "Other - Feeling"
        )
        self.assertEqual(media.lookup_title("Altero - Feeling", ""), "Altero - Feeling")
        with (
            tempfile.TemporaryDirectory() as directory,
            patch.dict(media.os.environ, {"XDG_CACHE_HOME": directory}),
            patch.object(media, "recording_info", return_value={}) as recording,
            patch.object(media, "apple_info", return_value={}) as apple,
            patch.object(media, "get_json", return_value={}),
        ):
            media.info("Altero", "", "Altero - Feeling", 165, True)
            self.assertEqual(recording.call_args.args[0], "Feeling")
            self.assertEqual(apple.call_args.args[0], "Feeling")

    def test_favicon_discovers_any_public_site_and_caches_by_host(self):
        def fetch(url, _host, _limit):
            if url == "https://music.example.org/favicon.ico":
                raise OSError("missing conventional icon")
            if url == "https://music.example.org/":
                return b'<link rel="icon" href="/assets/music.png">'
            self.assertEqual(url, "https://music.example.org/assets/music.png")
            return b"\x89PNG\r\n\x1a\n" + b"icon"

        with (
            tempfile.TemporaryDirectory() as directory,
            patch.dict(media.os.environ, {"XDG_CACHE_HOME": directory}),
            patch.object(media, "_fetch_favicon_bytes", side_effect=fetch) as request,
        ):
            self.assertEqual(media.favicon("localhost"), {"status": "unsupported"})
            self.assertEqual(media.favicon("127.0.0.1"), {"status": "unsupported"})
            first = media.favicon("music.example.org")
            self.assertEqual(first["status"], "ready")
            self.assertTrue(first["url"].endswith("/music.example.org.png"))
            self.assertEqual(media.favicon("music.example.org"), first)
            self.assertEqual(request.call_count, 3)

    def test_favicon_falls_back_to_standard_path(self):
        def fetch(url, _host, _limit):
            self.assertEqual(url, "https://example.org/favicon.ico")
            return b"\x00\x00\x01\x00" + b"icon"

        with (
            tempfile.TemporaryDirectory() as directory,
            patch.dict(media.os.environ, {"XDG_CACHE_HOME": directory}),
            patch.object(media, "_fetch_favicon_bytes", side_effect=fetch),
        ):
            self.assertTrue(
                media.favicon("example.org")["url"].endswith("/example.org.ico")
            )

    def test_busctl_variants(self):
        self.assertEqual(
            media.unwrap(
                {
                    "type": "aa{sv}",
                    "data": [[{"xesam:title": {"type": "s", "data": "Title"}}]],
                }
            ),
            [[{"xesam:title": "Title"}]],
        )

    def test_queue_excludes_current_and_caps_batch(self):
        tracks = [f"/track/{i}" for i in range(100)]
        with (
            patch.object(
                media, "prop", side_effect=[True, tracks, {"mpris:trackid": tracks[4]}]
            ),
            patch.object(media, "bus", return_value=[[{"xesam:title": "Next"}]]) as bus,
        ):
            result = media.queue("player")
        self.assertEqual(result["total"], 95)
        self.assertEqual(bus.call_args.args[6], "50")
        self.assertEqual(bus.call_args.args[7], "/track/5")
        self.assertEqual(bus.call_args.args[-1], "/track/54")

    def test_unknown_current_is_not_fabricated_queue(self):
        with (
            patch.object(media, "prop", side_effect=[True, ["/one"], {}]),
            patch.object(media, "bus") as bus,
        ):
            self.assertEqual(media.queue("player")["status"], "unknown")
            bus.assert_not_called()

    def test_unsupported_and_empty_queue(self):
        with patch.object(media, "prop", return_value=False):
            self.assertEqual(media.queue("player")["status"], "unsupported")
        with (
            patch.object(
                media, "prop", side_effect=[True, ["/one"], {"mpris:trackid": "/one"}]
            ),
            patch.object(media, "bus") as bus,
        ):
            self.assertEqual(media.queue("player")["tracks"], [])
            bus.assert_not_called()

    def test_ambiguous_pid_does_not_select_arbitrary_player(self):
        with (
            patch.object(
                media,
                "bus",
                side_effect=[
                    [["org.mpris.MediaPlayer2.a", "org.mpris.MediaPlayer2.b"]],
                    [123],
                    [123],
                ],
            ),
            patch.object(media, "prop", return_value="Player"),
        ):
            with self.assertRaises(ValueError):
                media.resolve_player({"pid": 123, "identity": "Player"})

    def test_disambiguation_not_shown(self):
        with (
            patch.dict(media.os.environ, {"XDG_CACHE_HOME": "/dev/null"}),
            patch.object(
                media,
                "get_json",
                return_value={
                    "query": {
                        "pages": {
                            "1": {
                                "extract": "A band or singer",
                                "pageprops": {"disambiguation": ""},
                            }
                        }
                    }
                },
            ),
        ):
            self.assertEqual(media.info("Ambiguous", "")["status"], "empty")

    def test_exact_album_match_and_summary(self):
        album = {
            "release-groups": [
                {
                    "id": "release-id",
                    "title": "Album",
                    "first-release-date": "2001-02-03",
                    "primary-type": "Album",
                    "secondary-types": ["Live"],
                    "artist-credit": [{"artist": {"name": "Artist"}}],
                    "tags": [{"name": "jazz"}],
                }
            ]
        }
        wiki = {
            "query": {
                "pages": {
                    "1": {
                        "extract": "Artist is a musician.",
                        "fullurl": "https://en.wikipedia.org/wiki/Artist",
                    }
                }
            }
        }
        with (
            patch.dict(media.os.environ, {"XDG_CACHE_HOME": "/dev/null"}),
            patch.object(media, "get_json", side_effect=[album, wiki]),
        ):
            result = media.info("Artist", "Album")
        self.assertEqual(result["status"], "ready")
        self.assertEqual(result["year"], "2001")
        self.assertEqual(result["releaseDate"], "2001-02-03")
        self.assertEqual(result["releaseType"], "Album · Live")
        self.assertEqual(result["genres"], ["jazz"])
        self.assertEqual(result["summary"], "Artist is a musician.")

    def test_recording_match_requires_identity_and_rejects_versions(self):
        record = {
            "id": "one",
            "title": "A Song",
            "length": 180000,
            "artist-credit": [{"artist": {"name": "Artist"}}],
        }
        self.assertEqual(
            media.recording_match([record], "a song", "Artist", "", 180)[0], record
        )
        self.assertIsNone(
            media.recording_match([record], "A Song (Live)", "Artist", "", 180)[0]
        )
        self.assertIsNone(
            media.recording_match([record], "A Song", "Someone Else", "", 180)[0]
        )
        self.assertIsNone(media.recording_match([record], "A Song", "", "", 0)[0])
        self.assertIsNone(media.recording_match([record], "A Song", "", "", 185)[0])
        self.assertEqual(
            media.recording_match([record], "A Song", "", "", 180)[0], record
        )
        self.assertEqual(
            media.recording_match(
                [record, dict(record, id="two")], "A Song", "Artist", "", 180
            ),
            (None, True),
        )

    def test_recording_credits_and_single_release(self):
        rid = "12345678-1234-1234-1234-123456789012"
        record = {
            "id": rid,
            "title": "Song",
            "length": 152000,
            "artist-credit": [{"name": "Artist"}],
        }
        detail = {
            "isrcs": ["GB1234567890"],
            "genres": [{"name": "rock"}],
            "disambiguation": "original mix",
            "relations": [
                {"type": "producer", "artist": {"name": "Producer"}},
                {
                    "type": "instrument",
                    "attributes": ["guitar"],
                    "artist": {"name": "Player"},
                },
                {
                    "type": "performance",
                    "work": {
                        "relations": [
                            {"type": "composer", "artist": {"name": "Composer"}},
                            {"type": "lyricist", "artist": {"name": "Writer"}},
                        ]
                    },
                },
            ],
            "releases": [
                {
                    "id": rid,
                    "title": "Album",
                    "release-group": {
                        "id": rid,
                        "title": "Album",
                        "primary-type": "Album",
                        "first-release-date": "2001-01-01",
                    },
                }
            ],
        }
        release = {
            "title": "Album",
            "country": "GB",
            "date": "2001-02-01",
            "label-info": [{"label": {"name": "Label"}}],
        }
        with patch.object(
            media, "get_json", side_effect=[{"recordings": [record]}, detail, release]
        ) as request:
            result = media.recording_info("Song", "Artist", "Album", 152)
        self.assertEqual(result["composer"], "Composer")
        self.assertEqual(result["lyricist"], "Writer")
        self.assertEqual(result["producers"], "Producer")
        self.assertEqual(result["performers"], "Player (guitar)")
        self.assertEqual(result["label"], "Label")
        self.assertEqual(result["country"], "GB")
        self.assertEqual(result["isrc"], "GB1234567890")
        self.assertIn("work-level-rels", request.call_args_list[1].args[0])

    def test_explicit_recording_choice_stays_with_matching_song(self):
        records = [
            {"id": "one", "title": "Song", "artist-credit": [{"name": "Artist"}]},
            {"id": "two", "title": "Song", "artist-credit": [{"name": "Artist"}]},
        ]
        self.assertIsNone(media.recording_match(records, "Song", "Artist", "", 0)[0])
        self.assertEqual(
            media.recording_match(records, "Song", "Artist", "", 0, "two")[0]["id"],
            "two",
        )
        self.assertIsNone(
            media.recording_match(records, "Other song", "Artist", "", 0, "two")[0]
        )
        with patch.object(media, "get_json", return_value={"recordings": records}):
            result = media.recording_info("Song", "Artist", "", 0)
        self.assertEqual(result["reason"], "ambiguous")
        self.assertEqual([r["id"] for r in result["candidates"]], ["one", "two"])

    def test_recording_partial_result_survives_failed_credits(self):
        record = {
            "id": "12345678-1234-1234-1234-123456789012",
            "title": "Song",
            "artist-credit": [{"name": "Artist"}],
        }
        with patch.object(
            media,
            "get_json",
            side_effect=[{"recordings": [record]}, OSError("offline")],
        ):
            result = media.recording_info("Song", "Artist", "", 0)
        self.assertTrue(result["partial"])
        self.assertIn("recordingUrl", result)

    def test_apple_is_separately_opted_in_and_cache_separates_songs(self):
        with (
            tempfile.TemporaryDirectory() as directory,
            patch.dict(media.os.environ, {"XDG_CACHE_HOME": directory}),
            patch.object(media, "get_json", return_value={}),
            patch.object(
                media,
                "apple_info",
                return_value={
                    "catalogUrl": "https://music.apple.com/us/album/example",
                    "album": "Found",
                },
            ) as apple,
        ):
            media.info("Artist", "", "Song", 152)
            apple.assert_not_called()
            result = media.info("Artist", "", "Song", 152, True)
            self.assertEqual(result["status"], "ready")
            self.assertEqual(result["album"], "Found")
            media.info("Artist", "", "Song", 152, True)
            self.assertEqual(apple.call_count, 1)
            media.info("Artist", "", "Other song", 152, True)
            self.assertEqual(apple.call_count, 2)

    def test_screenshot_title_does_not_match_wrong_apple_artist_or_length(self):
        songs = [
            {
                "kind": "song",
                "trackId": 1,
                "trackName": "Elegant Science",
                "artistName": "Felix Thoma",
                "trackTimeMillis": 147674,
            },
            {
                "kind": "song",
                "trackId": 2,
                "trackName": "Elegant Science",
                "artistName": "Roman Spivak",
                "trackTimeMillis": 169091,
            },
        ]
        with patch.object(media, "get_json", return_value={"results": songs}):
            self.assertNotIn(
                "catalogUrl", media.apple_info("Elegant Science", "", "", 152)
            )
            self.assertNotIn(
                "catalogUrl",
                media.apple_info("Elegant Science", "Melodic Blaze", "", 152),
            )

    def test_apple_match_supplies_missing_album(self):
        song = {
            "kind": "song",
            "trackId": 1,
            "trackName": "Song",
            "artistName": "Artist",
            "collectionName": "Album",
            "trackTimeMillis": 152000,
            "trackNumber": 3,
            "trackViewUrl": "https://music.apple.com/us/album/song?i=1",
            "releaseDate": "2025-01-01T00:00:00Z",
        }
        with patch.object(media, "get_json", return_value={"results": [song]}):
            result = media.apple_info("Song", "", "", 152)
        self.assertEqual(result["matchedArtist"], "Artist")
        self.assertEqual(result["album"], "Album")
        self.assertEqual(result["matchBasis"], "duration")
        self.assertEqual(result["trackNumber"], 3)

    def test_offline_is_retryable(self):
        with (
            patch.dict(media.os.environ, {"XDG_CACHE_HOME": "/dev/null"}),
            patch.object(media, "get_json", side_effect=OSError("offline")),
        ):
            self.assertEqual(media.info("Artist", "Album")["status"], "error")


if __name__ == "__main__":
    unittest.main()
