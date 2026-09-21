import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location(
    "local_lyrics",
    Path(__file__).resolve().parents[1] / "package/contents/code/local_lyrics.py",
)
lyrics = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lyrics)


class LocalLyrics(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.audio = Path(self.directory.name) / "a ' 日本語.mp3"
        self.audio.touch()

    def test_sidecar_precedence_and_companions(self):
        self.audio.with_suffix(".lrc").write_text("[00:01]Local", encoding="utf-16")
        self.audio.with_suffix(".translation.lrc").write_text("[00:01]Translation")
        self.audio.with_suffix(".romaji.lrc").write_text("[00:01]Reading")
        value = lyrics.load(self.audio.as_uri())
        self.assertEqual(value["synced"], "[00:01]Local")
        self.assertEqual(value["translation"], "[00:01]Translation")
        self.assertEqual(value["romanized"], "[00:01]Reading")

    def test_reject_remote_urls(self):
        for uri in (
            "https://example.com/a.mp3",
            "file://example.com/a.mp3",
            "relative.mp3",
        ):
            self.assertEqual(lyrics.load(uri), {})

    def test_alternative_filename_and_invalid_sidecar(self):
        self.audio.with_suffix(".lrc").write_bytes(b"\xff")
        Path(str(self.audio) + ".lrc").write_text("[00:02]Fallback")
        self.assertEqual(lyrics.load(self.audio.as_uri())["synced"], "[00:02]Fallback")

    def test_millisecond_sylt(self):
        class Frame:
            format = 2
            type = 1
            text = [("Hello ", 1000), ("world", 1500), ("\nNext", 3000)]

        self.assertEqual(
            lyrics.sylt_text(Frame()),
            "[00:01.000]<00:01.000>Hello <00:01.500>world\n[00:03.000]<00:03.000>Next",
        )
        frame = Frame()
        frame.format = 1
        self.assertEqual(lyrics.sylt_text(frame), "")

    def test_real_id3_roundtrip(self):
        try:
            from mutagen.id3 import ID3, USLT, SYLT
        except ImportError:
            self.skipTest("mutagen is not installed")
        for version in (3, 4):
            tags = ID3()
            tags.add(USLT(encoding=1, lang="jpn", text="Untimed 日本語"))
            tags.save(self.audio, v2_version=version)
            self.assertEqual(
                lyrics.load(self.audio.as_uri())["plain"], "Untimed 日本語"
            )
            tags.add(
                SYLT(
                    encoding=1,
                    lang="eng",
                    format=2,
                    type=1,
                    text=[("Hello ", 1000), ("world", 2000)],
                )
            )
            tags.save(self.audio, v2_version=version)
            self.assertIn(
                "<00:02.000>world", lyrics.load(self.audio.as_uri())["synced"]
            )
            self.audio.with_suffix(".lrc").write_text("[00:01]Sidecar wins")
            self.assertEqual(
                lyrics.load(self.audio.as_uri())["synced"], "[00:01]Sidecar wins"
            )
            self.audio.with_suffix(".lrc").unlink()

    def test_readings(self):
        try:
            import pykakasi  # noqa: F401
            import pypinyin  # noqa: F401
        except ImportError:
            self.skipTest("reading libraries are not installed")
        self.assertIn("nǐ", lyrics.readings("[00:01]你好", "zh")["romanized"])
        self.assertIn(
            "[00:01]", lyrics.readings("[00:01]こんにちは", "auto")["romanized"]
        )
        self.assertIn(
            "こんにちは", lyrics.readings("[00:01]こんにちは", "ja")["reading"]
        )
        self.assertEqual(lyrics.readings("[00:01]日本", "auto"), {})


if __name__ == "__main__":
    unittest.main()
