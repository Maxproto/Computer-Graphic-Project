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

void main() {
    vec2 normalizedCoordinates = gl_FragCoord.xy / iResolution.xy;
    float aspectRatio = iResolution.x / iResolution.y;
    float viewportHeight = 2.0;
    float viewportWidth = aspectRatio * viewportHeight;
    vec3 cameraOrigin = vec3(0.0, 0.0, 0.0);
    vec3 viewportOrigin = cameraOrigin - vec3(viewportWidth / 2.0, viewportHeight / 2.0, 1.0);
    vec3 direction = viewportOrigin + vec3(normalizedCoordinates.x * viewportWidth, normalizedCoordinates.y * viewportHeight, 0.0) - cameraOrigin;
    Ray ray = Ray(cameraOrigin, normalize(direction));
    vec3 color = get_color_from_ray(ray);
    gl_FragColor = vec4(color, 1.0);
}
