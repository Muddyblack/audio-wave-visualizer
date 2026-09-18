.pragma library
.import "WaveMath.js" as WaveMath
.import "WaveDraw.js" as WaveDraw

// Shared material swatches: repaint only when the tile size or choice changes.
function draw(ctx, width, height, kind) {
    if (width <= 0 || height <= 0) return;
    if (kind === "liquid") {
        const background = ctx.createLinearGradient(0, 0, width, 0);
        background.addColorStop(0, "#5b1d6e");
        background.addColorStop(1, "#b3628a");
        ctx.fillStyle = background;
        ctx.fillRect(0, 0, width, height);
    }
    ctx.save();
    const w = width * .74, h = Math.min(34, height);
    ctx.translate((width - w) / 2, (height - h) / 2);
    const diagonal = stops => {
        const g = ctx.createLinearGradient(0, 0, w, h);
        for (const s of stops)
            g.addColorStop(s[0], s[1]);
        ctx.fillStyle = g;
        ctx.fillRect(0, 0, w, h);
    };
    ctx.save();
    ctx.beginPath();
    WaveDraw.roundRect(ctx, 0, 0, w, h, 9);
    ctx.clip();
    switch (kind) {
    case "color":
        ctx.fillStyle = WaveMath.color("#e60a0b10");
        ctx.fillRect(0, 0, w, h);
        break;
    case "art":
        diagonal([[0, WaveMath.color("#7a3cff")], [1, WaveMath.color("#ff4fb8")]]);
        ctx.fillStyle = WaveMath.color("#55000000");
        ctx.fillRect(0, 0, w, h);
        break;
    case "glass":
        diagonal([[0, WaveMath.color("#30ffffff")], [0.6, WaveMath.color("#08ffffff")], [1, WaveMath.color("#14ffffff")]]);
        ctx.fillStyle = WaveMath.color("#30ffffff");
        ctx.fillRect(0, 0, w, 1);
        break;
    case "liquid":
        diagonal([[0, WaveMath.color("#22ffffff")], [0.5, WaveMath.color("#05ffffff")], [1, WaveMath.color("#18ffffff")]]);
        ctx.fillStyle = WaveMath.color("#aaffffff");
        ctx.fillRect(0, 0, w, 1);
        ctx.fillStyle = WaveMath.color("#40ffffff");
        ctx.fillRect(0, h - 1, w, 1);
        break;
    case "solid":
        diagonal([[0, WaveMath.color("#eeeee4")], [1, WaveMath.color("#d9dfcf")]]);
        break;
    case "atmosphere":
        ctx.fillStyle = WaveMath.color("#120b2e");
        ctx.fillRect(0, 0, w, h);
        for (const spot of [[w, 0, WaveMath.color("#aaff3d8b")], [0, h, WaveMath.color("#aa5b2cff")]]) {
            const g = ctx.createRadialGradient(spot[0], spot[1], 0, spot[0], spot[1], w * 0.8);
            g.addColorStop(0, spot[2]);
            g.addColorStop(1, Qt.rgba(0, 0, 0, 0));
            ctx.fillStyle = g;
            ctx.fillRect(0, 0, w, h);
        }
        break;
    }
    ctx.restore();
    if (kind !== "liquid") {
        ctx.strokeStyle = WaveMath.color("#1fffffff");
        ctx.lineWidth = 1;
        ctx.beginPath();
        WaveDraw.roundRect(ctx, 0.5, 0.5, w - 1, h - 1, 8.5);
        ctx.stroke();
    }
    ctx.restore();
}
