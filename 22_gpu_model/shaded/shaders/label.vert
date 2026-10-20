// The label's vertex shader: it places the glyphs of a text beside a point of the model, flat on the screen, at the point's depth, so the model's
// nearer side covers the label as it turns. A glyph's x and y are in pixels from the text's top left, as gpu.glyphs gives them.
#version 450

layout(location = 0) in vec4 glyph; // x and y in pixels, then u and v in the texture of glyphs

layout(location = 0) out vec2 uv;

// a vertex shader's uniform blocks are in set 1, as SDL's GPU API sets them; the matrices are 16 floats column by column
layout(set = 1, binding = 0) uniform Label
{
    mat4 model;
    mat4 viewProjection;
    vec4 anchor; // the point in the model's space that the label follows
    vec4 screen; // the surface's width and height in pixels, then the text's offset from the point in pixels
};

void main()
{
    vec4 clip = viewProjection * (model * vec4(anchor.xyz, 1.0));
    vec2 pixels = glyph.xy + screen.zw;

    // pixels go right and down, and clip space goes right and up from -1 to 1 across the surface; multiplied by w, the offset stays the same on the screen
    clip.xy += vec2(pixels.x * 2.0 / screen.x, -pixels.y * 2.0 / screen.y) * clip.w;
    gl_Position = clip;
    uv = glyph.zw;
}
