#!/usr/bin/env python3
"""LRCLIB fallback for hosts whose Qt HTTPS transport fails."""

import json
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qsl, urlencode
from urllib.request import Request, urlopen


def fetch(query):
    # The host supplies metadata, never an arbitrary URL. Keep TLS verification.
    fields = {"track_name", "artist_name", "album_name", "duration"}
    query = urlencode([(k, v) for k, v in parse_qsl(query) if k in fields])
    request = Request(
        "https://lrclib.net/api/get?" + query,
        headers={"User-Agent": "plasma-audio-visualizer"},
    )
    try:
        with urlopen(request, timeout=12) as response:
            payload = response.read(2 * 1024 * 1024 + 1)
            if len(payload) > 2 * 1024 * 1024:
                return {"status": 0}
            value = json.loads(payload)
            if not isinstance(value, dict):
                return {"status": 0}
            return {"status": 200, "body": value}
    except HTTPError as error:
        return {"status": error.code}
    except (URLError, OSError, ValueError):
        return {"status": 0}


if __name__ == "__main__":
    print(json.dumps(fetch(sys.argv[1]), ensure_ascii=True))
