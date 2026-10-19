// The torus's vertex shader in HLSL, for Direct3D 12, as torus.vert is for Vulkan: it moves each vertex by the model's matrix, and sees it through the camera's.
// Compile it with: dxc -T vs_6_0 -E main torus.vert.hlsl -Fo torus.vert.dxil

// a vertex shader's uniform blocks are in space 1, as SDL's GPU API sets them; the matrices are 16 floats column by column, as in torus.vert
cbuffer Transform : register(b0, space1)
{
    column_major float4x4 model;
    column_major float4x4 viewProjection;
};

// SDL's GPU API names a vertex attribute of location n TEXCOORDn
struct Input
{
    float3 position : TEXCOORD0;
    float3 normal : TEXCOORD1;
};

struct Output
{
    float3 worldNormal : TEXCOORD0;
    float3 worldPosition : TEXCOORD1;
    float4 position : SV_Position;
};

Output main(Input input)
{
    Output output;
    float4 world = mul(model, float4(input.position, 1.0));
    output.worldPosition = world.xyz;
    output.worldNormal = mul((float3x3)model, input.normal);
    output.position = mul(viewProjection, world);
    return output;
}
