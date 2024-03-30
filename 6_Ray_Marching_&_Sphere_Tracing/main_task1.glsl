#include "common.glsl"
#include "sdf.glsl"

#define ANIM_SPEED 0.35

#define SPHERE 0
#define BOX 1
#define LINE 2
#define CYLINDER 3
#define CYLINDER_TWO 4
#define CONE 5
#define CONE_TWO 6
#define SPHERE_UNION 7
#define SPHERE_INTERSECTION 8
#define SPHERE_DIFFERENCE 9
#define ROUNDED_BOX 10

// Change this to one of the "#define" values above to check your answers to each subtaks
int sdf_func = ROUNDED_BOX;

//////////////////////////////////////////////////////////////////////////////////
// we will be replacing all of the code below with our own method(s). All of    //
// the changes you make will be disgarded. But feel free to change the main     //
// method to help debug your code.                                              //
//////////////////////////////////////////////////////////////////////////////////

vec3 shade(float sd)
{
    vec3 col = vec3(1.0) - sign(sd) * vec3(0.9, 0.4, 0.2);

    col *= 1.0 - exp(-6.0 * abs(sd));
    col *= 0.8 + 0.2 * cos(140.0 * sd);
    col = mix(col, vec3(1.0, 0.0, 0.0), 1.0 - smoothstep(0.0, 0.02, abs(sd)));

    return col;
}

void main()
{
    // Compute a 2D position based on fragCoord and resolution.
    // Put the origin at the center of the screen.
    vec2 p = (2.0 * gl_FragCoord.xy - iResolution.xy) / iResolution.y;
    // The z position is constant over the whole screen, so we are only visualizing a "slice" through the signed
    // distance field. We use the "iTime" variable to change which slice we show.
    float z = cos(ANIM_SPEED * iTime);
    // Finally put together the 2D position and the z-coordinate for the complete 3D position of this pixel.
    vec3 world_p = vec3(p, z);

    // Put the "progress bar" at the bottom of the screen to show which slice we are visualizing.
    if (p.y < -0.95)
        gl_FragColor = vec4(shade_progress_bar(p, iResolution.xy, z), 1.0);
    else
    {
        // Assemble the scene
        float sphere_r = 1.0;

        vec3 box_b = vec3(0.5);

        vec2 line_a = vec2(0.5);
        vec2 line_b = vec2(-0.5);

        vec3 cylinder_a = vec3(0.0, -0.7, 0.0);
        vec3 cylinder_b = vec3(0.0, 0.7, 0.0);
        float cylinder_r = 0.7;

        vec3 cylinder_two_a = vec3(0.0, 0.0, -0.7);
        vec3 cylinder_two_b = vec3(0.0, 0.0, 0.7);
        float cylinder_two_r = 0.7;

        vec3 cone_a = vec3(0.0, -0.8, 0.0);
        vec3 cone_b = vec3(0.0, 0.8, 0.0);
        float cone_ra = 0.8;
        float cone_rb = 0.25;

        vec3 cone_two_a = vec3(0.0, 0.0, -0.8);
        vec3 cone_two_b = vec3(0.0, 0.0, 0.8);
        float cone_two_ra = 0.8;
        float cone_two_rb = 0.25;

        // Switch between the different primitives.
        if (sdf_func == SPHERE)
            gl_FragColor = vec4(shade(sdSphere(world_p, sphere_r)), 1.0);

        else if (sdf_func == BOX)
            gl_FragColor = vec4(shade(sdBox(world_p, box_b)), 1.0);

        else if (sdf_func == LINE)
        {
            // line is slightly different. Since this is a 2D object we will spin the camera along z instead of moving
            // along the z axis
            vec2 line_world_p = vec2(cos(z) * p.x - sin(z) * p.y, sin(z) * p.x + cos(z) * p.y);

            gl_FragColor = vec4(shade(sdLine(line_world_p, line_a, line_b)), 1.0);
        }

        else if (sdf_func == CYLINDER)
            gl_FragColor = vec4(shade(sdCylinder(world_p, cylinder_a, cylinder_b, cylinder_r)), 1.0);
        else if (sdf_func == CYLINDER_TWO)
            gl_FragColor = vec4(shade(sdCylinder(world_p, cylinder_two_a, cylinder_two_b, cylinder_two_r)), 1.0);

        else if (sdf_func == CONE)
            gl_FragColor = vec4(shade(sdCone(world_p, cone_a, cone_b, cone_ra, cone_rb)), 1.0);
        else if (sdf_func == CONE_TWO)
            gl_FragColor = vec4(shade(sdCone(world_p, cone_two_a, cone_two_b, cone_two_ra, cone_two_rb)), 1.0);
        else if (sdf_func == SPHERE_UNION)
        {
            world_p[2] = 0.f;
            float sdf =
                opSmoothUnion(sdSphere(world_p - vec3(0.4, 0.f, 0.f), 0.7),
                              sdSphere(world_p + vec3(0.4, 0.f, 0.f), 0.7), 0.5 * cos(ANIM_SPEED * iTime) + 0.5);

            gl_FragColor = vec4(shade(sdf), 1.0);
        }
        else if (sdf_func == SPHERE_INTERSECTION)
        {
            world_p[2] = 0.f;
            float sdf =
                opSmoothIntersection(sdSphere(world_p - vec3(0.4, 0.f, 0.f), 0.7),
                                     sdSphere(world_p + vec3(0.4, 0.f, 0.f), 0.7), 0.5 * cos(ANIM_SPEED * iTime) + 0.5);

            gl_FragColor = vec4(shade(sdf), 1.0);
        }
        else if (sdf_func == SPHERE_DIFFERENCE)
        {
            world_p[2] = 0.f;
            float sdf =
                opSmoothSubtraction(sdSphere(world_p - vec3(0.4, 0.f, 0.f), 0.7),
                                    sdSphere(world_p + vec3(0.4, 0.f, 0.f), 0.7), 0.5 * cos(ANIM_SPEED * iTime) + 0.5);

            gl_FragColor = vec4(shade(sdf), 1.0);
        }
        else if (sdf_func == ROUNDED_BOX)
        {
            world_p[2] = 0.f;
            float sdf = sdBox(world_p, vec3(0.45));
            sdf = opRound(sdf, 0.15 * cos(ANIM_SPEED * iTime) + 0.15);

            gl_FragColor = vec4(shade(sdf), 1.0);
        }
        else
            gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
}