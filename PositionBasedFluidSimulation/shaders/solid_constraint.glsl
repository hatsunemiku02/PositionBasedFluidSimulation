#version 450

layout(local_size_x = 128, local_size_y = 1, local_size_z = 1)in;


layout(std430, binding = 0) buffer partical_buffer {
    struct {
        vec3 pos;
        float lambda;
        vec3 pos_prev;

        uint grid_idx;

        vec3 delta_p;

        uint idx_in_grid;
    }particals[];
};

layout(std430, binding = 1) buffer voxel_buffer {
    struct{
        vec3 norm;// plane normal
        int solid;
        vec3 pos;// one point on the plane

        int _padding_;
    }voxels[];
};

layout(std430, binding = 2) buffer fluid_impulse_buffer {
    struct {
        vec3 pos;// impulse position in local space
        float depth;
        vec3 normal;// impulse normal in local space
        int _padding_;
    }fluid_impulses[];
};

layout(binding = 0, offset = 0) uniform atomic_uint impulse_counter;

uniform vec3 bBoxMin;
uniform ivec3 voxelSpaceSize;
uniform float voxelSize;


uniform mat4 mView;
uniform mat3 mModelRot;

uniform bool isFixed;

void main(void)
{
    vec3 pos = (mView * vec4(particals[gl_GlobalInvocationID.x].pos, 1.0)).xyz;


    ivec3 ipos = ivec3((pos - bBoxMin)/ voxelSize);

    if (any(lessThan(ipos, ivec3(0))) || any(greaterThanEqual(ipos, voxelSpaceSize)))return;

    struct {
        vec3 norm;// plane normal
        int solid;
        vec3 pos;// one point on the plane
        int _padding_;
    } voxel = voxels[ipos.x * voxelSpaceSize.y*voxelSpaceSize.z + ipos.y*voxelSpaceSize.z + ipos.z];

    if (voxel.solid==0)return;

    float depth = dot(voxel.pos - pos, voxel.norm);
    if (depth < 0.0001)return;


    vec3 delta = depth*voxel.norm;

    particals[gl_GlobalInvocationID.x].pos += mModelRot * delta;

    if (isFixed) return;

    uint impulse_idx = atomicCounterIncrement(impulse_counter);
    fluid_impulses[impulse_idx].normal = voxel.norm;
    fluid_impulses[impulse_idx].pos = voxel.pos;
    fluid_impulses[impulse_idx].depth = -depth;

}