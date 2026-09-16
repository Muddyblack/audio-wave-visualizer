#!/usr/bin/env python3
"""Read-only MPRIS queue/metadata bridge and on-demand public music information."""

import fcntl
import hashlib
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from urllib.parse import urlencode, urljoin, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener, urlopen

ROOT = "org.mpris.MediaPlayer2"
PATH = "/org/mpris/MediaPlayer2"


def unwrap(value):
    if isinstance(value, dict):
        if set(value) == {"type", "data"}:
            return unwrap(value["data"])
        return {k: unwrap(v) for k, v in value.items()}
    if isinstance(value, list):
        return [unwrap(v) for v in value]
    return value


def bus(*args):
    result = subprocess.run(
        ["busctl", "--user", "--timeout=2", "--json=short", *args],
        capture_output=True,
        text=True,
        timeout=3,
        check=True,
    )
    return unwrap(json.loads(result.stdout))


def prop(service, interface, name):
    return bus("get-property", service, PATH, interface, name)


def resolve_player(selector):
    service = selector.get("service", "")
    if re.fullmatch(r"org\.mpris\.MediaPlayer2\.[\w.-]+", service, re.ASCII):
        return service
    # Plasma exposes the owning PID, but not the D-Bus service name in QML.
    pid = selector.get("pid", 0)
    if not pid:
        raise ValueError("No player address")
    names = bus(
        "call",
        "org.freedesktop.DBus",
        "/org/freedesktop/DBus",
        "org.freedesktop.DBus",
        "ListNames",
    )[0]
    matches = []
    for name in [n for n in names if n.startswith(ROOT + ".")][:32]:
        try:
            owner = bus(
                "call",
                "org.freedesktop.DBus",
                "/org/freedesktop/DBus",
                "org.freedesktop.DBus",
                "GetConnectionUnixProcessID",
                "s",
                name,
            )[0]
            if owner == pid and prop(name, ROOT, "Identity") == selector.get(
                "identity"
            ):
                matches.append(name)
        except (OSError, ValueError, subprocess.SubprocessError):
            continue
    if len(matches) != 1:
        raise ValueError("Ambiguous or missing player")
    return matches[0]


def queue(service):
    if not prop(service, ROOT, "HasTrackList"):
        return {"status": "unsupported", "tracks": []}
    tracks = prop(service, ROOT + ".TrackList", "Tracks")
    current = prop(service, ROOT + ".Player", "Metadata").get("mpris:trackid")
    if current not in tracks:
        return {"status": "unknown", "tracks": []}
    upcoming = tracks[tracks.index(current) + 1 :]
    ids = upcoming[:50]
    metadata = (
        bus(
            "call",
            service,
            PATH,
            ROOT + ".TrackList",
            "GetTracksMetadata",
            "ao",
            str(len(ids)),
            *ids,
        )[0]
        if ids
        else []
    )
    return {"status": "ready", "tracks": metadata, "total": len(upcoming)}


def get_json(url):
    # Cross-process MusicBrainz throttle, shared by widgets on multiple screens.
    if url.startswith("https://musicbrainz.org/"):
        directory = (
            Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
            / "plasma-audio-visualizer"
        )
        directory.mkdir(parents=True, exist_ok=True)
        with (directory / "musicbrainz.lock").open("a+") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            lock.seek(0)
            try:
                previous = float(lock.read() or 0)
            except ValueError:
                previous = 0
            time.sleep(max(0, min(1.1, 1.1 - (time.time() - previous))))
            lock.seek(0)
            lock.truncate()
            lock.write(str(time.time()))
            lock.flush()
            return request_json(url)
    return request_json(url)


def request_json(url):
    request = Request(
        url,
        headers={
            "User-Agent": "PlasmaAudioVisualizer/3.0 (https://github.com/Muddyblack/audio-wave-visualizer)",
            "Accept": "application/json",
        },
    )
    with urlopen(request, timeout=8) as response:
        data = response.read(2 * 1024 * 1024 + 1)
        if len(data) > 2 * 1024 * 1024:
            raise ValueError("Response too large")
        return json.loads(data)


class IconLinks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.hrefs = []

    def handle_starttag(self, tag, attrs):
        if tag != "link":
            return
        values = dict(attrs)
        if "icon" in values.get("rel", "").lower().split() and values.get("href"):
            self.hrefs.append(values["href"])


def _favicon_host(host):
    """Accept public-looking DNS names, never literal or local addresses."""
    if not isinstance(host, str) or len(host) > 253:
        return ""
    host = host.lower().rstrip(".")
    labels = host.split(".")
    if len(labels) < 2 or host.endswith(
        (".local", ".localhost", ".internal", ".test", ".invalid")
    ):
        return ""
    if not all(
        re.fullmatch(r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?", label) for label in labels
    ):
        return ""
    if labels[-1].isdigit():
        return ""
    return host


def _fetch_favicon_bytes(url, host, limit):
    hosts = {host, host[4:] if host.startswith("www.") else "www." + host}

    class SameHostRedirect(HTTPRedirectHandler):
        def redirect_request(self, request, fp, code, msg, headers, newurl):
            if (
                urlsplit(newurl).scheme != "https"
                or urlsplit(newurl).hostname not in hosts
            ):
                raise ValueError("Cross-host favicon redirect")
            return super().redirect_request(request, fp, code, msg, headers, newurl)

    request = Request(url, headers={"User-Agent": "PlasmaAudioVisualizer/3.0"})
    with build_opener(SameHostRedirect()).open(request, timeout=5) as response:
        return response.read(limit + 1)


def _favicon_format(data):
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return ".png"
    if data.startswith(b"\x00\x00\x01\x00"):
        return ".ico"
    return ""


def favicon(host):
    """Discover and cache the playing website's own favicon by hostname."""
    host = _favicon_host(host)
    if not host:
        return {"status": "unsupported"}
    directory = (
        Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
        / "plasma-audio-visualizer"
        / "favicons"
    )
    for suffix in (".png", ".ico"):
        cache = directory / (host + suffix)
        if cache.is_file() and cache.stat().st_size > 0:
            return {"status": "ready", "url": cache.as_uri()}

    home = f"https://{host}/"
    hosts = {host, host[4:] if host.startswith("www.") else "www." + host}

    def try_candidates(candidates):
        for href in candidates[:8]:
            url = urljoin(home, href)
            parts = urlsplit(url)
            if parts.scheme != "https" or parts.hostname not in hosts:
                continue
            try:
                data = _fetch_favicon_bytes(url, host, 128 * 1024)
            except (OSError, ValueError):
                continue
            suffix = _favicon_format(data) if len(data) <= 128 * 1024 else ""
            if suffix:
                return data, suffix
        return b"", ""

    data, suffix = try_candidates(["/favicon.ico"])
    if not suffix:
        try:
            page = _fetch_favicon_bytes(home, host, 256 * 1024)
            links = IconLinks()
            links.feed(page.decode("utf-8", errors="ignore"))
            candidates = sorted(
                links.hrefs, key=lambda href: 0 if ".png" in href.lower() else 1
            )
            data, suffix = try_candidates(candidates)
        except (OSError, ValueError):
            pass
    if not suffix:
        return {"status": "error"}

    cache = directory / (host + suffix)
    directory.mkdir(parents=True, exist_ok=True)
    temporary = cache.with_suffix(f".{os.getpid()}.tmp")
    temporary.write_bytes(data)
    temporary.replace(cache)
    return {"status": "ready", "url": cache.as_uri()}


def info(artist, album):
    artist, album = artist.strip()[:240], album.strip()[:240]
    if not artist:
        return {"status": "empty"}
    key = hashlib.sha256(json.dumps([artist, album]).encode()).hexdigest()
    cache = (
        Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
        / "plasma-audio-visualizer"
        / "info"
        / (key + ".json")
    )
    try:
        if time.time() - cache.stat().st_mtime < 86400:
            return json.loads(cache.read_text())
    except (OSError, ValueError):
        pass
    result = {"status": "empty"}
    failed = False
    if album:
        # Quoted Lucene terms; do not let titles become search operators.
        def escape(s):
            return re.sub(r'([+\-!(){}\[\]^"~*?:\\/])', r"\\\1", s)

        query = f'artist:"{escape(artist)}" AND releasegroup:"{escape(album)}"'
        try:
            data = get_json(
                "https://musicbrainz.org/ws/2/release-group/?"
                + urlencode({"query": query, "fmt": "json", "limit": 5})
            )
            matches = [
                r
                for r in data.get("release-groups", [])
                if r.get("title", "").casefold() == album.casefold()
                and any(
                    c.get("artist", {}).get("name", "").casefold() == artist.casefold()
                    for c in r.get("artist-credit", [])
                    if isinstance(c, dict)
                )
            ]
            if len(matches) == 1:
                release = matches[0]
                result.update(
                    year=release.get("first-release-date", "")[:4],
                    genres=[t["name"] for t in release.get("tags", [])[:8]],
                    albumUrl="https://musicbrainz.org/release-group/" + release["id"],
                )
        except (OSError, ValueError, KeyError):
            failed = True
    try:
        data = get_json(
            "https://en.wikipedia.org/w/api.php?"
            + urlencode(
                {
                    "action": "query",
                    "format": "json",
                    "redirects": 1,
                    "prop": "extracts|pageprops|info",
                    "inprop": "url",
                    "exintro": 1,
                    "explaintext": 1,
                    "exchars": 1200,
                    "titles": artist,
                }
            )
        )
        pages = list(data.get("query", {}).get("pages", {}).values())
        for page in pages:
            extract = page.get("extract", "")
            # Reject disambiguation and unrelated namesakes rather than guessing.
            if "disambiguation" not in page.get("pageprops", {}) and re.search(
                r"\b(singer|musician|band|rapper|composer|songwriter|musical|record producer|DJ)\b",
                extract,
                re.I,
            ):
                result.update(summary=extract, artistUrl=page.get("fullurl", ""))
                break
    except (OSError, ValueError):
        failed = True
    result["status"] = (
        "ready"
        if result.get("summary") or result.get("albumUrl")
        else "error"
        if failed
        else "empty"
    )
    # Successful and negative lookups are cached; temporary failures remain retryable.
    if not failed:
        try:
            cache.parent.mkdir(parents=True, exist_ok=True)
            temporary = cache.with_suffix(f".{os.getpid()}.tmp")
            temporary.write_text(json.dumps(result))
            temporary.replace(cache)
        except OSError:
            pass
    return result


def main():
    try:
        mode, payload = sys.argv[1:3]
        data = json.loads(payload)
        if mode == "info":
            result = info(data.get("artist", ""), data.get("album", ""))
        elif mode == "favicon":
            result = favicon(data.get("host", ""))
        else:
            service = resolve_player(data)
            result = (
                queue(service)
                if mode == "queue"
                else {
                    "status": "ready",
                    "metadata": prop(service, ROOT + ".Player", "Metadata"),
                }
            )
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError):
        result = {"status": "error", "tracks": []}
    print(json.dumps(result))


if __name__ == "__main__":
    main()
