// Bounded vertex-buffer quads; geometry, inertia and turbulence share the
// audio-clock state with Canvas. Fragments shade only the nearby spark.
layout(location = 1) in vec4 particleData;
void main() {
    float d = length(particleData.xy);
    float life = particleData.w;
    float radius = particleData.z;
    vec4 dot = over(paint(life, cover(d - radius)), htmlShadow(life * htmlDiscGlow(d, radius)));
    fragColor = dot * (qt_Opacity * edgeMask());
}
