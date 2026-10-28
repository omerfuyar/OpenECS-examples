// The torus's vertex shader: it moves each vertex by the model's matrix, and sees it through the camera's.
#version 450

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 normal;

layout(location = 0) out vec3 worldNormal;
layout(location = 1) out vec3 worldPosition;

// a vertex shader's uniform blocks are in set 1, as SDL's GPU API sets them; gpu gives the first one, binding 0
layout(set = 1, binding = 0) uniform Transform
{
    mat4 model;
    mat4 viewProjection;
};

void main()
{
    vec4 world = model * vec4(position, 1.0);
    worldPosition = world.xyz;
    worldNormal = mat3(model) * normal;
    gl_Position = viewProjection * world;
}
