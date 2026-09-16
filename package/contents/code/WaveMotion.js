.pragma library
.import "WaveMath.js" as WaveMath

// Host-owned state; advancing twice at the same timestamp is a no-op.
function random(state) {
    state._seed = (Math.imul(state._seed, 1664525) + 1013904223) | 0;
    return (state._seed >>> 0) / 4294967296;
}

function reset(state) {
    state.beatPulse = 0;
    state._previousLevels = [];
    if (state.peaks.length)
        state.peaks = [];
    if (state.particles.length)
        state.particles = [];
    if (state.ripples.length)
        state.ripples = [];
    state._lastFrame = -1;
    state._seed = state.randomSeed;
}

function advance(state) {
    if (state._destroying || !state.active || state.frameTime === state._lastFrame || state.width <= 0 || state.height <= 0)
        return;
    // Scale motion to elapsed audio time, independent of host frame rate.
    const step = state._lastFrame < 0 ? 1 : Math.max(0, Math.min(6, (state.frameTime - state._lastFrame) * 0.06));
    state._lastFrame = state.frameTime;
    const n = WaveMath.count(state.numBars, state.width, state.style);
    const levels = WaveMath.levels(state.bars, n, state.maxRange);
    if (state.style === 17) {
        state.beatPulse = state.reducedMotion ? 0 : state.attack ? 1 : state.beatPulse * Math.exp(-step / 9);
    } else if (state.style === 6) {
        state.peaks = levels.map((value, i) => Math.max(value, (state.peaks[i] || 0) - 0.01 * step));
    } else if (state.style === 14 && !state.reducedMotion) {
        const next = [];
        const slot = state.width / n;
        for (const p of state.particles) {
            const life = p.life - 0.025 * step;
            if (life > 0)
                next.push({
                    x: p.x,
                    y: p.y + p.vy * step,
                    vy: p.vy,
                    r: p.r,
                    life: life
                });
        }
        for (let i = 0; i < n && next.length < 32; i++) {
            if (random(state) < 1 - Math.pow(1 - levels[i] * 0.22, step)) {
                const x = (i + 0.5) * slot + (random(state) - 0.5) * slot;
                const y = state.height / 2 + (random(state) - 0.5) * levels[i] * state.height;
                const vy = -(0.2 + random(state) * 0.8) * (1 + levels[i]);
                const r = 0.6 + random(state) * 1.4 * (state.lineWidth / 1.8);
                next.push({
                    x: x,
                    y: y + vy * step,
                    vy: vy,
                    r: r,
                    life: Math.max(0, 1 - 0.025 * step)
                });
            }
        }
        if (state.particles.length || next.length)
            state.particles = next;
    } else if (state.style === 21 && !state.reducedMotion) {
        const next = [];
        const slot = state.width / n;
        for (const p of state.particles) {
            const life = p.life - 0.025 * step;
            const turbulence = Math.sin(p.y * .055 + state.frameTime * .002 + p.x * .023) * .035;
            const vx = ((p.vx || 0) + turbulence * step) * Math.pow(.992, step);
            const vy = p.vy + .018 * step;
            const x = p.x + vx * step, y = p.y + vy * step;
            if (life > 0 && x >= -8 && x <= state.width + 8 && y >= -8 && y <= state.height + 8)
                next.push({
                    x: x,
                    y: y,
                    vx: vx,
                    vy: vy,
                    r: p.r,
                    life: life
                });
        }
        for (let i = 0; i < n && next.length < 32; i++) {
            const rise = Math.max(0, levels[i] - (state._previousLevels[i] || 0));
            if (levels[i] > .12 && random(state) < 1 - Math.pow(1 - Math.min(.8, levels[i] * .07 + rise * .8 + (state.attack ? .2 : 0)), step)) {
                const x = (i + 0.5) * slot + (random(state) - 0.5) * slot;
                const y = state.height * .82 - levels[i] * state.height * .55;
                const vy = -(0.2 + random(state) * 0.8) * (1 + levels[i]);
                const r = 0.6 + random(state) * 1.4 * (state.lineWidth / 1.8);
                next.push({
                    x: x,
                    vx: (random(state) - .5) * (1 + levels[i] * 2),
                    y: y + vy * step,
                    vy: vy,
                    r: r,
                    life: Math.max(0, 1 - 0.025 * step)
                });
            }
        }
        state._previousLevels = levels;
        if (state.particles.length || next.length)
            state.particles = next;
    } else if (state.style === 15 && !state.reducedMotion) {
        const next = [];
        for (const ripple of state.ripples) {
            const age = ripple.age + 0.03 * step;
            if (age < 1)
                next.push({
                    x: ripple.x,
                    age: age
                });
        }
        // Hosts supply onset pulses rather than a held beat.
        if (state.attack && state.energy > 0.5 && next.length < 4)
            next.push({
                x: random(state) * state.width,
                age: 0.03 * step
            });
        if (state.ripples.length || next.length)
            state.ripples = next;
    }
}
