# Lyrics and karaoke

Enable **Lyrics → Lyrics only** for the reading view, or **Line on card** for
one synced line. The widget checks local files before its online cache and
LRCLIB. Local lookup needs the player's MPRIS `xesam:url` to point to a local
`file:` URI; streaming URLs are never opened as local files.

For `Song.mp3`, lookup order is:

1. `Song.lrc`, `Song.mp3.lrc`, or `Song.LRC` in the audio directory.
2. Embedded ID3 `SYLT` (millisecond timestamps), then `USLT`.
3. Cached LRCLIB lyrics, then an online lookup using title, artist, album and duration.

UTF-8 and BOM-marked UTF-16 sidecars are supported. Plain USLT lyrics appear as
an untimed document in Lyrics only; no timing is fabricated. SYLT using MPEG
frame counts is skipped because those values are not milliseconds. Embedded
ID3 support uses Python **mutagen**; sidecar lookup needs only Python 3.
Nix packages and the development shell include the dependencies. For other
installations, install `mutagen` using your distribution's Python packages.

Enhanced LRC enables word or syllable fill, for example:

```text
[00:01.00]<00:01.00>Hel<00:01.50>lo <00:02.00>world<00:03.00>
```

A word ends at the next marker. Without a closing marker, it ends at the next
line; the final word of the document uses a two-second fallback. The GPU shader
adds a soft glowing wipe; software rendering uses a clipped fill. Reduced
motion highlights each timed unit without animating its fill. Ordinary LRC
continues to highlight whole lines. Seeks and pauses use the playback clock.

The **− / +** buttons change the saved timing offset in 100 ms steps, limited
to ±10 seconds. Positive values show lyrics earlier. Click the value to reset
it. Click inside the lyrics view to focus it, then use **− / +** (or **=**) on
the keyboard. The offset applies to both lyrics displays and all tracks.
The LRC `[offset:milliseconds]` tag also applies, with positive values earlier.

## Translations and pronunciation

Add timestamp-aligned companion files beside the audio:

- `Song.translation.lrc`: translated subtitles in any language.
- `Song.romaji.lrc`: pronunciation subtitles, including Romaji or Pinyin.
- `Song.reading.lrc`: Japanese kana readings.

Companions match the original's adjusted timestamps within 20 ms. Two lines
with the same timestamp in a single LRC also display as original + translation.
All lyric text is rendered literally; embedded HTML is not interpreted.

**Reading language** selects Automatic, Japanese or Chinese. Automatic detects
Japanese kana. Select Japanese or Chinese explicitly for Han-only lyrics,
which cannot be reliably distinguished from the text alone. Python **pykakasi**
provides Romaji and kana; **pypinyin** provides Pinyin with tone marks. These
optional libraries run locally once per lookup, including online lyrics, and
are included in the Nix environment. Missing libraries do not hide the lyrics.
Automatic pronunciation can be imperfect; companion files override it.
**Pronunciation subtitle** selects Romaji/Pinyin, kana, or off. Kana is rendered
as a reading subtitle, not as ruby annotations above individual kanji.

Translations must be supplied locally or included in the lyric text:
[LRCLIB's documented API](https://lrclib.net/docs) has no translation endpoint.
No automatic translation service is called.
