#!/usr/bin/env python3
"""Bounded local-file waveform/chapter extraction; remote URLs are cache-only."""
import array
import hashlib
import json
import math
import os
from pathlib import Path
import re
import selectors
import subprocess
import sys
import time
from urllib.parse import unquote, urlparse

COUNT = 128


def normalize(values):
    if not isinstance(values, list) or len(values) != COUNT:
        return []
    if any(not isinstance(v, (int, float)) or not math.isfinite(v) or v < 0 for v in values):
        return []
    maximum = max(values)
    return [min(1.0, v / maximum) if maximum else 0.0 for v in values]


def sidecar_chapters(path):
    for candidate in [path.with_suffix('.chapters'), path.with_suffix('.chapters.json'), path.with_suffix('.cue')]:
        if not candidate.is_file() or candidate.stat().st_size > 1024 * 1024:
            continue
        text = candidate.read_text(errors='replace')
        if candidate.suffix != '.cue':
            try:
                value = json.loads(text)
                return value if isinstance(value, list) else value.get('chapters', [])
            except (ValueError, AttributeError):
                continue
        chapters, title = [], ''
        matches_file = True
        for line in text.splitlines():
            match = re.match(r'\s*FILE\s+"([^"]+)"', line, re.I)
            if match:
                matches_file = Path(match[1]).name == path.name
            match = re.match(r'\s*TITLE\s+"([^"]+)"', line, re.I)
            if match:
                title = match[1]
            match = re.match(r'\s*INDEX\s+01\s+(\d+):(\d+):(\d+)', line, re.I)
            if match and matches_file:
                m, s, f = map(int, match.groups())
                if s < 60 and f < 75:
                    chapters.append({'start': m * 60 + s + f / 75, 'title': title})
        if chapters:
            return chapters
    return []


def decode_peaks(path, duration, timeout=90):
    peaks = [0.0] * COUNT
    # Restrict protocols even for local playlists; no network capture/download.
    command = ['ffmpeg', '-v', 'error', '-nostdin', '-protocol_whitelist', 'file,pipe',
               '-i', str(path), '-map', '0:a:0', '-vn', '-ac', '1', '-ar', '8000', '-f', 'f32le', 'pipe:1']
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ)
    deadline, sample_index, pending = time.monotonic() + timeout, 0, bytearray()
    try:
        while True:
            if time.monotonic() > deadline:
                raise TimeoutError('Audio decoding timed out')
            if not selector.select(.2):
                continue
            data = os.read(process.stdout.fileno(), 32768)
            if not data:
                break
            pending.extend(data)
            complete = len(pending) // 4 * 4
            samples = array.array('f')
            samples.frombytes(pending[:complete])
            del pending[:complete]
            if sys.byteorder != 'little':
                samples.byteswap()
            for value in samples:
                if math.isfinite(value):
                    bin_index = min(COUNT - 1, int(sample_index * COUNT / (duration * 8000)))
                    peaks[bin_index] = max(peaks[bin_index], abs(value))
                sample_index += 1
        if process.wait(timeout=2) != 0 or not sample_index:
            raise ValueError('No decodable audio')
        return normalize(peaks)
    finally:
        selector.close()
        process.stdout.close()
        if process.poll() is None:
            process.kill()
        process.wait()


def profile(url, cache_root=None):
    cache = Path(cache_root or os.environ.get('XDG_CACHE_HOME', str(Path.home() / '.cache'))) / 'plasma-audio-visualizer' / 'peaks'
    key = hashlib.sha1(url.encode()).hexdigest()
    target = cache / (key + '.json')
    parsed = urlparse(url)
    local = parsed.scheme == 'file' and parsed.netloc in ('', 'localhost')
    path = Path(unquote(parsed.path)) if local else None
    if path and (not path.is_file()):
        return {'peaks': [], 'chapters': [], 'status': 'missing'}
    stamp = [path.stat().st_mtime_ns, path.stat().st_size] if path else None
    try:
        if target.stat().st_size < 128 * 1024:
            cached = json.loads(target.read_text())
            if cached.get('url') == url and cached.get('stamp') == stamp and normalize(cached.get('peaks')):
                cached['peaks'] = normalize(cached['peaks'])
                if path:
                    cached['chapters'] = sidecar_chapters(path) or cached.get('chapters', [])
                return cached
    except (OSError, ValueError, AttributeError):
        pass
    if not path:
        return {'peaks': [], 'chapters': [], 'status': 'uncached-stream'}
    chapters = sidecar_chapters(path)
    try:
        result = subprocess.run(['ffprobe', '-v', 'error', '-protocol_whitelist', 'file,pipe', '-show_format', '-show_chapters', '-of', 'json', str(path)], capture_output=True, timeout=10, check=True)
        info = json.loads(result.stdout)
        duration = float(info.get('format', {}).get('duration', 0))
        if not math.isfinite(duration) or not 0 < duration <= 86400:
            raise ValueError('Invalid track duration')
        if not chapters:
            chapters = [{'start': float(c['start_time']), 'title': c.get('tags', {}).get('title', '')} for c in info.get('chapters', [])]
        peaks = decode_peaks(path, duration)
    except (OSError, ValueError, KeyError, subprocess.SubprocessError, TimeoutError) as error:
        return {'peaks': [], 'chapters': chapters, 'status': 'unavailable', 'detail': str(error)[:200]}
    value = {'version': 1, 'url': url, 'stamp': stamp, 'duration': duration, 'peaks': peaks, 'chapters': chapters, 'status': 'ready'}
    cache.mkdir(parents=True, exist_ok=True)
    temporary = target.with_suffix(f'.{os.getpid()}.tmp')
    try:
        temporary.write_text(json.dumps(value, allow_nan=False))
        temporary.replace(target)
    finally:
        temporary.unlink(missing_ok=True)
    return value


if __name__ == '__main__':
    try:
        print(json.dumps(profile(sys.argv[1]), allow_nan=False))
    except (OSError, ValueError, IndexError) as error:
        print(json.dumps({'peaks': [], 'chapters': [], 'status': 'unavailable', 'detail': str(error)[:200]}))
