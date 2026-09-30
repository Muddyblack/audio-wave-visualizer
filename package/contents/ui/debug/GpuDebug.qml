pragma Singleton
import QtQuick

// Diagnostic A/B switches for GPU memory reports (docs/gpu-memory-debugging.md,
// tools/awv-ab.sh). Set from the hidden gpuDebug config entry, empty by
// default, e.g. "layers,sources" or "all":
//   layers  - no layer.enabled / MultiEffect; take the software-renderer fallbacks
//   sources - no ShaderEffectSource (backdrop blur, cover reflection)
//   shaders - Canvas instead of the WaveShader / OrbitShader ShaderEffects
// main.qml calls apply() with the entry's value; nothing else reads it.
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
            console.warn("audio-wave-visualizer: gpuDebug layers=" + noLayers + " sources=" + noSources + " shaders=" + noShaders);
    }
}
