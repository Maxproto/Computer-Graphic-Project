#define SPHERE 0
#define BOX 1
#define CYLINDER 3
#define CONE 5
#define NONE 4

////////////////////////////////////////////////////
// TASK 1 - Write up your SDF code here:
////////////////////////////////////////////////////

// returns the signed distance to a sphere from position p
float sdSphere(vec3 p, float r)
{
    return length(p) - r;
}

//
// Task 1.1
//
// Returns the signed distance to a line segment.
//
// p is the position you are evaluating the distance to.
// a and b are the end points of your line.
//
float sdLine(in vec2 p, in vec2 a, in vec2 b)
{
// ################ Edit your code below ################
    vec2 ab = b - a;
    vec2 ap = p - a;
    float t = dot(ap, ab) / dot(ab, ab);
    t = clamp(t, 0.0, 1.0); // Clamp t to the range [0, 1] to ensure it's within the line segment
    vec2 closestPoint = a + t * ab;
    return length(p - closestPoint);

}

//
// Task 1.2
//
// Returns the signed distance from position p to an axis-aligned box centered at the origin with half-length,
// half-height, and half-width specified by half_bounds
//
float sdBox(vec3 p, vec3 half_bounds)
{
// ################ Edit your code below ################
    // The distance of p from the box in each axis
    vec3 d = abs(p) - half_bounds;
    
    // The outside distance is the max between 0 and the largest positive distance to the box's sides
    float outsideDist = length(max(d, vec3(0.0)));
    
    // The inside distance is the minimum distance inside the box, which is negative or zero
    // It is the largest negative value among the distances in each axis, or 0 if the point is outside
    float insideDist = min(max(d.x, max(d.y, d.z)), 0.0);
    
    // The signed distance is the combination of the outside and inside distances
    return outsideDist + insideDist;
}

//
// Task 1.3
//
// Returns the signed distance from position p to a cylinder or radius r with an axis connecting the two points a and b.
//
float sdCylinder(vec3 p, vec3 a, vec3 b, float r)
{
// ################ Edit your code below ################
    // Compute the vector from end point b to a (cylinder's axis direction) and the vector from point p to a
    vec3 ba = a - b;
    vec3 pa = a - p;

    // Normalize the cylinder's axis direction
    vec3 ba_normalized = normalize(ba);

    // Project pa onto the cylinder's axis direction to find the projection length
    float t = dot(pa, ba_normalized);

    // Calculate the closest point on the cylinder axis to p
    vec3 projection = a - ba_normalized * t;

    // Calculate the distance from p to the surface of the cylinder
    float dist = length(p - projection) - r;

    // Determine where the projection lies relative to the cylinder caps
    float k = dot(projection - b, ba) / dot(ba, ba);

    // Determine if the projected point falls within the cylinder segment
    if (k >= 0.0 && k <= 1.0) {
        // Point falls within the cylinder's linear bounds
        
        if (dist > 0.0) {
            // Point is outside the cylinder, return the positive distance to its surface
            return dist;
        } else {
            // Point is inside the cylinder; calculate the distance to the closest end cap
            // and use the negative distance to indicate inside location
            float distToA = length(projection - a);
            float distToB = length(projection - b);
            return max(max(-distToA, -distToB), dist); // Return the max of negative distances or dist itself
        }
    } else if (k > 1.0) {
        // Projection is beyond point b, calculate distance as if from a sphere at b
        
        if (dist > 0.0) {
            // Point is outside, compute Euclidean distance to the end cap and adjust for cylinder radius
            return sqrt(dist * dist + length(projection - a) * length(projection - a));
        } else {
            // Point is inside, return the distance to the end cap directly
            return length(projection - a);
        }
    } else {
        // Projection is before point a, handle similarly to the case above but for point a
        
        if (dist > 0.0) {
            // Point is outside, compute Euclidean distance to the end cap and adjust for cylinder radius
            return sqrt(dist * dist + length(projection - b) * length(projection - b));
        } else {
            // Point is inside, return the distance to the end cap directly
            return length(projection - b);
        }
    }
}

//
// Task 1.4
//
// Returns the signed distance from position p to a cone with axis connecting points a and b and (ra, rb) being the
// radii at a and b respectively.
//
float sdCone(vec3 p, vec3 a, vec3 b, float ra, float rb) {
    // Define the vector from b to a, representing the cone's axis
    vec3 ba = a - b;

    // Define the vector from p to a
    vec3 pa = a - p;

    // Normalize the cone's axis to get a direction vector
    vec3 ba_normalized = normalize(ba);

    // Project the vector from p to a onto the cone's axis
    float t = dot(pa, ba_normalized);

    // Calculate the projection of p onto the cone's axis
    vec3 projection = a - ba_normalized * t;

    // Calculate the linear interpolation factor for the radius at the projection point
    float k = dot(projection - b, ba) / dot(ba, ba);

    if (k >= 0.0 && k <= 1.0) {
        // If the projection is within the cone's linear segment
        // Interpolate the radius at the projection point between rb and ra
        float interpolatedRadius = rb + k * (ra - rb);
        // Calculate the distance from p to the cone's surface
        float dist = length(p - projection) - interpolatedRadius;

        if (dist > 0.0) {
            // Point is outside the cone, return positive distance
            return dist;
        } else {
            // Point is inside the cone, return the largest negative distance to indicate inside
            // This compares the distance to both ends and the interpolated surface
            return max(max(-length(projection - a), -length(projection - b)), dist);
        }
    } else if (k > 1.0) {
        // If the projection is beyond the end at a
        // Calculate the distance from p to the end at a, considering ra
        float distToEndA = length(p - projection) - ra;
        if (distToEndA > 0.0) {
            // Point is outside the cone's end, return distance accounting for curvature
            return sqrt(distToEndA * distToEndA + length(projection - a) * length(projection - a));
        } else {
            // Point is inside towards end a, return direct distance
            return length(projection - a);
        }
    } else {
        // If the projection is before the start at b
        // Calculate the distance from p to the end at b, considering rb
        float distToEndB = length(p - projection) - rb;
        if (distToEndB > 0.0) {
            // Point is outside the cone's end, return distance accounting for curvature
            return sqrt(distToEndB * distToEndB + length(projection - b) * length(projection - b));
        } else {
            // Point is inside towards end b, return direct distance
            return length(projection - b);
        }
    }
}


// Task 1.5
float opSmoothUnion(float d1, float d2, float k)
{
// Performs a smooth union operation between two SDFs.
// d1, d2: The signed distances to the two SDFs.
// k: The smoothing amount; higher values result in a smoother blend.
// ################ Edit your code below ################
    // Calculate the polynomial smooth min (or smooth union) factor
    float h = max(k - abs(d1 - d2), 0.0);
    // Return the smoothed minimum distance adjusted by the smooth factor
    return min(d1, d2) - h * h / (4.0 * k);
}

// Task 1.6
float opSmoothSubtraction(float d1, float d2, float k)
{
// Performs a smooth subtraction operation between two SDFs.
// d1, d2: The signed distances to the two SDFs, with d2 being subtracted from d1.
// k: The smoothing amount; affects the transition between the shapes.
// ################ Edit your code below ################
    // Use smooth union with inverted d2 for smooth subtraction,
    // effectively carving d2 out of d1 with a smooth transition.
    return -opSmoothUnion(d1, -d2, k);
}

// Task 1.7
float opSmoothIntersection(float d1, float d2, float k)
{
// Performs a smooth intersection operation between two SDFs.
// d1, d2: The signed distances to the two SDFs.
// k: The smoothing amount; controls the sharpness of the intersection edge.
// ################ Edit your code below ################
    // Use smooth union with both distances inverted for smooth intersection,
    // resulting in a smooth blend at the intersection of d1 and d2.
    return -opSmoothUnion(-d1, -d2, k);
}

// Task 1.8
float opRound(float d, float iso)
{
// Rounds the edges of an SDF.
// d: The signed distance to the SDF.
// iso: The radius of the rounding; larger values result in more pronounced rounding.
// ################ Edit your code below ################
    // Subtract the rounding radius from the distance to create rounded edges.
    // This operation effectively softens the edges of the shape by the iso value.
    return d - iso;
}

////////////////////////////////////////////////////
// FOR TASK 3 & 4
////////////////////////////////////////////////////

#define TASK3 3
#define TASK4 4

//
// Render Settings
//
struct settings
{
    int sdf_func;      // Which primitive is being visualized (e.g. SPHERE, BOX, etc.)
    int shade_mode;    // How the primiive is being visualized (GRID or COST)
    int marching_type; // Should we use RAY_MARCHING or SPHERE_TRACING?
    int task_world;    // Which task is being rendered (TASK3 or TASK4)?
    float anim_speed;  // Specifies the animation speed
};

// returns the signed distance to an infinite plane with a specific y value
float sdPlane(vec3 p, float z)
{
    return p.y - z;
}

float world_sdf(vec3 p, float time, settings setts)
{
    if (setts.task_world == TASK3)
    {
        if ((setts.sdf_func == SPHERE) || (setts.sdf_func == NONE))
        {
            return min(sdSphere(p - vec3(0.f, 0.25 * cos(setts.anim_speed * time), 0.f), 0.4f), sdPlane(p, 0.f));
        }
        if (setts.sdf_func == BOX)
        {
            return min(sdBox(p - vec3(0.f, 0.25 * cos(setts.anim_speed * time), 0.f), vec3(0.4f)), sdPlane(p, 0.f));
        }
        if (setts.sdf_func == CYLINDER)
        {
            return min(sdCylinder(p - vec3(0.f, 0.25 * cos(setts.anim_speed * time), 0.f), vec3(0.0f, -0.4f, 0.f),
                                  vec3(0.f, 0.4f, 0.f), 0.2f),
                       sdPlane(p, 0.f));
        }
        if (setts.sdf_func == CONE)
        {
            return min(sdCone(p - vec3(0.f, 0.25 * cos(setts.anim_speed * time), 0.f), vec3(-0.4f, 0.0f, 0.f),
                              vec3(0.4f, 0.0f, 0.f), 0.1f, 0.6f),
                       sdPlane(p, 0.f));
        }
    }

    if (setts.task_world == TASK4)
    {
        float dist = 100000.0;

        dist = sdPlane(p.xyz, -0.3);
        dist = opSmoothUnion(dist, sdSphere(p - vec3(0.f, 0.25 * cos(setts.anim_speed * time), 0.f), 0.4f), 0.1);
        dist = opSmoothUnion(
            dist, sdSphere(p - vec3(sin(time), 0.25 * cos(setts.anim_speed * time * 2. + 0.2), cos(time)), 0.2f), 0.01);
        dist = opSmoothSubtraction(sdBox(p - vec3(0.f, 0.25, 0.f), 0.1 * vec3(2. + cos(time))), dist, 0.2);
        dist = opSmoothUnion(
            dist, sdSphere(p - vec3(sin(-time), 0.25 * cos(setts.anim_speed * time * 25. + 0.2), cos(-time)), 0.2f),
            0.1);

        return dist;
    }

    return 1.f;
}