#!/usr/bin/env python3
import importlib.util
import json
from pathlib import Path
import shutil
import struct
import tempfile
import unittest
from unittest.mock import patch
import wave

HELPER = Path(__file__).resolve().parents[1] / "package/contents/code/track_profile.py"
spec = importlib.util.spec_from_file_location("track_profile", HELPER)
profile = importlib.util.module_from_spec(spec)
spec.loader.exec_module(profile)


class ProfileTests(unittest.TestCase):
    def test_silence_and_invalid_cache(self):
        self.assertEqual(profile.normalize([0] * 128), [0] * 128)
        for value in [None, [], [float("nan")] * 128, [-1] * 128]:
            self.assertEqual(profile.normalize(value), [])

    def test_remote_is_cache_only(self):
        with (
            tempfile.TemporaryDirectory() as directory,
            patch.object(profile.subprocess, "run") as run,
        ):
            result = profile.profile("https://example.invalid/track", directory)
            self.assertEqual(result["status"], "uncached-stream")
            run.assert_not_called()

    @unittest.skipUnless(
        shutil.which("ffmpeg") and shutil.which("ffprobe"), "ffmpeg/ffprobe needed"
    )
    def test_real_peaks_cache_and_invalidation(self):
        with tempfile.TemporaryDirectory() as directory:
            audio = Path(directory) / "quiet ' then loud.wav"
            with wave.open(str(audio), "wb") as output:
                output.setnchannels(1)
                output.setsampwidth(2)
                output.setframerate(8000)
                output.writeframes(
                    b"".join(
                        struct.pack(
                            "<h", (2000 if i < 8192 else 20000) * (1 if i % 2 else -1)
                        )
                        for i in range(16384)
                    )
                )
            result = profile.profile(audio.as_uri(), directory)
            self.assertEqual(result["status"], "ready", result)
            self.assertEqual(len(result["peaks"]), 128)
            self.assertAlmostEqual(result["peaks"][10], 0.1, places=2)
            self.assertAlmostEqual(result["peaks"][100], 1, places=2)
            with patch.object(
                profile,
                "decode_peaks",
                side_effect=AssertionError("Cache should be used"),
            ):
                self.assertEqual(
                    profile.profile(audio.as_uri(), directory)["peaks"], result["peaks"]
                )
            # Sidecar changes are read even when the acoustic cache remains valid.
            audio.with_suffix(".chapters").write_text(
                json.dumps([{"start": 0.5, "title": "Drop"}])
            )
            self.assertEqual(
                profile.profile(audio.as_uri(), directory)["chapters"][0]["title"],
                "Drop",
            )
            audio.write_bytes(audio.read_bytes() + b"\x00\x00")
            with patch.object(
                profile, "decode_peaks", return_value=[0.5] * 128
            ) as decode:
                profile.profile(audio.as_uri(), directory)
                decode.assert_called_once()

    def test_plain_and_ogm_chapter_formats(self):
        self.assertEqual(
            profile.text_chapters("00:00:00.000 Intro\n00:02:30.500 Drop")[1]["start"],
            150.5,
        )
        self.assertEqual(
            profile.text_chapters("CHAPTER01=00:01:02.500\nCHAPTER01NAME=Verse")[0],
            {"start": 62.5, "title": "Verse"},
        )

    def test_cue_and_malformed_chapters(self):
        with tempfile.TemporaryDirectory() as directory:
            audio = Path(directory) / "album.flac"
            audio.with_suffix(".cue").write_text(
                'FILE "album.flac" WAVE\n TRACK 01 AUDIO\n TITLE "Intro"\n INDEX 01 00:00:00\n TRACK 02 AUDIO\n TITLE "Drop"\n INDEX 01 02:30:37\nFILE "other.flac" WAVE\n INDEX 01 00:00:00\n'
            )
            chapters = profile.sidecar_chapters(audio)
            self.assertEqual(len(chapters), 2)
            self.assertAlmostEqual(chapters[1]["start"], 150 + 37 / 75)
        self.assertEqual(
            profile.clean_chapters([None, {}, {"start": -1}, {"start": "nan"}]), []
        )


if __name__ == "__main__":
    unittest.main()
