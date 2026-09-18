import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import MagicMock, patch
from urllib.error import HTTPError, URLError

spec = importlib.util.spec_from_file_location(
    "online_lyrics",
    Path(__file__).resolve().parents[1] / "package/contents/code/online_lyrics.py",
)
lyrics = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lyrics)


class OnlineLyrics(unittest.TestCase):
    def test_fixed_endpoint_and_plain_lyrics(self):
        response = MagicMock()
        response.__enter__.return_value.read.return_value = json.dumps(
            {"plainLyrics": "First\nSecond", "syncedLyrics": None}
        ).encode()
        with patch.object(lyrics, "urlopen", return_value=response) as fetch:
            result = lyrics.fetch(
                "track_name=A%26B&artist_name=C&url=https://other.test"
            )
        self.assertEqual(result["status"], 200)
        self.assertEqual(result["body"]["plainLyrics"], "First\nSecond")
        self.assertEqual(
            fetch.call_args.args[0].full_url,
            "https://lrclib.net/api/get?track_name=A%26B&artist_name=C",
        )
        self.assertEqual(fetch.call_args.kwargs["timeout"], 12)

    def test_missing_is_distinct_from_transport_failure(self):
        for error, status in (
            (HTTPError("https://lrclib.net", 404, "missing", {}, None), 404),
            (HTTPError("https://lrclib.net", 503, "unavailable", {}, None), 503),
            (URLError("TLS failure"), 0),
            (TimeoutError(), 0),
        ):
            with self.subTest(status=status):
                with patch.object(lyrics, "urlopen", side_effect=error):
                    self.assertEqual(
                        lyrics.fetch("track_name=Song"), {"status": status}
                    )

    def test_reject_invalid_and_oversized_responses(self):
        for payload in (b"not json", b"[]", b"null", b"x" * (2 * 1024 * 1024 + 1)):
            response = MagicMock()
            response.__enter__.return_value.read.return_value = payload
            with patch.object(lyrics, "urlopen", return_value=response):
                self.assertEqual(lyrics.fetch("track_name=Song"), {"status": 0})


if __name__ == "__main__":
    unittest.main()
