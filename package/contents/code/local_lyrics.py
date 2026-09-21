#!/usr/bin/env python3
"""Read local lyric sidecars and ID3 tags. Never opens a network URL or writes audio."""

import json
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit

LIMIT = 2 * 1024 * 1024
TIME = re.compile(r"\[\d+:[0-5]?\d(?:[.:]\d+)?\]")


def read_text(path):
    try:
        if not path.is_file() or path.stat().st_size > LIMIT:
            return ""
        data = path.read_bytes()
        return data.decode(
            "utf-16" if data.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig"
        )
    except (OSError, UnicodeError):
        return ""


def timestamp(ms, brackets="[]"):
    ms = max(0, int(ms))
    return f"{brackets[0]}{ms // 60000:02}:{ms // 1000 % 60:02}.{ms % 1000:03}{brackets[1]}"


def sylt_text(frame):
    # Format 1 measures MPEG frames, not milliseconds; do not invent timings.
    if frame.format != 2 or frame.type != 1:
        return ""
    output = []
    for text, ms in frame.text:
        if not output or text.startswith(("\n", "\r")):
            output.append(timestamp(ms))
        output[-1] += timestamp(ms, "<>") + text.strip("\r\n")
    return "\n".join(output)


def embedded(path):
    try:
        from mutagen.id3 import ID3
        from mutagen import MutagenError
    except ImportError:
        return {"warning": "Install Python mutagen for embedded ID3 lyrics"}
    try:
        tags = ID3(path)
        synced = next(
            (value for frame in tags.getall("SYLT") if (value := sylt_text(frame))), ""
        )
        unsynced = [frame.text for frame in tags.getall("USLT") if frame.text.strip()]
        synced = synced or next((text for text in unsynced if TIME.search(text)), "")
        return {
            "synced": synced,
            "plain": unsynced[0] if unsynced and not synced else "",
        }
    except (OSError, MutagenError, ValueError):
        return {}


def readings(text, language="auto"):
    """Readings, not translations. Never guess Chinese for ambiguous Han-only text."""
    plain = re.sub(r"<\d+:[^>]+>", "", text)
    japanese = language == "ja" or (
        language == "auto" and re.search(r"[\u3040-\u30ff]", plain)
    )
    try:
        if japanese:
            import pykakasi

            converter = pykakasi.kakasi()

            def convert(line):
                parts = converter.convert(line)
                return " ".join(p["hepburn"] for p in parts), " ".join(
                    p["hira"] for p in parts
                )
        elif language == "zh":
            from pypinyin import lazy_pinyin, Style

            def convert(line):
                return " ".join(lazy_pinyin(line, style=Style.TONE)), ""
        else:
            return {}
    except ImportError:
        return {"warning": "Install Python pykakasi / pypinyin for automatic readings"}
    romanized, kana = [], []
    for line in plain.splitlines():
        tags = "".join(TIME.findall(line))
        body = re.sub(r"\[[^\]]*\]", "", line)
        if not body.strip():
            continue
        romaji, furigana = convert(body)
        romanized.append(tags + romaji)
        if furigana:
            kana.append(tags + furigana)
    offset = re.search(r"\[offset:[+-]?\d+\]", plain, re.I)
    prefix = offset[0] + "\n" if offset else ""
    return {
        "romanized": prefix + "\n".join(romanized),
        "reading": prefix + "\n".join(kana),
    }


def load(uri, language="auto"):
    parsed = urlsplit(uri)
    if (
        parsed.scheme != "file"
        or parsed.netloc not in ("", "localhost")
        or parsed.query
        or parsed.fragment
    ):
        return {}
    path = Path(unquote(parsed.path))
    if not path.is_absolute() or not path.is_file():
        return {}
    result = {}
    for candidate in (
        path.with_suffix(".lrc"),
        Path(str(path) + ".lrc"),
        path.with_suffix(".LRC"),
    ):
        text = read_text(candidate)
        if TIME.search(text):
            result = {"synced": text}
            break
    if not result:
        result = embedded(path)
    text = result.get("synced") or result.get("plain", "")
    if text:
        result.update(readings(text, language))
    for field, suffix in (
        ("translation", ".translation.lrc"),
        ("romanized", ".romaji.lrc"),
        ("reading", ".reading.lrc"),
    ):
        sidecar = read_text(path.with_suffix(suffix))
        if sidecar:
            result[field] = sidecar
    return result


def main():
    try:
        if sys.argv[1] == "--readings":
            result = readings(sys.argv[2], sys.argv[3])
        else:
            result = load(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "auto")
        print(json.dumps(result, ensure_ascii=True))
    except (OSError, ValueError, IndexError):
        print("{}")


if __name__ == "__main__":
    main()
