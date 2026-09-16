import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "media",
    Path(__file__).resolve().parents[1] / "package/contents/code/media_metadata.py",
)
media = importlib.util.module_from_spec(spec)
spec.loader.exec_module(media)


class MediaTests(unittest.TestCase):
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
        self.assertEqual(result["genres"], ["jazz"])
        self.assertEqual(result["summary"], "Artist is a musician.")

    def test_offline_is_retryable(self):
        with (
            patch.dict(media.os.environ, {"XDG_CACHE_HOME": "/dev/null"}),
            patch.object(media, "get_json", side_effect=OSError("offline")),
        ):
            self.assertEqual(media.info("Artist", "Album")["status"], "error")


if __name__ == "__main__":
    unittest.main()
