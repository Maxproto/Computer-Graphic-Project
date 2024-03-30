#include "sdf.glsl"
#define EPSILON 1e-4

////////////////////////////////////////////////////
// TASK 2 - Write up your ray generation code here:
////////////////////////////////////////////////////
//
// Ray
//
struct ray
{
    vec3 origin;    // This is the origin of the ray
    vec3 direction; // This is the direction the ray is pointing in
};

// TASK 2.1
// Computes the camera's coordinate frame based on its direction, an up vector, and the camera's position.
// dir: The direction vector the camera is pointed towards.
// up: The world's up vector, used to ensure the camera's orientation is aligned correctly.
// u, v, w: Output vectors representing the camera's coordinate frame.
void compute_camera_frame(vec3 dir, vec3 up, out vec3 u, out vec3 v, out vec3 w)
{
    // The camera's forward vector (w) is the negative of the normalized direction vector.
    // This is because in a right-handed coordinate system, the camera looks down the negative z-axis.
    w = normalize(-dir);

    // The camera's right vector (u) is perpendicular to both the up vector and the forward vector.
    // This is calculated using the cross product of the up vector and the forward vector.
    u = normalize(cross(up, w));

    // The camera's up vector (v) is perpendicular to both the forward vector and the right vector.
    // This ensures an orthonormal basis for the camera's coordinate frame.
    v = normalize(cross(w, u));
}


// TASK 2.2
// Generates a ray for orthographic projection given the uv coordinates on the image plane.
// uv: The uv position of the pixel on the image plane.
// e: The eye position, or the camera's position in world space.
// u, v, w: The camera's coordinate frame vectors.
// Returns a ray object initialized for orthographic projection.
ray generate_ray_orthographic(vec2 uv, vec3 e, vec3 u, vec3 v, vec3 w)
{
    // The ray origin is calculated by offsetting the eye position by the uv coordinates
    // scaled by the camera's right (u) and up (v) vectors. This positions the ray correctly on the image plane.
    vec3 origin = e + uv.x * u + uv.y * v;

    // The ray direction is constant and opposite to the camera's forward vector (w) for orthographic projection,
    // as all rays are parallel and perpendicular to the image plane.
    vec3 direction = -w;

    // Create and return the ray with the calculated origin and direction.
    return ray(origin, direction);
}


// TASK 2.3
// Generates a ray for perspective projection given the uv coordinates on the image plane.
// uv: The uv position of the pixel on the image plane.
// eye: The eye position, or the camera's position in world space.
// u, v, w: The camera's coordinate frame vectors.
// focal_length: The focal length of the camera, affecting the field of view.
// Returns a ray object initialized for perspective projection.
ray generate_ray_perspective(vec2 uv, vec3 eye, vec3 u, vec3 v, vec3 w, float focal_length)
{
    // The ray direction is calculated by combining the camera's right (u) and up (v) vectors scaled by the uv coordinates
    // and the camera's forward vector (w) scaled by the negative focal length. This creates a perspective effect where
    // rays converge at the eye position.
    vec3 direction = normalize(u * uv.x + v * uv.y - focal_length * w);

    // Create and return the ray with the eye position as the origin and the calculated direction.
    // This ensures that rays originate from the camera and spread outwards, simulating perspective.
    return ray(eye, direction);
}


////////////////////////////////////////////////////
// TASK 3 - Write up your code here:
////////////////////////////////////////////////////

// TASK 3.1
bool ray_march(ray r, float step_size, int max_iter, settings setts, out vec3 hit_loc, out int iters)
{

// ################ Edit your code below ################

    hit_loc = r.origin + r.direction * (-r.origin.y / r.direction.y);
    iters = 1;
    // TODO: implement ray marching

    // it should work as follows:
    //
    // while (hit has not occured && iteration < max_iters)
    //     march a distance of step_size forwards
    //     evaluate the sdf
    //     if a collision occurs (SDF < EPSILON)
    //         return hit location and iteration count
    // return false

    // Start marching from the initial position
    float t = step_size;
    for (int i = 0; i < max_iter; ++i) {
        // Calculate the current position along the ray
        vec3 current_pos = r.origin + t * r.direction;

        // Evaluate the signed distance function (SDF) for the current position
        float sdf_val = world_sdf(current_pos, iTime, setts);

        // Check if we're close enough to the surface to consider it a hit
        if (sdf_val < EPSILON) {
            hit_loc = current_pos; // Update hit location to current position
            iters += i; // Update iteration count to current iteration
            return true; // Return true indicating a hit was found
        }

        // Increment t by step size to advance the ray
        t += step_size;
    }

    // If we reach here, no hit was detected within the maximum iterations
    iters = max_iter; // Set iteration count to max_iter indicating no hit
    return false;
}

// TASK 3.2
bool sphere_tracing(ray r, int max_iter, settings setts, out vec3 hit_loc, out int iters)
{

// ################ Edit your code below ################

    hit_loc = r.origin + r.direction * (-r.origin.y / r.direction.y);
    iters = 1;

    // TODO: implement sphere tracing

    // it should work as follows:
    //
    // while (hit has not occured && iteration < max_iters)
    //     set the step size to be the SDF
    //     march step size forwards
    //     if a collision occurs (SDF < EPSILON)
    //         return hit location and iteration count
    // return false
    vec3 current_position = r.origin; // Initialize the current position to the ray's origin

    // Iterate up to a maximum number of iterations to find a hit
    for (int i = 0; i < max_iter; ++i) {
        // Calculate the step size based on the SDF at the current position (key difference: dynamic step size)
        float step_size = world_sdf(current_position, iTime, setts);

        // If the step size is less than EPSILON, a surface has been hit
        if (step_size < EPSILON) {
            hit_loc = current_position; // Update the hit location
            iters += i; // Update the iteration count
            return true; // Return true to indicate a hit has been found
        }

        // Move the current position forward along the ray by the step size
        current_position += step_size * r.direction;
    }

    // If no hit is found within the maximum number of iterations
    iters = max_iter; // Ensure iters reflects the maximum iterations attempted
    return false; 
}

////////////////////////////////////////////////////
// TASK 4 - Write up your code here:
////////////////////////////////////////////////////

float map(vec3 p, settings setts)
{
    return world_sdf(p, iTime, setts);
}

// TASK 4.1
vec3 computeNormal(vec3 p, settings setts)
{

// ################ Edit your code below ################
    // Define a small offset to use for gradient calculation
    const float offset = 1e-4;

    // Calculate the SDF value at the original position
    float sdfOriginal = world_sdf(p, iTime, setts);

    // Calculate the SDF values at slightly offset positions in each axis direction
    float sdfOffsetX = world_sdf(p + vec3(offset, 0.0, 0.0), iTime, setts) - sdfOriginal;
    float sdfOffsetY = world_sdf(p + vec3(0.0, offset, 0.0), iTime, setts) - sdfOriginal;
    float sdfOffsetZ = world_sdf(p + vec3(0.0, 0.0, offset), iTime, setts) - sdfOriginal;

    // Construct the gradient vector from the differences in SDF values
    vec3 gradient = vec3(sdfOffsetX, sdfOffsetY, sdfOffsetZ);

    // Normalize the gradient to get the unit normal vector at the position
    return normalize(gradient);
}
