#!/usr/bin/env bash
if [[ $1 == --online ]]; then
    shift
    exec python3 "${BASH_SOURCE[0]%/*}/online_lyrics.py" "$@"
fi
exec python3 "${BASH_SOURCE[0]%/*}/local_lyrics.py" "$@"
