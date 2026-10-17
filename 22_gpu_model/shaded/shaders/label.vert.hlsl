// The label's vertex shader: it places the glyphs of a text beside a point of the model, flat on the screen, at the point's depth, so the model's
// nearer side covers the label as it turns. A glyph's x and y are in pixels from the text's top left, as gpu.glyphs gives them.
// Compile it with: dxc -T vs_6_0 -E main label.vert.hlsl -Fo label.vert.dxil, and with -spirv -Fo label.vert.spv for Vulkan

// a vertex shader's uniform blocks are in space 1, as SDL's GPU API sets them; the matrices are 16 floats column by column
cbuffer Label : register(b0, space1)
{
    column_major float4x4 model;
    column_major float4x4 viewProjection;
    float4 anchor; // the point in the model's space that the label follows
    float4 screen; // the surface's width and height in pixels, then the text's offset from the point in pixels
};

// SDL's GPU API names a vertex attribute of location n TEXCOORDn; Vulkan takes its location
struct Input
{
    [[vk::location(0)]] float4 glyph : TEXCOORD0; // x and y in pixels, then u and v in the texture of glyphs
};

struct Output
{
    [[vk::location(0)]] float2 uv : TEXCOORD0;
    float4 position : SV_Position;
};

Output main(Input input)
{
    Output output;
    float4 clip = mul(viewProjection, mul(model, float4(anchor.xyz, 1.0)));
    float2 pixels = input.glyph.xy + screen.zw;

    // pixels go right and down, and clip space goes right and up from -1 to 1 across the surface; multiplied by w, the offset stays the same on the screen
    clip.xy += float2(pixels.x * 2.0 / screen.x, -pixels.y * 2.0 / screen.y) * clip.w;
    output.position = clip;
    output.uv = input.glyph.zw;
    return output;
}
