// Perspective height-field mesh. Only nearby columns can reach each pixel.
vec2 terrainPoint(float x, float z) {
    float band = clamp((x + 6.0) / 12.0, 0.0, 1.0);
    float amplitude = level(int(band * max(0.0, barCount - 1.0)));
    float wave = sin(x * 1.3 + z * 1.7 + timeSeconds * 1.4);
    float elevation = (amplitude * 0.8 + bass * 0.3) * (0.65 + wave * 0.35);
    return vec2(canvasSize.x * (0.5 + x / z * 0.52),
                canvasSize.y * (0.27 + (1.15 - elevation) / z));
}
void main() {
    vec2 p = qt_TexCoord0 * canvasSize;
    float d = 1e5;
    float travel = fract(timeSeconds * 0.45);
    for (int row = 0; row < 12; row++) {
        float z = 1.35 + float(row) * 0.65 - travel * 0.65;
        float column = floor((qt_TexCoord0.x - 0.5) * z / 0.52);
        for (int k = -1; k <= 1; k++) {
            float x = column + float(k);
            if (x < -6.0 || x >= 6.0) continue;
            vec2 a = terrainPoint(x, z);
            d = min(d, sdSegment(p, a, terrainPoint(x + 1.0, z)));
            d = min(d, sdSegment(p, a, terrainPoint(x, z + 0.65)));
        }
    }
    float horizon = smoothstep(0.25, 0.43, qt_TexCoord0.y);
    vec4 mesh = over(paint(0.9, cover(d - max(0.55, lineWidth * 0.4))), htmlShadow(htmlLineGlow(d, 0.7)));
    fragColor = mesh * (horizon * qt_Opacity * edgeMask());
}
