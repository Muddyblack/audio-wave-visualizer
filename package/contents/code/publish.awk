# Stream CAVA frames with buffered reads. Bash's read builtin consumes pipes
# byte by byte, which gets costly at high bar counts and frame rates.
# The feeder handles probing/status once, then replaces its pipeline reader
# with this single process; no per-frame subprocesses or extra wake timers.
# feeder.sh only runs it with an awk that has systime(), and gives mawk
# -W interactive so each frame is handled as soon as it arrives.
BEGIN {
    bars_path = ENVIRON["AUDIO_WAVE_RUN"] "/bars"
    frame_path = ENVIRON["AUDIO_WAVE_RUN"] "/frame.ini"
    previous = ENVIRON["AUDIO_WAVE_PREVIOUS"]
    previous_second = ENVIRON["AUDIO_WAVE_FRAME_SECOND"] + 0
}

length($0) {
    now = systime()
    if ($0 != previous) {
        printf "%s", $0 > bars_path
        close(bars_path)
        previous = $0
    } else if (now == previous_second) {
        next
    }

    # Keep fresh even when the waveform is constant. A quoted semicolon
    # payload stays a QString in QSettings; original readers accept it too.
    printf "t=%d\nv=\"%s\"\nprotocol=2\n", now, $0 > frame_path
    close(frame_path)
    previous_second = now
}
