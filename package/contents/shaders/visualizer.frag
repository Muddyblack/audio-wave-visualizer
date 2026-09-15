#version 440
// Draws the six WaveCanvas styles in a single pass. Geometry follows
// WaveCanvas.qml path by path, and the glow reproduces its MultiEffect shadow
// with a measured blur kernel, so an audio frame needs no CPU rasterisation,
// texture upload or blur passes.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 canvasSize;
    float pixelRatio;
    float style;
    float barCount;
    float lineWidth;
    float fillAmount;
    float glowAmount;
    float glowSigma;
    float glowGain;
    float glowSigma2;
    float glowGain2;
    vec4 waveColor;
    vec4 levels0;
    vec4 levels1;
    vec4 levels2;
    vec4 levels3;
    vec4 levels4;
    vec4 levels5;
    vec4 levels6;
    vec4 levels7;
    vec4 levels8;
    vec4 levels9;
    vec4 levels10;
    vec4 levels11;
    vec4 levels12;
    vec4 levels13;
    vec4 levels14;
    vec4 levels15;
    vec4 levels16;
    vec4 levels17;
    vec4 levels18;
    vec4 levels19;
    vec4 levels20;
    vec4 levels21;
    vec4 levels22;
    vec4 levels23;
    vec4 levels24;
    vec4 levels25;
    vec4 levels26;
    vec4 levels27;
    vec4 levels28;
    vec4 levels29;
    vec4 levels30;
    vec4 levels31;
};

// ShaderEffect has no array uniforms, so levels arrive four per vec4.
vec4 block(int b)
{
    if (b < 16) {
        if (b < 8) {
            if (b < 4)
                return b < 2 ? (b < 1 ? levels0 : levels1) : (b < 3 ? levels2 : levels3);
            return b < 6 ? (b < 5 ? levels4 : levels5) : (b < 7 ? levels6 : levels7);
        }
        if (b < 12)
            return b < 10 ? (b < 9 ? levels8 : levels9) : (b < 11 ? levels10 : levels11);
        return b < 14 ? (b < 13 ? levels12 : levels13) : (b < 15 ? levels14 : levels15);
    }
    if (b < 24) {
        if (b < 20)
            return b < 18 ? (b < 17 ? levels16 : levels17) : (b < 19 ? levels18 : levels19);
        return b < 22 ? (b < 21 ? levels20 : levels21) : (b < 23 ? levels22 : levels23);
    }
    if (b < 28)
        return b < 26 ? (b < 25 ? levels24 : levels25) : (b < 27 ? levels26 : levels27);
    return b < 30 ? (b < 29 ? levels28 : levels29) : (b < 31 ? levels30 : levels31);
}

// Normalised, tapered sample i (0 outside the configured bars).
float level(int i)
{
    int n = int(barCount + 0.5);
    if (i < 0 || i >= n)
        return 0.0;
    int b = i / 4;
    int c = i - b * 4;
    vec4 v = block(b);
    return c == 0 ? v.x : (c == 1 ? v.y : (c == 2 ? v.z : v.w));
}

float erfApprox(float x)
{
    // Abramowitz & Stegun 7.1.27, error below 5e-4.
    float a = abs(x);
    float t = 1.0 + (0.278393 + (0.230389 + (0.000972 + 0.078108 * a) * a) * a) * a;
    t *= t;
    return sign(x) * (1.0 - 1.0 / (t * t));
}

// Mass of a unit 1D Gaussian inside [lo, hi].
float gaussSpan(float lo, float hi, float sigma)
{
    float k = 0.70710678 / sigma;
    return 0.5 * (erfApprox(hi * k) - erfApprox(lo * k));
}

// The glow kernel is a mix of a narrow and a wide Gaussian, fitted to
// MultiEffect { shadowBlur: 1; blurMax: 8 } as WaveCanvas configures it.
float kernelSpan(float lo, float hi)
{
    return glowGain * gaussSpan(lo, hi, glowSigma) + glowGain2 * gaussSpan(lo, hi, glowSigma2);
}

// Blurred alpha of an axis-aligned box.
float kernelBox(vec2 p, vec2 lo, vec2 hi)
{
    return glowGain * gaussSpan(lo.x - p.x, hi.x - p.x, glowSigma) * gaussSpan(lo.y - p.y, hi.y - p.y, glowSigma)
        + glowGain2 * gaussSpan(lo.x - p.x, hi.x - p.x, glowSigma2) * gaussSpan(lo.y - p.y, hi.y - p.y, glowSigma2);
}

// Blurred alpha of a small disc: exact at its centre, Gaussian falloff.
float kernelDisc(float d, float r)
{
    float s1 = glowSigma * glowSigma;
    float s2 = glowSigma2 * glowSigma2;
    float rr = r * r;
    return glowGain * (1.0 - exp(-rr / (2.0 * s1))) * exp(-d * d / (2.0 * s1 + 0.5 * rr))
        + glowGain2 * (1.0 - exp(-rr / (2.0 * s2))) * exp(-d * d / (2.0 * s2 + 0.5 * rr));
}

// Pixel coverage for a signed distance (negative inside), one device pixel wide.
float cover(float sd)
{
    return clamp(0.5 - sd * pixelRatio, 0.0, 1.0);
}

vec3 baseRgb()
{
    return waveColor.a > 0.0 ? waveColor.rgb / waveColor.a : vec3(0.0);
}

vec4 paint(float alpha, float coverage)
{
    float a = alpha * coverage;
    return vec4(baseRgb() * a, a);
}

vec4 over(vec4 top, vec4 under)
{
    return top + under * (1.0 - top.a);
}

float sdBox(vec2 p, vec2 lo, vec2 hi)
{
    vec2 d = abs(p - (lo + hi) * 0.5) - (hi - lo) * 0.5;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdSegment(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
    return length(pa - ba * h);
}

float glowReach()
{
    return lineWidth * 0.5 + 3.0 * max(glowSigma, glowSigma2);
}

// ── Style 0: mirrored smooth wave ───────────────────────────────────────────
// WaveCanvas joins samples with cubic beziers whose control points share the
// segment's mid x: x(t) = x0 + step * (1.5t - 1.5t² + t³) and the height
// follows smoothstep(t) between the two samples.
float waveHeight(float x, float step, int n)
{
    float fi = clamp(floor(x / step), 0.0, float(n - 2));
    int i = int(fi);
    float u = clamp(x / step - fi, 0.0, 1.0);
    float t = u;
    for (int k = 0; k < 4; k++) {
        float f = t * (1.5 + t * (t - 1.5)) - u;
        float df = 1.5 + t * (3.0 * t - 3.0);
        t = clamp(t - f / df, 0.0, 1.0);
    }
    return mix(level(i), level(i + 1), t * t * (3.0 - 2.0 * t));
}

// Distance to the upper curve, measured against a fine polyline of each nearby
// bezier segment so steep flanks get true perpendicular distances.
float waveDistance(vec2 p, float step, int n, float mid, float amp)
{
    float reach = glowReach();
    float d = 1.0e5;
    int j = int(clamp(floor(p.x / step), 0.0, float(n - 2)));
    for (int s = -3; s <= 3; s++) {
        int i = j + s;
        if (i < 0 || i > n - 2)
            continue;
        float x0 = float(i) * step;
        if (p.x < x0 - reach || p.x > x0 + step + reach)
            continue;
        float a = level(i);
        float b = level(i + 1);
        vec2 prev = vec2(x0, mid - a * amp);
        for (int k = 1; k <= 6; k++) {
            float t = float(k) / 6.0;
            vec2 cur = vec2(x0 + step * t * (1.5 + t * (t - 1.5)), mid - mix(a, b, t * t * (3.0 - 2.0 * t)) * amp);
            d = min(d, sdSegment(p, prev, cur));
            prev = cur;
        }
    }
    return d;
}

// Upper half; the lower half is drawn by mirroring p around the centre line.
vec4 waveHalf(vec2 p, float W, float H, int n, out float glow)
{
    float mid = H * 0.5;
    float amp = H * 0.42;
    float step = W / float(n - 1);
    float h = mid - p.y;
    float ch = waveHeight(p.x, step, n) * amp;
    float hw = lineWidth * 0.5;
    float d = waveDistance(p, step, n, mid, amp);
    vec4 color = paint(waveColor.a, cover(d - hw));
    glow = waveColor.a * kernelSpan(-hw - d, hw - d);
    if (fillAmount > 0.5) {
        float edge = h < ch ? -d : d;
        float gradient = mix(0.38, 0.02, clamp(h / amp, 0.0, 1.0));
        color = over(paint(gradient, cover(edge) * cover(-h)), color);
        glow += mix(0.38, 0.02, clamp(clamp(h, 0.0, ch) / amp, 0.0, 1.0)) * kernelSpan(-h, ch - h);
    }
    return color;
}

vec4 styleWave(vec2 p, float W, float H, int n, out float glow)
{
    float glowUpper;
    float glowLower;
    vec4 upper = waveHalf(p, W, H, n, glowUpper);
    vec4 lower = waveHalf(vec2(p.x, H - p.y), W, H, n, glowLower);
    glow = glowUpper + glowLower;
    return over(lower, upper);
}

// ── Style 1: bars from the bottom ───────────────────────────────────────────
// WaveCanvas closes each bar's path back to its start at the top of the cap,
// so the left edge runs diagonally from the bottom-left corner to the cap top,
// leaving a sliver of the cap's left half: a "fin".
float sdFin(vec2 p, float x0, float y0, float r, float H)
{
    vec2 c = vec2(x0 + r, y0 + r);
    float disc = length(p - c) - r;
    float body = min(disc, sdBox(p, vec2(x0, y0 + r), vec2(x0 + 2.0 * r, H + r)));
    float diagonal = dot(p - vec2(x0, H), normalize(vec2(y0 - H, -r)));
    float sliver = max(disc, dot(p - vec2(x0 + r, y0), vec2(0.70710678)));
    return min(max(body, diagonal), sliver);
}

vec4 styleBars(vec2 p, float W, float H, int n, out float glow)
{
    float slot = W / float(n);
    float gap = max(1.0, slot * 0.25);
    float barW = max(1.0, slot - gap);
    float r = barW * 0.5;
    float amp = H * 0.88;
    float pitch = barW + gap;
    int j = int(floor((p.x - gap * 0.5) / pitch));
    vec4 color = vec4(0.0);
    glow = 0.0;
    for (int k = -3; k <= 3; k++) {
        int i = j + k;
        if (i < 0 || i >= n)
            continue;
        float bh = max(2.0, level(i) * amp);
        float x0 = float(i) * pitch + gap * 0.5;
        float y0 = H - bh;
        bool fin = bh > 2.0 * r;
        float sd = fin ? sdFin(p, x0, y0, r, H) : length(p - vec2(x0 + r, y0 + r)) - r;
        float gradient = mix(0.95, 0.35, clamp((p.y - y0) / bh, 0.0, 1.0));
        color = over(paint(gradient, cover(sd)), color);
        // The fin narrows towards the top; blur the box at this pixel's width.
        float left = fin ? x0 + r * clamp((H - p.y) / bh, 0.0, 1.0) : x0;
        glow += gradient * kernelBox(p, vec2(left, y0), vec2(x0 + barW, H + 4.0 * glowSigma2));
    }
    return color;
}

// ── Style 2: bars mirrored around the centre ────────────────────────────────
vec4 styleMirrorBars(vec2 p, float W, float H, int n, out float glow)
{
    float slot = W / float(n);
    float gap = max(1.0, slot * 0.22);
    float barW = max(1.0, slot - gap);
    float r = barW * 0.5;
    float amp = H * 0.44;
    float mid = H * 0.5;
    float pitch = barW + gap;
    int j = int(floor((p.x - gap * 0.5) / pitch));
    vec4 color = vec4(0.0);
    glow = 0.0;
    for (int k = -3; k <= 3; k++) {
        int i = j + k;
        if (i < 0 || i >= n)
            continue;
        float bh = max(2.0, level(i) * amp);
        float x0 = float(i) * pitch + gap * 0.5;
        float cx = x0 + r;
        float gradient = mix(0.95, 0.35, clamp(abs(p.y - mid) / bh, 0.0, 1.0));
        float sdTop;
        float sdBottom;
        float bottomEnd;
        if (bh > r) {
            // Top: box from the cap centre to the middle plus the upper half disc.
            // Each half disc reaches 1 px past its flat side, so it never shares
            // an edge with the box; coincident edges leak coverage as a seam.
            float cy = mid - bh + r;
            float cap = max(length(p - vec2(cx, cy)) - r, p.y - cy - 1.0);
            sdTop = min(sdBox(p, vec2(x0, cy), vec2(x0 + barW, mid)), cap);
            // Bottom: WaveCanvas' arc bends back up, notching the bar's end.
            float by = mid + bh - r;
            float notch = max(length(p - vec2(cx, by)) - r, p.y - by - 1.0);
            sdBottom = max(sdBox(p, vec2(x0, mid), vec2(x0 + barW, by)), -notch);
            bottomEnd = by - 0.5 * r;
        } else {
            sdTop = length(p - vec2(cx, mid - r)) - r;
            sdBottom = length(p - vec2(cx, mid + r)) - r;
            bottomEnd = mid + 2.0 * r;
        }
        color = over(paint(gradient, cover(sdTop)), color);
        color = over(paint(gradient, cover(sdBottom)), color);
        glow += gradient * kernelBox(p, vec2(x0, mid - bh), vec2(x0 + barW, bottomEnd));
    }
    return color;
}

// ── Style 3: stepped "tech" line with node dots ─────────────────────────────
vec4 styleTechHalf(vec2 p, float sign, float W, float H, int n, out float glow)
{
    float mid = H * 0.5;
    float amp = H * 0.42;
    float step = W / float(max(n - 1, 1));
    int j = int(floor(p.x / step));
    float line = 1.0e5;
    float dot = 1.0e5;
    for (int k = -2; k <= 2; k++) {
        int i = j + k;
        if (i < 0 || i >= n)
            continue;
        float x = float(i) * step;
        float y = mid + sign * level(i) * amp;
        dot = min(dot, length(p - vec2(x, y)));
        if (i + 1 < n) {
            float y1 = mid + sign * level(i + 1) * amp;
            float xm = x + step * 0.5;
            line = min(line, sdSegment(p, vec2(x, y), vec2(xm, y)));
            line = min(line, sdSegment(p, vec2(xm, y), vec2(xm, y1)));
            line = min(line, sdSegment(p, vec2(xm, y1), vec2(x + step, y1)));
        }
    }
    float hw = lineWidth * 0.5;
    glow = waveColor.a * (kernelSpan(-hw - line, hw - line) + kernelDisc(dot, 1.6));
    vec4 color = paint(waveColor.a, cover(line - hw));
    return over(paint(waveColor.a, cover(dot - 1.6)), color);
}

vec4 styleTech(vec2 p, float W, float H, int n, out float glow)
{
    float glowUpper;
    float glowLower;
    vec4 upper = styleTechHalf(p, -1.0, W, H, n, glowUpper);
    vec4 lower = styleTechHalf(p, 1.0, W, H, n, glowLower);
    glow = glowUpper + glowLower;
    return over(lower, upper);
}

// ── Styles 4 and 5: floating dots and rings ─────────────────────────────────
vec4 dotSoft(vec2 p, vec2 c, float radius, inout float glow)
{
    float d = length(p - c);
    // Solid core, then a radial halo from 0.3r (alpha .55) to r (alpha 0).
    vec4 color = paint(0.92, cover(d - radius * 0.45));
    float halo = mix(0.55, 0.0, clamp((d - radius * 0.3) / (radius * 0.7), 0.0, 1.0));
    color = over(paint(halo, cover(d - radius)), color);
    glow += 0.9 * kernelDisc(d, radius * 0.62);
    return color;
}

vec4 dotRing(vec2 p, vec2 c, float radius, float strokeW, inout float glow)
{
    float d = length(p - c);
    float core = max(0.8, radius * 0.38);
    vec4 color = paint(1.0, cover(d - core));
    float hw = strokeW * 0.5;
    color = over(paint(0.75, cover(abs(d - radius) - hw)), color);
    float ring = abs(d - radius);
    glow += kernelDisc(d, core) + 0.75 * kernelSpan(-hw - ring, hw - ring) * min(1.0, radius / (1.5 * glowSigma));
    return color;
}

vec4 styleDots(vec2 p, float W, float H, int n, bool rings, out float glow)
{
    float step = W / float(n);
    float amp = H * 0.42;
    float mid = H * 0.5;
    float maxR = rings ? max(2.0, step * 0.32) : max(2.0, step * 0.28 * (lineWidth / 2.0));
    float strokeW = max(0.8, lineWidth * 0.6);
    int j = int(floor(p.x / step));
    vec4 color = vec4(0.0);
    glow = 0.0;
    for (int k = -3; k <= 3; k++) {
        int i = j + k;
        if (i < 0 || i >= n)
            continue;
        float lv = level(i);
        float cx = float(i) * step + step * 0.5;
        float radius = max(1.5, lv * maxR);
        vec2 up = vec2(cx, mid - lv * amp);
        vec2 down = vec2(cx, mid + lv * amp);
        if (rings) {
            color = over(dotRing(p, up, radius, strokeW, glow), color);
            color = over(dotRing(p, down, radius, strokeW, glow), color);
        } else {
            color = over(dotSoft(p, up, radius, glow), color);
            color = over(dotSoft(p, down, radius, glow), color);
        }
    }
    return color;
}

void main()
{
    float W = canvasSize.x;
    float H = canvasSize.y;
    vec2 p = qt_TexCoord0 * canvasSize;
    int n = int(barCount + 0.5);
    int type = int(style + 0.5);
    float glow = 0.0;
    vec4 color = vec4(0.0);
    if (n >= 2 || (n >= 1 && type != 0 && type != 3)) {
        if (type == 0)
            color = styleWave(p, W, H, n, glow);
        else if (type == 1)
            color = styleBars(p, W, H, n, glow);
        else if (type == 2)
            color = styleMirrorBars(p, W, H, n, glow);
        else if (type == 3)
            color = styleTech(p, W, H, n, glow);
        else
            color = styleDots(p, W, H, n, type == 5, glow);
    }
    // MultiEffect shadow: the drawing over a wave-coloured blurred alpha.
    vec4 shadow = waveColor * clamp(glow * glowAmount, 0.0, 1.0);
    fragColor = over(color, shadow) * qt_Opacity;
}
