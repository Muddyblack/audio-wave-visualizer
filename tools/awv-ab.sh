#!/bin/bash
# Find which GPU path plasmashell memory growth follows (see
# docs/gpu-memory-debugging.md). Restarts plasmashell once per gpuDebug
# switch and once on Vulkan, measures memory while the settings window is
# open, and writes ~/awv-ab.txt.
set -u
out=~/awv-ab.txt
seconds=${AWV_AB_SECONDS:-20}

rss() { awk '/VmRSS/{print int($2 / 1024)}' "/proc/$(pgrep -xo plasmashell)/status"; }
reset_env() { systemctl --user unset-environment QSG_RHI_BACKEND; }
# Writes the widget's hidden gpuDebug entry on every instance; it applies live.
set_debug() {
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
        for (const c of desktops().concat(panels()))
            for (const w of c.widgets('org.muddyblack.plasmaAudioVisualizer')) {
                w.currentConfigGroup = ['General'];
                w.writeConfig('gpuDebug', '$1');
            }" > /dev/null
}

{
    echo "== system"
    plasmashell --version 2>/dev/null
    qtpaths6 --qt-version 2>/dev/null | sed 's/^/Qt /'
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null
    echo "session: ${XDG_SESSION_TYPE:-unknown}"
    echo "== runs (${seconds}s each, settings window open)"
} > "$out"

run() {
    local name=$1 debug=${2-} env=${3-}
    reset_env
    [ -n "$env" ] && systemctl --user set-environment "$env"
    local since
    since=$(date "+%Y-%m-%d %H:%M:%S")
    systemctl --user restart plasma-plasmashell
    sleep 8
    set_debug "$debug"
    echo
    read -rp ">>> [$name] Open the visualizer settings window, then press Enter (keep it open) "
    local start end switch
    start=$(rss)
    for _ in $(seq "$seconds"); do sleep 1; printf '.'; done
    end=$(rss)
    echo
    switch=$(journalctl --user -b --since "$since" 2>/dev/null | grep -o 'gpuDebug layers.*' | tail -1)
    echo "$name: start ${start} MB, after ${seconds}s ${end} MB, growth $((end - start)) MB ${switch:+($switch)}" | tee -a "$out"
    read -rp "Close the settings window, then press Enter "
}

run baseline
run all all
run layers layers
run sources sources
run shaders shaders
run vulkan "" QSG_RHI_BACKEND=vulkan

reset_env
set_debug ""
systemctl --user restart plasma-plasmashell
echo
echo "Done, plasmashell is back to normal. Please post the contents of $out"
