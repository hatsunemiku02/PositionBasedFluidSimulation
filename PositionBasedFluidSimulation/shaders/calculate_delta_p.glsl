#version 450

// compute shader
// calculate lambda
// save lambda in pos_curr[].w

layout(local_size_x = 128, local_size_y = 1, local_size_z = 1)in;

layout(std430, binding = 0) buffer pos_curr_buffer {
    vec4 pos_curr[];
};

layout(std430, binding = 1) buffer grid_partical_count_buffer {
    uint grid_partical_count[];
};

layout(std430, binding = 2) buffer grid_particals_buffer {
    struct {
        vec3 pos;
        uint index;
    } grid_particals[];
};

layout(std430, binding = 3) buffer pos_delta_buffer {
    vec4 pos_delta[];
};

uniform float cellsize;

uniform int grid_edge_count;

uniform int cellmaxparticalcount;

uniform float kernel_radius;

float POLY6(float r) {
    float kernel_r2 = kernel_radius * kernel_radius;
    float kernel_r9 = kernel_r2 * kernel_r2 * kernel_r2 * kernel_r2 * kernel_radius;
    // 315/(64*pi*h^9)
    return (kernel_r2 - r * r)*(kernel_r2 - r * r)*(kernel_r2 - r * r)*1.566681471 / kernel_r9;
}
float POLY6_gradient(float r) {
    float kernel_r2 = kernel_radius * kernel_radius;

    float kernel_r9 = kernel_r2 * kernel_r2 * kernel_r2 * kernel_r2 * kernel_radius;

    // 945/(32*pi*h^9)
    return -r * (kernel_r2 - r * r)*(kernel_r2 - r * r)*9.40008826 / kernel_r9;
}

float scorr(float r) {
    float tmp = POLY6(r) / POLY6(0.1*kernel_radius);

    return -0.1*tmp*tmp*tmp*tmp;
}

const float rho0 = 1000.0;

void main(void)
{

    int grid_edge_count2 = grid_edge_count * grid_edge_count;
    
    vec4 pos_full = pos_curr[gl_GlobalInvocationID.x];

    float lambda_i = pos_full.w;

    vec3 pos = pos_full.xyz;

    vec3 pos_min = pos - vec3(0.41);
    vec3 pos_max = pos + vec3(0.41);

    ivec3 grid_v = ivec3((pos + vec3(6, 6, 6)) / cellsize);

    ivec3 grid_v_min = ivec3((pos_min + vec3(6, 6, 6)) / cellsize);
    ivec3 grid_v_max = ivec3((pos_max + vec3(6, 6, 6)) / cellsize);

    vec3 deltaP = vec3(0);

    // for each neighbiyr cell
    for (int x = grid_v_min.x; x <= grid_v_max.x; x++)for (int y = grid_v_min.y; y <= grid_v_max.y; y++)for (int z = grid_v_min.z; z <= grid_v_max.z; z++) {

        uint cellidx = z * grid_edge_count2 + y * grid_edge_count + x;

        uint partical_count = grid_partical_count[cellidx];

        // for each partical in the neightbour cell
        for (uint i = 0; i < partical_count; i++) {

            uint neighbour_idx = grid_particals[cellidx*cellmaxparticalcount + i].index;

            if (neighbour_idx != gl_GlobalInvocationID.x) {

                vec3 norm = pos - grid_particals[cellidx*cellmaxparticalcount + i].pos;

                float r = length(norm);

                if (r < kernel_radius) {

                    float lambda_j = pos_curr[neighbour_idx].w;
                    float g = POLY6_gradient(r);
                    norm = norm / r * g;
                    deltaP += norm * (lambda_i+lambda_j + scorr(r)) / rho0;

                }


            }
        }


    }
    float l = length(deltaP);
    if (l > 0.3) {
        deltaP = deltaP / l * 0.3;
    }
    pos_delta[gl_GlobalInvocationID.x] = vec4(deltaP, 0);
}