// Four mesh rows per particle: top, bottom, collapsed bottom, collapsed next
// top. Connector triangles are degenerate, so 32 quads use one vertex buffer
// and one draw call without a full-screen per-pixel loop over every particle.
layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out vec2 qt_TexCoord0;
layout(location = 1) out vec4 particleData;
void main() {
    int row = int(floor(qt_MultiTexCoord0.y * 125.0 + 0.5));
    int lane = row % 4;
    int index = row / 4 + (lane == 3 ? 1 : 0);
    vec4 particle = particleAt(index);
    float extent = particle.z + (glowAmount > 0.5 ? 16.0 * max(0.2, bloom) : 1.0);
    float x = lane >= 2 ? 0.0 : qt_MultiTexCoord0.x * 2.0 - 1.0;
    float y = lane == 1 || lane == 2 ? 1.0 : -1.0;
    vec2 local = vec2(x, y) * extent;
    particleData = vec4(local, particle.z, float(index) < particleCount ? particle.w : 0.0);
    vec2 position = particle.xy + local;
    qt_TexCoord0 = position / max(canvasSize, vec2(1.0));
    gl_Position = qt_Matrix * vec4(position, 0.0, 1.0);
}
