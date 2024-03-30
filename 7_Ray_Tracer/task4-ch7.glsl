#include "common.glsl"

// Definition of a ray in 3D space
struct Ray {
    vec3 origin; // Origin point of the ray
    vec3 direction; // Direction vector of the ray
};

// Computes a point along a ray at distance t
vec3 calculate_ray_point(vec3 origin, vec3 direction, float t) {
    return origin + t * direction;
}

// Representation of a sphere
struct Sphere {
    vec3 center; // Center of the sphere
    float radius; // Radius of the sphere
};

// Structure to hold information about a ray-sphere intersection
struct Intersection {
    vec3 position; // Intersection point
    vec3 normal; // Normal at the intersection
    float time; // Time at which the intersection occurs
};

// Checks if a ray hits a sphere and returns intersection information
Intersection check_sphere_intersection(Sphere sphere, Ray ray) {
    vec3 oc = ray.origin - sphere.center;
    float a = dot(ray.direction, ray.direction);
    float b = 2.0 * dot(oc, ray.direction);
    float c = dot(oc, oc) - sphere.radius * sphere.radius;
    float discriminant = b * b - 4.0 * a * c;
    Intersection result;

    if (discriminant < 0.0) {
        result.time = -1.0; // Indicates no intersection
    } else {
        float t = (-b - sqrt(discriminant)) / (2.0 * a);
        result.position = calculate_ray_point(ray.origin, ray.direction, t);
        result.normal = normalize(result.position - sphere.center);
        result.time = t;
    }
    return result;
}

// Determines the color based on the ray's intersection with objects
vec3 get_color_from_ray(Ray ray) {
    Sphere smallSphere = Sphere(vec3(0.0, 0.0, -1.0), 0.5);
    Intersection smallSphereHit = check_sphere_intersection(smallSphere, ray);
    if (smallSphereHit.time > 0.0) {
        return 0.5 * (smallSphereHit.normal + vec3(1.0, 1.0, 1.0));
    }

    Sphere largeSphere = Sphere(vec3(0.0, -100.5, -1.0), 100.0);
    Intersection largeSphereHit = check_sphere_intersection(largeSphere, ray);
    if (largeSphereHit.time > 0.0) {
        return 0.5 * (largeSphereHit.normal + vec3(1.0, 1.0, 1.0));
    }

    vec3 unitDirection = normalize(ray.direction);
    float t = 0.5 * (unitDirection.y + 1.0);
    return (1.0 - t) * vec3(1.0) + t * vec3(0.5, 0.7, 1.0);
}

// Main rendering function
void main() {
    init_rand(gl_FragCoord.xy, iTime);

    // Calculate normalized screen coordinates
    vec2 screenCoord = gl_FragCoord.xy / iResolution.xy;
    float screenAspectRatio = iResolution.x / iResolution.y;
    float viewHeight = 2.0;
    float viewWidth = screenAspectRatio * viewHeight;

    // Define camera properties
    struct CameraSettings {
        vec3 position;
        int samplesPerPixel;
    };
    CameraSettings camera;
    camera.position = vec3(0.0, 0.0, 0.0);
    camera.samplesPerPixel = 100;

    // Calculate viewport origin based on camera settings
    vec3 viewOrigin = camera.position - vec3(viewWidth / 2.0, viewHeight / 2.0, 1.0);
    
    // Initialize color accumulation variable
    vec3 accumulatedColor = vec3(0.0);
    float randomSeed = 0.0;

    // Sample multiple rays per pixel for anti-aliasing
    for (int sampleIndex = 0; sampleIndex < camera.samplesPerPixel; ++sampleIndex) {
        float u = (gl_FragCoord.x + rand1(randomSeed)) / iResolution.x;
        float v = (gl_FragCoord.y + rand1(randomSeed)) / iResolution.y;
        vec3 direction = viewOrigin + vec3(u * viewWidth, v * viewHeight, 0.0) - camera.position;
        Ray ray = Ray(camera.position, normalize(direction));
        accumulatedColor += get_color_from_ray(ray);
    }

    // Average the accumulated color by the number of samples
    accumulatedColor /= float(camera.samplesPerPixel);
    
    // Output the final color
    gl_FragColor = vec4(accumulatedColor, 1.0);
}

