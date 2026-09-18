// Polar angle selects a frequency; reciprocal depth projects the rings.
void main() {
    vec2 q = (qt_TexCoord0 - 0.5) * canvasSize;
    float angle = atan(q.y, q.x);
    float band = (angle + 3.14159265) / 6.2831853;
    float spectrum = level(int(band * max(0.0, barCount - 1.0)));
    float scale = min(canvasSize.x, canvasSize.y) * 0.48;
    float radius = length(q);
    float warp = 1.0 + 0.15 * spectrum * sin(angle * 5.0 + timeSeconds) + 0.12 * bass;
    float distance = 1e5;
    float light = 0.0;
    for (int i = 0; i < 12; i++) {
        float depth = 0.65 + mod(float(i) + timeSeconds * 1.4, 12.0);
        float ring = scale * 2.1 / depth * warp * (1.0 + beatPulse * 0.16);
        float d = abs(radius - ring);
        if (d < distance) {
            distance = d;
            light = 1.0 - float(i) / 18.0;
        }
    }
    float spokes = abs(sin(angle * 12.0 + sin(timeSeconds * 0.2) * mid)) * radius / 12.0;
    vec4 color = over(paint(light, cover(distance - max(0.6, lineWidth * 0.5))), htmlShadow(htmlLineGlow(distance, 0.8)));
    color = over(paint(0.12 * high, cover(spokes - 0.5)), color);
    fragColor = color * (qt_Opacity * edgeMask());
}
