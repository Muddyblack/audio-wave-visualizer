import QtQuick

// CSS box-shadow outside a rounded card: card shadows and the bass-pulse glow.
// The owner anchors it `margin` px beyond the card. Each layer is a separable
// Gaussian of its offset, spread box (as the shaders compute glow): a
// horizontal gradient multiplied by a vertical one with destination-in, then
// the card interior is cleared. Only native gradient fills run — Canvas
// shadowBlur and per-pixel ImageData loops both took seconds in QML.
// Painted once per size/setting change; animating the glow changes opacity.
Item {
    id: glow

    property real margin: 90
    property real radius: 12
    // [{ y, blur, spread, color }]; blur is the CSS blur radius (sigma = blur / 2).
    property var layers: []
    property color insetColor: "transparent"

    // Multi-stop radial bleed ambient glow.
    // When enabled or when layers specify radial: true, paints a soft multi-stop
    // radial/linear edge bleed outward from the card perimeter onto the desktop/panel.
    property bool radialBleed: false
    property real bleedDistance: margin
    property var bleedStops: []
    property var bleedColors: []

    // Abramowitz & Stegun 7.1.27, error below 5e-4.
    function erf(x) {
        const a = Math.abs(x);
        let t = 1 + (0.278393 + (0.230389 + (0.000972 + 0.078108 * a) * a) * a) * a;
        t *= t;
        return Math.sign(x) * (1 - 1 / (t * t));
    }

    // Blurred coverage of [lo, hi] at position p.
    function coverage(p, lo, hi, sigma) {
        const k = Math.SQRT1_2 / Math.max(0.5, sigma);
        return 0.5 * (erf((hi - p) * k) - erf((lo - p) * k));
    }

    // Gradient stops along one axis, dense where the edges ramp.
    function stops(length, lo, hi, sigma) {
        const positions = [0, length];
        for (const edge of [lo, hi])
            for (let k = -3; k <= 3; k += 0.25)
                positions.push(edge + k * Math.max(0.5, sigma));
        return positions.filter(p => p >= 0 && p <= length).sort((a, b) => a - b).filter((p, i, all) => i === 0 || p - all[i - 1] > 0.01).map(p => [p / length, coverage(p, lo, hi, sigma)]);
    }

    function clearCard(ctx) {
        const w = width - 2 * margin, h = height - 2 * margin;
        const r = Math.max(0, Math.min(radius, w / 2, h / 2));
        ctx.globalCompositeOperation = "destination-out";
        ctx.fillStyle = "black";
        ctx.beginPath();
        ctx.roundedRect(margin, margin, w, h, r, r);
        ctx.fill();
        ctx.globalCompositeOperation = "source-over";
    }

    function paintRadialBleed(ctx, W, H, m, w, h, r, spread, bleed, stopsList, colorsList) {
        const sp = spread || 0;
        const b = Math.max(1, bleed || m);
        const cardX = m - sp;
        const cardY = m - sp;
        const cardW = w + 2 * sp;
        const cardH = h + 2 * sp;
        const cr = Math.max(0, Math.min(r + sp, cardW / 2, cardH / 2));

        const left = cardX;
        const top = cardY;
        const right = cardX + cardW;
        const bottom = cardY + cardH;

        // Resolve stops: array of [offset 0..1, color]
        const resolvedStops = [];
        if (Array.isArray(stopsList) && stopsList.length > 0) {
            for (let i = 0; i < stopsList.length; i++) {
                const s = stopsList[i];
                if (Array.isArray(s)) {
                    resolvedStops.push([Math.max(0, Math.min(1, Number(s[0]))), s[1]]);
                } else if (typeof s === "object" && s !== null) {
                    const off = s.offset !== undefined ? s.offset : s.pos !== undefined ? s.pos : (i / Math.max(1, stopsList.length - 1));
                    resolvedStops.push([Math.max(0, Math.min(1, Number(off))), s.color]);
                }
            }
        } else if (Array.isArray(colorsList) && colorsList.length > 0) {
            if (colorsList.length === 1) {
                const c = colorsList[0];
                resolvedStops.push([0.0, c]);
                resolvedStops.push([0.3, Qt.rgba(c.r, c.g, c.b, c.a * 0.6)]);
                resolvedStops.push([0.7, Qt.rgba(c.r, c.g, c.b, c.a * 0.2)]);
                resolvedStops.push([1.0, Qt.rgba(c.r, c.g, c.b, 0.0)]);
            } else {
                const c1 = colorsList[0], c2 = colorsList[1];
                resolvedStops.push([0.0, c1]);
                resolvedStops.push([0.35, Qt.rgba(c1.r * 0.6 + c2.r * 0.4, c1.g * 0.6 + c2.g * 0.4, c1.b * 0.6 + c2.b * 0.4, 0.55)]);
                resolvedStops.push([0.7, Qt.rgba(c2.r, c2.g, c2.b, 0.2)]);
                resolvedStops.push([1.0, Qt.rgba(c2.r, c2.g, c2.b, 0.0)]);
            }
        }

        if (resolvedStops.length === 0)
            return;

        function applyStops(grad) {
            for (let i = 0; i < resolvedStops.length; i++) {
                grad.addColorStop(resolvedStops[i][0], resolvedStops[i][1]);
            }
        }

        // 1. Top edge
        if (right - cr > left + cr && top > 0) {
            const topGrad = ctx.createLinearGradient(0, top, 0, Math.max(0, top - b));
            applyStops(topGrad);
            ctx.fillStyle = topGrad;
            ctx.fillRect(left + cr, Math.max(0, top - b), (right - cr) - (left + cr), top - Math.max(0, top - b));
        }

        // 2. Bottom edge
        if (right - cr > left + cr && bottom < H) {
            const bottomGrad = ctx.createLinearGradient(0, bottom, 0, Math.min(H, bottom + b));
            applyStops(bottomGrad);
            ctx.fillStyle = bottomGrad;
            ctx.fillRect(left + cr, bottom, (right - cr) - (left + cr), Math.min(H, bottom + b) - bottom);
        }

        // 3. Left edge
        if (bottom - cr > top + cr && left > 0) {
            const leftGrad = ctx.createLinearGradient(left, 0, Math.max(0, left - b), 0);
            applyStops(leftGrad);
            ctx.fillStyle = leftGrad;
            ctx.fillRect(Math.max(0, left - b), top + cr, left - Math.max(0, left - b), (bottom - cr) - (top + cr));
        }

        // 4. Right edge
        if (bottom - cr > top + cr && right < W) {
            const rightGrad = ctx.createLinearGradient(right, 0, Math.min(W, right + b), 0);
            applyStops(rightGrad);
            ctx.fillStyle = rightGrad;
            ctx.fillRect(right, top + cr, Math.min(W, right + b) - right, (bottom - cr) - (top + cr));
        }

        // 5. Top-Left Corner
        const cxTL = left + cr, cyTL = top + cr;
        const rTLMinX = Math.max(0, left - b), rTLMinY = Math.max(0, top - b);
        if (cxTL > rTLMinX && cyTL > rTLMinY) {
            ctx.save();
            ctx.beginPath();
            ctx.rect(rTLMinX, rTLMinY, cxTL - rTLMinX, cyTL - rTLMinY);
            ctx.clip();
            const radTL = ctx.createRadialGradient(cxTL, cyTL, cr, cxTL, cyTL, cr + b);
            applyStops(radTL);
            ctx.fillStyle = radTL;
            ctx.fillRect(rTLMinX, rTLMinY, cxTL - rTLMinX, cyTL - rTLMinY);
            ctx.restore();
        }

        // 6. Top-Right Corner
        const cxTR = right - cr, cyTR = top + cr;
        const rTRMaxX = Math.min(W, right + b), rTRMinY = Math.max(0, top - b);
        if (rTRMaxX > cxTR && cyTR > rTRMinY) {
            ctx.save();
            ctx.beginPath();
            ctx.rect(cxTR, rTRMinY, rTRMaxX - cxTR, cyTR - rTRMinY);
            ctx.clip();
            const radTR = ctx.createRadialGradient(cxTR, cyTR, cr, cxTR, cyTR, cr + b);
            applyStops(radTR);
            ctx.fillStyle = radTR;
            ctx.fillRect(cxTR, rTRMinY, rTRMaxX - cxTR, cyTR - rTRMinY);
            ctx.restore();
        }

        // 7. Bottom-Left Corner
        const cxBL = left + cr, cyBL = bottom - cr;
        const rBLMinX = Math.max(0, left - b), rBLMaxY = Math.min(H, bottom + b);
        if (cxBL > rBLMinX && rBLMaxY > cyBL) {
            ctx.save();
            ctx.beginPath();
            ctx.rect(rBLMinX, cyBL, cxBL - rBLMinX, rBLMaxY - cyBL);
            ctx.clip();
            const radBL = ctx.createRadialGradient(cxBL, cyBL, cr, cxBL, cyBL, cr + b);
            applyStops(radBL);
            ctx.fillStyle = radBL;
            ctx.fillRect(rBLMinX, cyBL, cxBL - rBLMinX, rBLMaxY - cyBL);
            ctx.restore();
        }

        // 8. Bottom-Right Corner
        const cxBR = right - cr, cyBR = bottom - cr;
        const rBRMaxX = Math.min(W, right + b), rBRMaxY = Math.min(H, bottom + b);
        if (rBRMaxX > cxBR && rBRMaxY > cyBR) {
            ctx.save();
            ctx.beginPath();
            ctx.rect(cxBR, cyBR, rBRMaxX - cxBR, rBRMaxY - cyBR);
            ctx.clip();
            const radBR = ctx.createRadialGradient(cxBR, cyBR, cr, cxBR, cyBR, cr + b);
            applyStops(radBR);
            ctx.fillStyle = radBR;
            ctx.fillRect(cxBR, cyBR, rBRMaxX - cxBR, rBRMaxY - cyBR);
            ctx.restore();
        }

        glow.clearCard(ctx);
    }

    Repeater {
        model: glow.layers
        Canvas {
            required property var modelData
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative
            readonly property var signature: [glow.margin, glow.radius, modelData, width, height]
            onSignatureChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const W = width, H = height, m = glow.margin;
                const w = W - 2 * m, h = H - 2 * m;
                if (w <= 0 || h <= 0)
                    return;
                const layer = modelData;
                if (layer.radialBleed || layer.radial || layer.type === "radial" || (layer.stops && layer.stops.length > 0)) {
                    glow.paintRadialBleed(ctx, W, H, m, w, h, glow.radius, layer.spread || 0, layer.bleed || layer.blur || m, layer.stops || [], layer.colors || (layer.color ? [layer.color] : []));
                    return;
                }
                const spread = layer.spread || 0, sigma = (layer.blur || 0) / 2, c = layer.color;
                const horizontal = ctx.createLinearGradient(0, 0, W, 0);
                for (const stop of glow.stops(W, m - spread, m + w + spread, sigma))
                    horizontal.addColorStop(stop[0], Qt.rgba(c.r, c.g, c.b, c.a * stop[1]));
                ctx.fillStyle = horizontal;
                ctx.fillRect(0, 0, W, H);
                const vertical = ctx.createLinearGradient(0, 0, 0, H);
                for (const stop of glow.stops(H, m - spread + layer.y, m + h + spread + layer.y, sigma))
                    vertical.addColorStop(stop[0], Qt.rgba(0, 0, 0, stop[1]));
                ctx.globalCompositeOperation = "destination-in";
                ctx.fillStyle = vertical;
                ctx.fillRect(0, 0, W, H);
                // Like box-shadow, nothing is painted underneath the card itself.
                glow.clearCard(ctx);
            }
        }
    }

    Canvas {
        anchors.fill: parent
        visible: glow.radialBleed
        renderStrategy: Canvas.Cooperative
        readonly property var signature: [glow.radialBleed, glow.margin, glow.radius, glow.bleedDistance, glow.bleedStops, glow.bleedColors, width, height]
        onSignatureChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            if (!glow.radialBleed)
                return;
            const W = width, H = height, m = glow.margin;
            const w = W - 2 * m, h = H - 2 * m;
            if (w <= 0 || h <= 0)
                return;
            glow.paintRadialBleed(ctx, W, H, m, w, h, glow.radius, 0, glow.bleedDistance, glow.bleedStops, glow.bleedColors);
        }
    }

    Canvas {
        anchors.fill: parent
        visible: glow.insetColor.a > 0
        renderStrategy: Canvas.Cooperative
        readonly property var signature: [glow.margin, glow.radius, glow.insetColor, width, height]
        onSignatureChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const m = glow.margin, w = width - 2 * m, h = height - 2 * m;
            if (w <= 1 || h <= 1 || glow.insetColor.a <= 0)
                return;
            const r = Math.max(0, Math.min(glow.radius, w / 2, h / 2));
            ctx.strokeStyle = glow.insetColor;
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.roundedRect(m + 0.5, m + 0.5, w - 1, h - 1, Math.max(0, r - 0.5), Math.max(0, r - 0.5));
            ctx.stroke();
        }
    }
}
