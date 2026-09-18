.pragma library
.import "WaveMotion.js" as Motion

// Shared orbit sampling, geometry and bounded spark simulation.
function values(state) {
    const out = [];
    const count = state.bars.length;
    for (let i = 0; i < state.half; i++) {
        const index = count > 1 ? Math.round(i * (count - 1) / (state.half - 1)) : 0;
        out.push(state.drawing && state.maxRange > 0 ? Math.min(1, (state.bars[index] || 0) / state.maxRange) : 0);
    }
    return out;
}

function geometry(state) {
    const radius = Math.min(state.width, state.height) / 2;
    const inner = radius * state.coverRatio + 4;
    return {
        radius: radius,
        inner: inner,
        reach: Math.max(2, (radius - inner - 2) * 1.3 * state.orbitReach)
    };
}

function advance(state) {
    if (!state.sparks || !state.drawing) {
        if (state.particles.length)
            state.particles = [];
        state._lastFrame = -1;
        return;
    }
    if (state.visualFrameTime === state._lastFrame)
        return;
    // Scale to elapsed audio time.
    const step = state._lastFrame < 0 ? 1 : Math.max(0, Math.min(6, (state.visualFrameTime - state._lastFrame) * 0.06));
    state._lastFrame = state.visualFrameTime;
    const g = geometry(state), v = values(state), n = state.half * 2, next = [];
    for (const p of state.particles) {
        const life = p.life - 0.02 * step, r = p.r + p.v * step;
        if (life > 0 && r < g.radius)
            next.push({
                a: p.a,
                r: r,
                v: p.v,
                life: life,
                s: p.s
            });
    }
    // Start at a random spoke so the cap does not favour one side.
    const start = Math.floor(Motion.random(state) * n);
    for (let k = 0; k < n && next.length < 32; k++) {
        const j = (start + k) % n, level = v[j < state.half ? j : n - 1 - j];
        if (Motion.random(state) < 1 - Math.pow(1 - level * 0.12, step))
            next.push({
                a: j / n * Math.PI * 2 + state.ringRotation - Math.PI / 2 + (Motion.random(state) - 0.5) * 0.1,
                r: g.inner + 3,
                v: (0.4 + Motion.random(state)) * (1 + level),
                life: 1,
                s: 0.6 + Motion.random(state) * 1.3
            });
    }
    if (state.particles.length || next.length)
        state.particles = next;
}
