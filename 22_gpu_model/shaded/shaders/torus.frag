// The torus's fragment shader: it lights each pixel by how much it faces the light, with a highlight where the light reflects towards the eye.
// Compile it with: glslangValidator -V torus.frag -o torus.frag.spv
#version 450

layout(location = 0) in vec3 worldNormal;
layout(location = 1) in vec3 worldPosition;

layout(location = 0) out vec4 color;

// a fragment shader's uniform blocks are in set 3
layout(set = 3, binding = 0) uniform Light
{
    vec4 base;      // the material's colour
    vec4 direction; // the way the light goes
    vec4 eye;       // where the camera is
};

void main()
{
    vec3 n = normalize(worldNormal);
    vec3 towardsLight = normalize(-direction.xyz);
    float facing = max(dot(n, towardsLight), 0.0);
    vec3 halfway = normalize(towardsLight + normalize(eye.xyz - worldPosition));
    float highlight = pow(max(dot(n, halfway), 0.0), 80.0) * 0.35;
    color = vec4(base.rgb * (0.2 + 0.8 * facing) + vec3(highlight), 1.0);
}
