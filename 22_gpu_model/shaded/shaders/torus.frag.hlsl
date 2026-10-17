// The torus's fragment shader in HLSL, for Direct3D 12, as torus.frag is for Vulkan: it lights each pixel by how much it faces the light,
// with a highlight where the light reflects towards the eye.
// Compile it with: dxc -T ps_6_0 -E main torus.frag.hlsl -Fo torus.frag.dxil

// a fragment shader's uniform blocks are in space 3
cbuffer Light : register(b0, space3)
{
    float4 base;      // the material's colour
    float4 direction; // the way the light goes
    float4 eye;       // where the camera is
};

struct Input
{
    float3 worldNormal : TEXCOORD0;
    float3 worldPosition : TEXCOORD1;
};

float4 main(Input input) : SV_Target0
{
    float3 n = normalize(input.worldNormal);
    float3 towardsLight = normalize(-direction.xyz);
    float facing = max(dot(n, towardsLight), 0.0);
    float3 halfway = normalize(towardsLight + normalize(eye.xyz - input.worldPosition));
    float highlight = pow(max(dot(n, halfway), 0.0), 80.0) * 0.35;
    return float4(base.rgb * (0.2 + 0.8 * facing) + highlight, 1.0);
}
