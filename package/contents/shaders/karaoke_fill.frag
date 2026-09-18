#version 440
layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;
layout(std140,binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    vec2 pixelStep;
};
layout(binding=1) uniform sampler2D source;
void main() {
    vec2 uv = qt_TexCoord0;
    float edge = max(pixelStep.x * 2.0, 0.005);
    float wipe = progress >= 1.0 ? 1.0 : 1.0 - smoothstep(progress - edge, progress + edge, uv.x);
    vec4 ink = texture(source, uv);
    vec4 glow = (texture(source, uv + vec2(pixelStep.x, 0.0))
               + texture(source, uv - vec2(pixelStep.x, 0.0))
               + texture(source, uv + vec2(0.0, pixelStep.y))
               + texture(source, uv - vec2(0.0, pixelStep.y))) * 0.25;
    float shine = (1.0 - smoothstep(0.0, edge * 3.0, abs(uv.x - progress))) * 0.5;
    fragColor = (ink + glow * shine * (1.0 - ink.a)) * wipe * qt_Opacity;
}
