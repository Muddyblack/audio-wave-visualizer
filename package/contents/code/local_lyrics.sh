#!/usr/bin/env bash
exec python3 "${BASH_SOURCE[0]%/*}/local_lyrics.py" "$@"
