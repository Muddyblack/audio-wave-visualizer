#!/usr/bin/env bash
# Separate wrapper so packaged hosts can supply Python and PipeWire on PATH.
exec python3 "${BASH_SOURCE[0]%/*}/stereo_capture.py" "$@"
