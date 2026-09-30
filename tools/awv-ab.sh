#!/bin/bash
# Issue #10: plasmashell memory while the visualizer animates.
# Restarts plasmashell once per run (see docs/gpu-memory-debugging.md),
# measures memory while the settings window is open, and writes ~/awv-ab.txt.
# The first run is the shipped behaviour (Canvas on NVIDIA under OpenGL); the
# gl-shaders runs turn the GPU shaders back on to look for a setting that
# keeps them from growing.
set -u
out=~/awv-ab.txt
seconds=20

rss() { awk '/VmRSS/{print int($2 / 1024)}' "/proc/$(pgrep -xo plasmashell)/status"; }
vars=(AWV_GPU_DEBUG QSG_RHI_BACKEND QSG_RENDER_LOOP QSG_RHI_DISABLE_DISK_CACHE __GL_THREADED_OPTIMIZATIONS __GL_SHADER_DISK_CACHE)
reset_env() { systemctl --user unset-environment "${vars[@]}"; }

{
    echo "== system"
    plasmashell --version 2>/dev/null
    qtpaths6 --qt-version 2>/dev/null | sed 's/^/Qt /'
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null
    echo "session: ${XDG_SESSION_TYPE:-unknown}"
    echo "== runs (${seconds}s each, settings window open)"
} > "$out"

run() {
    local name=$1
    shift
    reset_env
    [ $# -gt 0 ] && systemctl --user set-environment "$@"
    local since
    since=$(date "+%Y-%m-%d %H:%M:%S")
    systemctl --user restart plasma-plasmashell
    sleep 8
    echo
    read -rp ">>> [$name] Open the visualizer settings window, then press Enter (keep it open) "
    local start end switch
    start=$(rss)
    for _ in $(seq "$seconds"); do sleep 1; printf '.'; done
    end=$(rss)
    echo
    # On NVIDIA the widget logs its Canvas fallback, which applies to OpenGL only.
    if [[ " $* " != *" QSG_RHI_BACKEND=vulkan "* ]] &&
        journalctl --user -b --since "$since" 2>/dev/null | grep -q 'drawing the visualizer with Canvas'; then
        switch=canvas
    else
        switch=shaders
    fi
    echo "$name: start ${start} MB, after ${seconds}s ${end} MB, growth $((end - start)) MB ($switch)" | tee -a "$out"
    read -rp "Close the settings window, then press Enter "
}

run fix
run gl-shaders AWV_GPU_DEBUG=gl-shaders
run gl-shaders+basic-loop AWV_GPU_DEBUG=gl-shaders QSG_RENDER_LOOP=basic
run gl-shaders+no-qt-cache AWV_GPU_DEBUG=gl-shaders QSG_RHI_DISABLE_DISK_CACHE=1
run gl-shaders+no-threaded AWV_GPU_DEBUG=gl-shaders __GL_THREADED_OPTIMIZATIONS=0
run gl-shaders+no-nv-cache AWV_GPU_DEBUG=gl-shaders __GL_SHADER_DISK_CACHE=0
run vulkan QSG_RHI_BACKEND=vulkan

reset_env
systemctl --user restart plasma-plasmashell
echo
echo "Done, plasmashell is back to normal. Please post the contents of $out"
