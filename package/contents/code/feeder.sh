#!/usr/bin/env bash
# Runs cava in the background and mirrors its latest frame into $RUN/bars,
# which the QML side polls.
#
# cava is built with a fixed set of input backends and distros do not agree on
# which ones: a `method` that was not compiled in, or a sound server that is not
# running, makes cava either exit immediately or sit there emitting nothing. So
# instead of hardcoding pipewire we probe candidates until one actually produces
# a frame, and record the outcome in $RUN/status so the widget can say what went
# wrong instead of drawing a flat line forever.
set -u

BARS="${1:-24}"
FRAMERATE="${2:-60}"
SENSITIVITY="${3:-100}"
NOISE_REDUCTION="${4:-0.77}"
INPUT_METHOD="${5:-auto}"

RUN="${XDG_RUNTIME_DIR:-/tmp}/audio-wave-widget"
mkdir -p "$RUN"

CONF="$RUN/cava.conf"
STATUS="$RUN/status"
LOG="$RUN/cava.log"
MARKER="$RUN/.first-frame"
REMEMBERED="$RUN/input-method"
PUBLISHER="${BASH_SOURCE[0]%/*}/publish.awk"
[[ "${BASH_SOURCE[0]}" == */* ]] || PUBLISHER="./publish.awk"

# How long a backend gets to produce its first frame before we call it dead.
# cava emits a frame every 1/framerate second even in silence, so no output
# after a few seconds means the backend never came up.
PROBE_TIMEOUT=5

# Backends tried, in order, when the method is left on "auto". alsa comes last
# because its default source (hw:Loopback,1) only exists if snd-aloop is loaded.
AUTO_METHODS="pipewire pulse alsa"

write_status() {
  printf '%s\n' "$*" >"$STATUS.tmp" && mv -f "$STATUS.tmp" "$STATUS"
  # QSettings readers avoid spawning cat for healthy status polls. Keep the
  # original file for older widget instances sharing this feeder.
  printf 'v="%s"\n' "$*" >"$RUN/status.ini.tmp" && mv -f "$RUN/status.ini.tmp" "$RUN/status.ini"
}

exec 9>"$RUN/lock"
if ! flock -n 9; then
  exit 0
fi

# Lets the widget stop this feeder, not just cava: when cava dies during a
# backend probe the feeder moves on to the next backend with its old settings
# and keeps the lock, so a restart with new settings would never start.
PIDFILE="$RUN/feeder.pid"
printf '%s\n' "$$" >"$PIDFILE"

# Ensure clean termination of the background cava process. The pkill pattern is
# pinned to our own config path so a cava the user started themselves survives.
cleanup() {
  pkill -P $$ >/dev/null 2>&1
  pkill -f "cava -p $CONF" >/dev/null 2>&1
  rm -f "$PIDFILE"
  return 0
}
trap cleanup EXIT

# Keep the original transport for installed widgets. The separate INI frame
# lets newer readers avoid a process per poll. Its timestamp detects old
# feeders taking over the lock without refreshing frame.ini. Identical frames
# need no bars rewrite; refresh only the INI heartbeat once per second so a
# quiet backend still passes the reader's two-second freshness check. Changed
# frames are always published immediately, at the configured full frame rate.
# EPOCHREALTIME uses the locale's decimal separator, so under e.g. de_DE it
# reads "1789074907,765593"; QSettings would parse that comma as a list, the
# reader's freshness check would always fail and it would fall back to one
# `cat` per frame. Force the dot.
last_frame=""
last_frame_second=-1
write_frame() {
  if [[ "$1" != "$last_frame" ]]; then
    printf '%s' "$1" >"$RUN/bars"
    last_frame="$1"
  elif [[ "$EPOCHSECONDS" == "$last_frame_second" ]]; then
    return
  fi
  last_frame_second="$EPOCHSECONDS"
  # Quote the semicolon string for QSettings: unlike comma-separated values,
  # this stays a string instead of constructing a QVariantList on every poll.
  printf 't=%s\nv="%s"\nprotocol=2\n' "${EPOCHREALTIME/,/.}" "$last_frame" >"$RUN/frame.ini"
}

printf -v zeros '%*s' "$BARS" ''
zeros="${zeros// /0;}"
write_frame "$zeros"

# Reported alongside "no-cava" so the widget can name the actual install
# command. Binary presence beats the /etc/os-release ID: derivatives keep their
# parent's package manager but change the ID, and there are far more
# derivatives than package managers.
detect_pkg_manager() {
  local mgr
  for mgr in apt-get dnf pacman zypper apk xbps-install emerge nix-env; do
    if command -v "$mgr" >/dev/null 2>&1; then
      printf '%s' "$mgr"
      return
    fi
  done
  printf 'unknown'
}

if ! command -v cava >/dev/null 2>&1; then
  write_status "error no-cava $(detect_pkg_manager)"
  exit 0
fi

: >"$LOG"

# awk reads the pipe in blocks instead of Bash's byte-at-a-time `read`, but not
# every awk suits a live stream: mawk (Debian/Ubuntu's default) fills its whole
# read buffer before handling a line unless run with -W interactive, and
# one-true-awk has no systime(). Without a usable awk the Bash loop keeps
# publishing. The choice is recorded for doctor.sh.
AWK=()
if awk 'BEGIN { exit !(systime() > 0) }' </dev/null >/dev/null 2>&1; then
  AWK=(awk)
  [[ "$(awk -W version 2>/dev/null </dev/null)" == mawk* ]] && AWK+=(-W interactive)
fi
printf '%s\n' "${AWK[*]:-bash}" >"$RUN/publisher"

write_conf() {
  local method="$1"
  local source_line=""
  # alsa/sndio want a device name, not "auto" — leave cava on its own default.
  case "$method" in
  pipewire | pulse) source_line="source = auto" ;;
  esac

  cat <<EOF >"$CONF"
[general]
bars = $BARS
framerate = $FRAMERATE
autosens = 1
sensitivity = $SENSITIVITY

[input]
method = $method
$source_line

[output]
method = raw
channels = mono
mono_option = average
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 1000
bar_delimiter = 59
frame_delimiter = 10

[smoothing]
noise_reduction = $NOISE_REDUCTION
EOF
}

# The first frame is handled in Bash so probing and status stay here. A usable
# awk then takes over the pipe (see AWK above); otherwise this loop continues.
publish_frames() {
  local method="$1"
  local line
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    # Direct write, no tmp+rename: at framerate this forked an external mv
    # process per frame (up to 4M/day at 60fps). A poll landing in the
    # microsecond truncate/write gap sees an empty file; Visualizer.qml's
    # handleData() already no-ops on an empty read, so that poll just keeps
    # the previous frame instead of updating.
    write_frame "$line"
    [ -e "$MARKER" ] && continue
    : >"$MARKER"
    printf '%s\n' "$method" >"$REMEMBERED"
    write_status "ok $method"
    ((${#AWK[@]})) || continue
    # Replacing this loop is the point: awk reads the rest of the stream.
    # shellcheck disable=SC2093
    AUDIO_WAVE_RUN="$RUN" AUDIO_WAVE_PREVIOUS="$line" AUDIO_WAVE_FRAME_SECOND="$last_frame_second" \
      exec "${AWK[@]}" -f "$PUBLISHER"
  done
}

# Runs cava with one input method. Returns 0 if it produced at least one frame
# (i.e. the backend works and cava has since exited), 1 if the method is a dud.
run_method() {
  local method="$1"
  write_conf "$method"
  rm -f "$MARKER"

  cava -p "$CONF" 2>>"$LOG" | publish_frames "$method" 2>>"$LOG" &
  local pipeline=$!

  # Watchdog: a backend that hangs without erroring out would otherwise block
  # the probe forever. It closes the lock fd: its sleep can outlive a stopped
  # feeder by up to PROBE_TIMEOUT seconds and would block the replacement.
  (
    sleep "$PROBE_TIMEOUT"
    [ -e "$MARKER" ] && exit 0
    pkill -f "cava -p $CONF" >/dev/null 2>&1
    pkill -P "$pipeline" >/dev/null 2>&1
    kill "$pipeline" >/dev/null 2>&1
    return 0
  ) 9>&- &
  local watchdog=$!

  wait "$pipeline" >/dev/null 2>&1
  kill "$watchdog" >/dev/null 2>&1
  wait "$watchdog" >/dev/null 2>&1

  [ -e "$MARKER" ]
}

methods=""
case "$INPUT_METHOD" in
auto | "")
  # Whatever worked last time goes first, so a restart does not re-probe.
  remembered=""
  if [ -r "$REMEMBERED" ]; then
    IFS= read -r remembered <"$REMEMBERED" || :
  fi
  methods="$remembered"
  for m in $AUTO_METHODS; do
    [ "$m" = "$remembered" ] || methods="${methods:+$methods }$m"
  done
  ;;
*)
  methods="$INPUT_METHOD"
  ;;
esac

tried=""
for m in $methods; do
  write_status "probing $m"
  if run_method "$m"; then
    # The backend worked and cava has now exited (sound server restart, device
    # switch, ...). Report it and let the widget's heartbeat respawn us.
    write_status "error cava-exited $m"
    exit 0
  fi
  tried="${tried:+$tried,}$m"
done

write_status "error no-backend ${tried:-none}"
exit 0
