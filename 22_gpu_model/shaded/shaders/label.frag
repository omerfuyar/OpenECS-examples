// The label's fragment shader: the texture of glyphs is white, with each glyph's coverage as its alpha, so the text takes the colour, faded by it.
#version 450

layout(location = 0) in vec2 uv;

layout(location = 0) out vec4 color;

// a fragment shader's samplers are in set 2, and its uniform blocks in set 3
layout(set = 2, binding = 0) uniform sampler2D glyphs;

layout(set = 3, binding = 0) uniform Colour
{
    vec4 colour;
};

void main()
{
    color = vec4(colour.rgb, colour.a * texture(glyphs, uv).a);
}
