// Smooth union of moving signed-distance circles forms one liquid surface.
float fluidDistance(vec2 p) {
    float d = 10.0;
    float t = timeSeconds * 0.55;
    for (int i = 0; i < 7; i++) {
        float f = float(i);
        float band = i < 2 ? bass : (i < 5 ? mid : high);
        vec2 centre = vec2(sin(t * (0.7 + f * 0.09) + f * 2.4) * 0.64,
                           cos(t * (0.9 + f * 0.05) + f * 1.7) * 0.55);
        float radius = 0.13 + band * 0.19 + 0.025 * sin(f + t * 2.0);
        float next = length(p - centre) - radius;
        float k = 0.17 + bass * 0.12;
        float h = clamp(0.5 + 0.5 * (next - d) / k, 0.0, 1.0);
        d = mix(next, d, h) - k * h * (1.0 - h);
    }
    return d;
}
void main() {
    vec2 p = (qt_TexCoord0 - 0.5) * 2.4;
    float d = fluidDistance(p);
    float px = 2.4 / max(1.0, min(canvasSize.x, canvasSize.y));
    float a = 1.0 - smoothstep(-px, px, d);
    vec2 normal = vec2(fluidDistance(p + vec2(px, 0.0)) - d, fluidDistance(p + vec2(0.0, px)) - d) / px;
    float spec = pow(max(0.0, dot(normalize(vec3(normal, 0.6)), normalize(vec3(-0.5, -0.6, 1.0)))), 18.0);
    vec3 rgb = baseRgb() * (0.55 + 0.45 * smoothstep(-0.3, 0.0, d)) + spec * 0.6;
    float rim = exp(-abs(d) * 35.0);
    a *= fillAmount > 0.5 ? 0.9 : rim;
    vec4 liquid = vec4(clamp(rgb, 0.0, 1.0) * a, a);
    float halo = glowAmount * exp(-abs(d) * 12.0 / max(0.2, bloom)) * 0.15;
    fragColor = over(liquid, vec4(baseRgb() * halo, halo)) * (qt_Opacity * edgeMask());
}
