.pragma library

// Synthetic frames for both studio hosts; production audio comes from the feeder.
function bands(t) {
    const bass = Math.pow(.5 + .5 * Math.sin(t * 7.4), 7);
    return {bass: bass, mid: .5 + .5 * Math.sin(t * 1.3), high: .5 + .5 * Math.sin(t * 5.1 + 1), attack: bass > .86};
}
function spectrum(i, n, t) {
    const p = n > 1 ? i / (n - 1) : 0;
    const shape = .18 + .5 * Math.pow(Math.sin(p * Math.PI), .8);
    const wobble = .55 + .45 * Math.sin(t * 3.1 + i * .7) * Math.sin(t * 1.3 + i * .23);
    const low = p < .3 ? bands(t).bass * .35 * (1 - p / .3) : 0;
    return Math.min(1, shape * wobble + low);
}
function stereo(t) {
    return Array.from({length: 32}, (_, i) => [Math.sin(i / 31 * Math.PI * 4) * .75,
        Math.sin(i / 31 * Math.PI * 4 + Math.sin(t) * 1.4) * .75]);
}
