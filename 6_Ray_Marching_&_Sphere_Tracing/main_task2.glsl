#include "common.glsl"
#include "ray.glsl"

#define VISUALIZE_RAY_DIR 0
#define VISUALIZE_SDF_SLICE 1

int visualize_func = VISUALIZE_SDF_SLICE; // change this to change the view

#define PROJECTION_ORTHOGRAPHIC 0
#define PROJECTION_PERSPECTIVE 1

int projection_func = PROJECTION_PERSPECTIVE; // change this to change the projection

///////////////////////////////////////////////////////////////////////

// assembles the world sdf
float sdf(vec3 world_p, float iTime)
{
    // Assemble the scene
    float sphere_r = 1.0;

    return opSmoothUnion(sdSphere(world_p - vec3(0.5, 0., 0.), 1.), sdBox(world_p + vec3(0.5, 0., 0.), vec3(0.2)),
                         0.01);

    return 0.;
}

vec3 shade(float sd)
{
    vec3 col = vec3(1.0) - sign(sd) * vec3(0.9, 0.4, 0.2);

    col *= 1.0 - exp(-6.0 * abs(sd));
    col *= 0.8 + 0.2 * cos(140.0 * sd);
    col = mix(col, vec3(1.0, 0.0, 0.0), 1.0 - smoothstep(0.0, 0.02, abs(sd)));

    return col * (1.0 - exp(-6.0 * abs(sd)));
}

void main()
{
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = gl_FragCoord.xy / iResolution.xy - 0.5;

    vec3 eye = vec3(0, 0, -10);
    vec3 target = vec3(0, 0, 0);

    if (abs(uv.x) < 0.005 / aspect || abs(uv.y) < 0.005)
    {
        gl_FragColor = vec4(vec3(0.), 1.);
        return;
    }

    if (uv.x < 0. && uv.y < 0.)
    {
        eye = vec3(10., 0., 0.);
        uv += 0.25;
        uv *= 2.;
    }
    else if (uv.x < 0. && uv.y > 0.)
    {
        eye = vec3(-10., 0., 0.);
        uv += vec2(0.25, -0.25);
        uv *= 2.;
    }
    else if (uv.x > 0. && uv.y > 0.)
    {
        eye = vec3(0., 0., 10.);
        uv -= 0.25;
        uv *= 2.;
    }
    else if (uv.x > 0. && uv.y < 0.)
    {
        eye = vec3(0., 0., -10.);
        uv -= vec2(0.25, -0.25);
        uv *= 2.;
    }

    uv.x *= aspect;

    vec3 dir = target - eye;
    vec3 up = vec3(0, 1, 0);
    float focal_length = 4.;

    vec3 u, v, w;

    compute_camera_frame(dir, up, u, v, w);

    ray r;
    switch (projection_func)
    {
    case PROJECTION_ORTHOGRAPHIC:
        r = generate_ray_orthographic(uv, eye, u, v, w);
        break;

    case PROJECTION_PERSPECTIVE:
        r = generate_ray_perspective(uv, eye, u, v, w, focal_length);
        break;
    }

    switch (visualize_func)
    {
    case VISUALIZE_RAY_DIR:
        gl_FragColor = vec4(r.direction * 0.5 + 0.5, 1.0);
        break;
    case VISUALIZE_SDF_SLICE:
        float ray_dist = 9. + sin(iTime * 0.25) * 1.0;
        gl_FragColor = vec4(shade(sdf(r.origin + r.direction * ray_dist, iTime)), 1.0);
        break;
    }
}