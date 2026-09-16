// Real signed stereo PCM, never reconstructed from spectral magnitudes.
vec4 sampleAt(int i) {
    if (i == 0) return scope0;
    if (i == 1) return scope1;
    if (i == 2) return scope2;
    if (i == 3) return scope3;
    if (i == 4) return scope4;
    if (i == 5) return scope5;
    if (i == 6) return scope6;
    if (i == 7) return scope7;
    if (i == 8) return scope8;
    if (i == 9) return scope9;
    if (i == 10) return scope10;
    if (i == 11) return scope11;
    if (i == 12) return scope12;
    if (i == 13) return scope13;
    if (i == 14) return scope14;
    if (i == 15) return scope15;
    if (i == 16) return scope16;
    if (i == 17) return scope17;
    if (i == 18) return scope18;
    if (i == 19) return scope19;
    if (i == 20) return scope20;
    if (i == 21) return scope21;
    if (i == 22) return scope22;
    if (i == 23) return scope23;
    if (i == 24) return scope24;
    if (i == 25) return scope25;
    if (i == 26) return scope26;
    if (i == 27) return scope27;
    if (i == 28) return scope28;
    if (i == 29) return scope29;
    if (i == 30) return scope30;
    return scope31;
}
vec2 pointAt(int i, bool previous) {
    vec4 frame = sampleAt(i);
    vec2 pcm = previous ? frame.zw : frame.xy;
    if (style < 19.5)
        return vec2(float(i) / max(1.0, scopeCount - 1.0), 0.5 - (pcm.x + pcm.y) * 0.22) * canvasSize;
    return (vec2(0.5) + vec2(pcm.x, -pcm.y) * 0.44) * canvasSize;
}
void main() {
    vec2 p = qt_TexCoord0 * canvasSize;
    float d = 1e5, trail = 1e5;
    for (int i = 0; i < 31; i++) {
        if (float(i + 1) >= scopeCount) break;
        d = min(d, sdSegment(p, pointAt(i, false), pointAt(i + 1, false)));
        if (reducedMotion < 0.5)
            trail = min(trail, sdSegment(p, pointAt(i, true), pointAt(i + 1, true)));
    }
    vec3 phosphor = style < 19.5 ? vec3(0.25, 1.0, 0.46) : vec3(1.0, 0.65, 0.18);
    float core = cover(d - max(0.6, lineWidth * 0.5));
    float persistence = cover(trail - 0.65) * 0.24;
    float halo = glowAmount * exp(-d / max(0.5, bloom * 2.4)) * 0.42;
    float gridX = abs(fract(qt_TexCoord0.x * 10.0 + 0.5) - 0.5) * canvasSize.x / 10.0;
    float gridY = abs(fract(qt_TexCoord0.y * 6.0 + 0.5) - 0.5) * canvasSize.y / 6.0;
    float grid = cover(min(gridX, gridY) - 0.35) * 0.09;
    float scan = 0.92 + 0.08 * sin(p.y * 3.14159);
    float alpha = clamp(core + persistence + halo + grid, 0.0, 1.0) * scan;
    fragColor = vec4(phosphor * alpha, alpha) * (qt_Opacity * edgeMask());
}
