// The label's fragment shader: the texture of glyphs is white, with each glyph's coverage as its alpha, so the text takes the colour, faded by it.
// Compile it with: dxc -T ps_6_0 -E main label.frag.hlsl -Fo label.frag.dxil, and with -spirv -Fo label.frag.spv for Vulkan

// a fragment shader's uniform blocks are in space 3, and its textures and samplers in space 2; Vulkan takes them as one sampler
cbuffer Colour : register(b0, space3)
{
    float4 colour;
};

[[vk::combinedImageSampler]] Texture2D<float4> glyphs : register(t0, space2);
[[vk::combinedImageSampler]] SamplerState glyphSampler : register(s0, space2);

float4 main([[vk::location(0)]] float2 uv : TEXCOORD0) : SV_Target0
{
    return float4(colour.rgb, colour.a * glyphs.Sample(glyphSampler, uv).a);
}
