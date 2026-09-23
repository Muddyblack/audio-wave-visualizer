#!/usr/bin/env bash
# The Nix package wraps this entry point with Python and busctl on PATH.
if [[ "${1:-}" == --check ]]; then
  for tool in python3 busctl; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf '%s: found\n' "$tool"
    else
      printf '%s: missing\n' "$tool"
    fi
  done
  distro=unknown
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    distro="${ID:-unknown}"
  fi
  printf 'distro: %s\n' "$distro"
  exit 0
fi
exec python3 "${BASH_SOURCE[0]%/*}/media_metadata.py" "$@"
