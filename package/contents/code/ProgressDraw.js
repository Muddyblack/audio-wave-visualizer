.pragma library
.import "WaveMath.js" as WaveMath
.import "WaveDraw.js" as WaveDraw
.import "ColourStyle.js" as ColourStyle

function seedHeights(key, n) {
    let seed = 0;
    for (let c = 0; c < key.length; c++) seed = (seed * 31 + key.charCodeAt(c)) >>> 0;
    const out = [];
    for (let i = 0; i < n; i++) {
        seed = (seed * 1664525 + 1013904223) >>> 0;
        out.push(.15 + (seed >>> 16) / 65535 * .85 * Math.sin((n > 1 ? i / (n - 1) : 0) * Math.PI));
    }
    return out;
}

// Canvas progress styles. Hosts own playback, repaint scheduling and easing.
function draw(ctx, o) {
    const w = o.width, h = o.height, px = o.playhead;
    if (w <= 0 || h <= 0) return;
    const wave = WaveMath.color(o.waveColor), text = WaveMath.color(o.textColor);
    const control = WaveMath.color(o.controlColor), stops = o.stops || [];
    if (o.style === 4) {
        const heights = o.heights || [];
        for (let i = 0; i < heights.length; i++) {
            const x = i * 5, played = x + 1.5 < px;
            const bh = Math.max(2, heights[i] * h * (played ? 1 : .45)), y = (h - bh) / 2;
            ctx.fillStyle = played ? (stops.length ? ColourStyle.sample(stops, x / Math.max(1, px)) : WaveDraw.alpha(wave, .9)) : WaveDraw.alpha(text, .25);
            ctx.beginPath();
            if (bh > 3) {
                ctx.moveTo(x + 1.5, y);
                ctx.arc(x + 1.5, y + 1.5, 1.5, Math.PI, 0);
                ctx.lineTo(x + 3, y + bh - 1.5);
                ctx.arc(x + 1.5, y + bh - 1.5, 1.5, 0, Math.PI);
                ctx.closePath();
            } else ctx.arc(x + 1.5, y + bh / 2, 1.5, 0, Math.PI * 2);
            ctx.fill();
        }
        if (o.showPlayhead) {
            ctx.fillStyle = WaveDraw.alpha(control, .95);
            ctx.fillRect(px - 1, 0, 2, h);
        }
    } else if (o.style === 5) {
        ctx.lineWidth = 2;
        ctx.lineCap = "round";
        ctx.strokeStyle = stops.length ? WaveDraw.paintFor(ctx, stops, Math.max(1, px)) : o.startColor;
        ctx.beginPath();
        for (let x = 1; x <= px; x++) {
            const y = h / 2 + Math.sin(x * .38 - o.time * 6) * o.amplitude;
            if (x > 1) ctx.lineTo(x, y); else ctx.moveTo(x, y);
        }
        ctx.stroke();
        ctx.strokeStyle = WaveDraw.alpha(text, .25);
        ctx.beginPath();
        ctx.moveTo(Math.min(w - 1, px + 5), h / 2);
        ctx.lineTo(w - 1, h / 2);
        ctx.stroke();
        ctx.fillStyle = control;
        ctx.beginPath();
        WaveDraw.roundRect(ctx, px - 1.5, 0, 3, h, 1.5);
        ctx.fill();
    } else if (o.style === 7) {
        for (const played of [true, false]) {
            ctx.beginPath();
            const r = played ? 1.6 : 1.1;
            for (let x = 3; x < w; x += 6) {
                if ((x < px) !== played) continue;
                ctx.moveTo(x + r, h / 2);
                ctx.arc(x, h / 2, r, 0, Math.PI * 2);
            }
            ctx.fillStyle = played ? (stops.length ? WaveDraw.paintFor(ctx, stops, Math.max(1, px)) : wave) : WaveDraw.alpha(text, .3);
            ctx.fill();
        }
        ctx.fillStyle = control;
        ctx.beginPath();
        ctx.arc(Math.max(3, Math.min(w - 3, px)), h / 2, 3.2, 0, Math.PI * 2);
        ctx.fill();
    }
}
