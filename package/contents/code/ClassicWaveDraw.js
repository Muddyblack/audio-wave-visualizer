.pragma library
.import "WaveDraw.js" as WaveDraw
.import "WaveMath.js" as WaveMath

// The original six styles, shared by QML Canvas and the browser preview.
// A host-owned cache retains colour conversions and vertical fill gradients.
function draw(ctx, options, cache) {
    const width = options.width, height = options.height, mid = height / 2;
    const levels = options.levels, n = levels.length, vtype = options.type;
    if (n < 2 || width <= 0 || height <= 0) return;
    const lineWidth = options.lineWidth, fillWave = options.fill;
    const colorStops = options.stops, waveColor = colorStops[0];
    const _colored = options.colored;
    const colorKey = String(waveColor);
    if (cache.colorKey !== colorKey || cache.height !== height) {
        cache.colorKey = colorKey;
        cache.height = height;
        cache.fillAbove = null;
        cache.fillBelow = null;
        cache.colors = {};
        for (const opacity of [0, .02, .35, .38, .55, .75, .92, .95, 1])
            cache.colors[opacity] = WaveDraw.alpha(WaveMath.color(waveColor), opacity);
    }
    const _drawCache = cache;
    const _color00 = cache.colors[0], _color02 = cache.colors[.02];
    const _color35 = cache.colors[.35], _color38 = cache.colors[.38];
    const _color55 = cache.colors[.55], _color75 = cache.colors[.75];
    const _color92 = cache.colors[.92], _color95 = cache.colors[.95], _color100 = cache.colors[1];
    const paint = _colored ? WaveDraw.paintFor(ctx, colorStops, width) : waveColor;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    // ═════════════════════════════════════════════════════
    // TYPE 0 — Smooth Wave (mirrored bezier)
    // ═════════════════════════════════════════════════════
    if (vtype === 0) {
        const step0 = width / (n - 1);
        ctx.lineWidth = lineWidth;
        ctx.strokeStyle = paint;

        if (fillWave && !_drawCache.fillAbove) {
            const amp = height * 0.42;
            const above = ctx.createLinearGradient(0, mid, 0, mid - amp);
            const below = ctx.createLinearGradient(0, mid, 0, mid + amp);
            above.addColorStop(0.0, _color38);
            above.addColorStop(1.0, _color02);
            below.addColorStop(0.0, _color38);
            below.addColorStop(1.0, _color02);
            _drawCache.fillAbove = above;
            _drawCache.fillBelow = below;
        }

        function plot0(sign) {
            ctx.beginPath();
            const amp = height * 0.42;
            let prevX = 0;
            let prevY = mid + sign * levels[0] * amp;
            ctx.moveTo(prevX, prevY);
            for (let i = 1; i < n; i++) {
                const v = levels[i];
                const x = i * step0;
                const y = mid + sign * v * amp;
                const cpX = (prevX + x) / 2;
                ctx.bezierCurveTo(cpX, prevY, cpX, y, x, y);
                prevX = x;
                prevY = y;
            }
            ctx.stroke();

            if (fillWave) {
                ctx.lineTo(width, mid);
                ctx.lineTo(0, mid);
                ctx.closePath();
                ctx.fillStyle = sign < 0 ? _drawCache.fillAbove : _drawCache.fillBelow;
                ctx.fill();
            }
        }
        plot0(-1);
        plot0(1);

        // ═════════════════════════════════════════════════════
        // TYPE 1 — Rounded Bars (upward bars from bottom)
        // ═════════════════════════════════════════════════════
    } else if (vtype === 1) {
        const totalW = width;
        const gap = Math.max(1, totalW / n * 0.25);
        const barW = Math.max(1, totalW / n - gap);
        const r = barW / 2;
        const amp1 = height * 0.88;
        ctx.lineWidth = 0;
        ctx.strokeStyle = "transparent";

        for (let i = 0; i < n; i++) {
            const v = levels[i];
            const bh = Math.max(2, v * amp1);
            const x = i * (barW + gap) + gap / 2;
            const y = height - bh;

            // gradient fill per bar
            const g = ctx.createLinearGradient(0, y, 0, height);
            const barColor = _colored ? WaveDraw.colorAt(colorStops, (x + barW / 2) / width) : waveColor;
            g.addColorStop(0.0, _colored ? WaveDraw.alpha(barColor, .95) : _color95);
            g.addColorStop(1.0, _colored ? WaveDraw.alpha(barColor, .35) : _color35);
            ctx.fillStyle = g;

            // rounded-top rectangle
            ctx.beginPath();
            if (bh > r * 2) {
                ctx.moveTo(x + r, y);
                ctx.arc(x + r, y + r, r, Math.PI, 0);
                ctx.lineTo(x + barW, height);
                ctx.lineTo(x, height);
                ctx.closePath();
            } else {
                ctx.arc(x + r, y + r, r, 0, Math.PI * 2);
            }
            ctx.fill();
        }

        // ═════════════════════════════════════════════════════
        // TYPE 2 — Mirror Bars (bars grow from centre up & down)
        // ═════════════════════════════════════════════════════
    } else if (vtype === 2) {
        const totalW2 = width;
        const gap2 = Math.max(1, totalW2 / n * 0.22);
        const barW2 = Math.max(1, totalW2 / n - gap2);
        const r2 = barW2 / 2;
        const amp2 = height * 0.44;

        for (let i = 0; i < n; i++) {
            const v = levels[i];
            const bh = Math.max(2, v * amp2);
            const x = i * (barW2 + gap2) + gap2 / 2;

            const g2 = ctx.createLinearGradient(0, mid - bh, 0, mid + bh);
            const barColor = _colored ? WaveDraw.colorAt(colorStops, (x + barW2 / 2) / width) : waveColor;
            g2.addColorStop(0.0, _colored ? WaveDraw.alpha(barColor, .35) : _color35);
            g2.addColorStop(0.5, _colored ? WaveDraw.alpha(barColor, .95) : _color95);
            g2.addColorStop(1.0, _colored ? WaveDraw.alpha(barColor, .35) : _color35);
            ctx.fillStyle = g2;

            // top half
            ctx.beginPath();
            if (bh > r2) {
                ctx.moveTo(x, mid);
                ctx.lineTo(x, mid - bh + r2);
                ctx.arc(x + r2, mid - bh + r2, r2, Math.PI, 0);
                ctx.lineTo(x + barW2, mid);
                ctx.closePath();
            } else {
                ctx.arc(x + r2, mid - r2, r2, 0, Math.PI * 2);
            }
            ctx.fill();

            // bottom half
            ctx.beginPath();
            if (bh > r2) {
                ctx.moveTo(x, mid);
                ctx.lineTo(x, mid + bh - r2);
                ctx.arc(x + r2, mid + bh - r2, r2, Math.PI, 2 * Math.PI);
                ctx.lineTo(x + barW2, mid);
                ctx.closePath();
            } else {
                ctx.arc(x + r2, mid + r2, r2, 0, Math.PI * 2);
            }
            ctx.fill();
        }

        // ═════════════════════════════════════════════════════
        // TYPE 3 — Tech Line (stepped segments with node dots)
        // ═════════════════════════════════════════════════════
    } else if (vtype === 3) {
        const step3 = width / (n - 1);
        const amp3 = height * 0.42;
        ctx.lineWidth = lineWidth;
        ctx.strokeStyle = paint;

        function drawTechLine(sign) {
            ctx.beginPath();
            for (let i = 0; i < n; i++) {
                const v = levels[i];
                const x = i * step3;
                const y = mid + sign * v * amp3;
                if (i === 0) {
                    ctx.moveTo(x, y);
                } else {
                    // horizontal then vertical — oscilloscope step look
                    ctx.lineTo(x - step3 * 0.5, mid + sign * levels[i - 1] * amp3);
                    ctx.lineTo(x - step3 * 0.5, y);
                    ctx.lineTo(x, y);
                }
            }
            ctx.stroke();

            // node dots at each sample
            for (let i = 0; i < n; i++) {
                const v = levels[i];
                const x = i * step3;
                const y = mid + sign * v * amp3;
                ctx.beginPath();
                ctx.arc(x, y, 1.6, 0, Math.PI * 2);
                ctx.fillStyle = paint;
                ctx.fill();
            }
        }
        drawTechLine(-1);
        drawTechLine(1);

        // ═════════════════════════════════════════════════════
        // TYPE 4 — Floating Dots (soft radial blobs, lineWidth scales size)
        // ═════════════════════════════════════════════════════
    } else if (vtype === 4) {
        const step4 = width / n;
        const amp4 = height * 0.42;
        // lineWidth (1–8) scales how big the dots get
        const maxR = Math.max(2, step4 * 0.28 * (lineWidth / 2.0));

        function drawDot4(cx, cy, dotR, color) {
            // solid bright core so it's always visible
            ctx.beginPath();
            ctx.arc(cx, cy, dotR * 0.45, 0, Math.PI * 2);
            ctx.fillStyle = _colored ? WaveDraw.alpha(color, .92) : _color92;
            ctx.fill();
            // soft glow halo
            const grad = ctx.createRadialGradient(cx, cy, dotR * 0.3, cx, cy, dotR);
            grad.addColorStop(0.0, _colored ? WaveDraw.alpha(color, .55) : _color55);
            grad.addColorStop(1.0, _colored ? WaveDraw.alpha(color, 0) : _color00);
            ctx.beginPath();
            ctx.arc(cx, cy, dotR, 0, Math.PI * 2);
            ctx.fillStyle = grad;
            ctx.fill();
        }

        for (let i = 0; i < n; i++) {
            const v = levels[i];
            const cx = i * step4 + step4 / 2;
            const dotR = Math.max(1.5, v * maxR);

            const dotColor = _colored ? WaveDraw.colorAt(colorStops, cx / width) : waveColor;
            drawDot4(cx, mid - v * amp4, dotR, dotColor);
            drawDot4(cx, mid + v * amp4, dotR, dotColor);
        }

        // ═════════════════════════════════════════════════════
        // TYPE 5 — Floating Dots Bold (outlined rings, high-contrast)
        // ═════════════════════════════════════════════════════
    } else if (vtype === 5) {
        const step5 = width / n;
        const amp5 = height * 0.42;
        const maxR5 = Math.max(2, step5 * 0.32);
        const strokeW = Math.max(0.8, lineWidth * 0.6);

        function drawRing(cx, cy, dotR, color) {
            // filled center (always punchy)
            ctx.beginPath();
            ctx.arc(cx, cy, Math.max(0.8, dotR * 0.38), 0, Math.PI * 2);
            ctx.fillStyle = _colored ? WaveDraw.alpha(color, 1) : _color100;
            ctx.fill();
            // outer ring stroke
            ctx.beginPath();
            ctx.arc(cx, cy, dotR, 0, Math.PI * 2);
            ctx.strokeStyle = _colored ? WaveDraw.alpha(color, .75) : _color75;
            ctx.lineWidth = strokeW;
            ctx.stroke();
        }

        for (let i = 0; i < n; i++) {
            const v = levels[i];
            const cx = i * step5 + step5 / 2;
            const dotR = Math.max(1.5, v * maxR5);

            const dotColor = _colored ? WaveDraw.colorAt(colorStops, cx / width) : waveColor;
            drawRing(cx, mid - v * amp5, dotR, dotColor);
            drawRing(cx, mid + v * amp5, dotR, dotColor);
        }
    }
}
