pragma Singleton
import QtQuick

// Diagnostic A/B switches for GPU memory reports (docs/gpu-memory-debugging.md,
// tools/awv-ab.sh). Read once from AWV_GPU_DEBUG in plasmashell's environment,
// e.g. "layers,sources" or "all":
//   layers  - no layer.enabled / MultiEffect; take the software-renderer fallbacks
//   sources - no ShaderEffectSource (backdrop blur, cover reflection)
//   shaders - Canvas instead of the WaveShader / OrbitShader ShaderEffects
// Hosts call apply() with the variable's value; nothing else reads it.
QtObject {
    property bool noLayers: false
    property bool noSources: false
    property bool noShaders: false

    function apply(value) {
        const flags = String(value ?? "").toLowerCase().split(/[\s,]+/);
        const all = flags.includes("all");
        noLayers = all || flags.includes("layers");
        noSources = all || flags.includes("sources");
        noShaders = all || flags.includes("shaders");
        if (noLayers || noSources || noShaders)
            console.warn("audio-wave-visualizer: AWV_GPU_DEBUG layers=" + noLayers + " sources=" + noSources + " shaders=" + noShaders);
    }

    // printf rather than printenv: an unset variable still returns (empty) stdout.
    readonly property string command: "printf 'awv-gpu-debug:%s' \"${AWV_GPU_DEBUG-}\""
    function handle(source, data) {
        if (source !== command)
            return false;
        const out = String(data?.stdout ?? "");
        apply(out.startsWith("awv-gpu-debug:") ? out.slice(14) : "");
        return true;
    }
}
