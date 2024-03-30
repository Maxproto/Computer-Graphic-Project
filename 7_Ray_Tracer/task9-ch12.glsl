#include "common.glsl" // Include common GLSL functions and utilities

// Define constants for material types
#define LAMBERTIAN 0
#define METAL 1
#define DIELECTRIC 2

// Material structure definition
struct Material {
    vec3 color; // Material color
    int material_type; // Type of material
    float material_dependent_var; // Material-dependent variable
};

// Sphere geometry structure definition
struct Sphere {
    vec3 center; // Sphere center
    float radius; // Sphere radius
    Material material; // Material of the sphere
};

// Ray structure definition
struct Ray {
    vec3 origin; // Ray origin
    vec3 direction; // Ray direction
};

// Hit record structure definition
struct HitRecord {
    vec3 point; // Point of intersection
    vec3 normal; // Surface normal at the point of intersection
    float t; // Parameter along the ray
    bool front_face; // Indicates if the ray hit the front face of the object
    Material material; // Material of the intersected object
};

// Function to get a point along a ray at a given parameter value
vec3 RayAt(Ray ray, float t) {
    return ray.origin + t * ray.direction;
}

// Utility function to calculate reflectance
float Reflectance(float cosine, float ref_idx) {
    float r0 = (1.0 - ref_idx) / (1.0 + ref_idx);
    r0 = r0 * r0;
    return r0 + (1.0 - r0) * pow((1.0 - cosine), 5.0);
}

// Function to check for intersection with a sphere
bool HitSphere(Sphere sphere, Ray ray, float ray_tmin, float ray_tmax, inout HitRecord rec) {
    // Intersection calculation using ray-sphere intersection formula
    vec3 oc = ray.origin - sphere.center;
    float a = dot(ray.direction, ray.direction);
    float half_b = dot(oc, ray.direction);
    float c = dot(oc, oc) - sphere.radius * sphere.radius;
    float discriminant = half_b * half_b - a * c;
    if (discriminant < 0.0) {
        return false; // No intersection
    }
    float sqrtd = sqrt(discriminant);
    float root = (-half_b - sqrtd) / a;
    if (root <= ray_tmin || ray_tmax <= root) {
        root = (-half_b + sqrtd) / a;
        if (root <= ray_tmin || ray_tmax <= root) {
            return false; // No intersection within the specified range
        }
    }
    // Record intersection details
    rec.t = root;
    rec.point = RayAt(ray, rec.t);
    rec.normal = (rec.point - sphere.center) / sphere.radius;
    rec.front_face = dot(ray.direction, rec.normal) < 0.0;
    rec.normal = rec.front_face ? rec.normal : -rec.normal;
    rec.material = sphere.material;
    return true;
}

// Function to determine material interaction and scattering
bool MaterialScatter(Ray ray, HitRecord rec, inout vec3 attenuation, inout Ray scattered) {
    if (rec.material.material_type == LAMBERTIAN) {
        // Lambertian scattering
        vec3 direction = rec.normal + random_in_unit_sphere(g_seed);
        scattered = Ray(rec.point, normalize(direction));
        attenuation *= rec.material.color;
        return true;
    } else if (rec.material.material_type == METAL) {
        // Metal material
        vec3 reflected = reflect(ray.direction, rec.normal);
        scattered = Ray(rec.point, normalize(reflected + rec.material.material_dependent_var * random_in_unit_sphere(g_seed)));
        attenuation *= rec.material.color;
        return (dot(scattered.direction, rec.normal) > 0.0);
    } else if (rec.material.material_type == DIELECTRIC) {
        // Dielectric material (glass)
        attenuation *= vec3(1.0, 1.0, 1.0);
        float refraction_ratio = rec.front_face ? (1.0 / rec.material.material_dependent_var) : rec.material.material_dependent_var;
        float cos_theta = min(dot(-ray.direction, rec.normal), 1.0);
        float sin_theta = sqrt(1.0 - cos_theta * cos_theta);
        bool cannot_refract = refraction_ratio * sin_theta > 1.0;
        vec3 direction;
        if (cannot_refract || Reflectance(cos_theta, refraction_ratio) > rand1(g_seed))
            direction = reflect(ray.direction, rec.normal);
        else
            direction = refract(ray.direction, rec.normal, refraction_ratio);

        scattered = Ray(rec.point, normalize(direction));
        return true;
    } else
        return false; // Unrecognized material type
}

// Function to calculate ray color
vec3 RayColor(Ray ray) {
    // Define materials and spheres
    Material material_center = Material(vec3(0.1, 0.2, 0.5), 0, 0.0);
    Material material_left = Material(vec3(1.0, 1.0, 1.0), 2, 1.5);
    Material material_right = Material(vec3(0.8, 0.6, 0.2), 1, 0.0);
    Material material_ground = Material(vec3(0.8, 0.8, 0.0), 0, 0.0);

    Sphere sphere_center = Sphere(vec3(0.0, 0.0, -1.0), 0.5, material_center);
    Sphere sphere_left = Sphere(vec3(-1.0, 0.0, -1.0), 0.5, material_left);
    Sphere sphere_left2 = Sphere(vec3(-1.0, 0.0, -1.0), -0.4, material_left);
    Sphere sphere_right = Sphere(vec3(1.0, 0.0, -1.0), 0.5, material_right);
    Sphere ground = Sphere(vec3(0.0, -100.5, -1.0), 100.0, material_ground);

    vec3 color = vec3(1.0, 1.0, 1.0);
    // Ray tracing loop with material scattering
    for (int i = 0; i < MAX_RECURSION; i++) {
        bool hit_anything = false;
        HitRecord hit_record;
        float ray_tmin = 0.001;
        float closest_so_far = MAX_FLOAT;
        // Check for intersection with each object
        if (HitSphere(sphere_center, ray, ray_tmin, closest_so_far, hit_record)) {
            hit_anything = true;
            closest_so_far = hit_record.t;
        }
        if (HitSphere(sphere_left, ray, ray_tmin, closest_so_far, hit_record)) {
            hit_anything = true;
            closest_so_far = hit_record.t;
        }
        if (HitSphere(sphere_left2, ray, ray_tmin, closest_so_far, hit_record)) {
            hit_anything = true;
            closest_so_far = hit_record.t;
        }
        if (HitSphere(sphere_right, ray, ray_tmin, closest_so_far, hit_record)) {
            hit_anything = true;
            closest_so_far = hit_record.t;
        }
        if (HitSphere(ground, ray, ray_tmin, closest_so_far, hit_record)) {
            hit_anything = true;
            closest_so_far = hit_record.t;
        }
        // If ray intersects with an object, calculate scattering
        if (hit_anything) {
            Ray scattered;
            if (MaterialScatter(ray, hit_record, color, scattered))
                ray = scattered;
            else
                return vec3(0.0, 0.0, 0.0);
        } else {
            // If no intersection, render background gradient
            vec3 unit_direction = normalize(ray.direction);
            float a = 0.5 * (unit_direction.y + 1.0);
            return color * ((1.0 - a) * vec3(1.0, 1.0, 1.0) + a * vec3(0.5, 0.7, 1.0));
        }
    }
    return vec3(0.0, 0.0, 0.0); // Return black if recursion limit reached
}

// Camera structure definition
struct Camera {
    vec3 lookfrom; // Camera position
    vec3 lookat; // Camera target
    vec3 vup; // Camera's up vector
    vec3 viewport_u; // Horizontal viewport vector
    vec3 viewport_v; // Vertical viewport vector
    vec3 viewport_upper_left; // Upper-left corner of the viewport
    float defocus_angle; // Defocus angle for depth of field
    vec3 defocus_disk_u; // Horizontal defocus disk vector
    vec3 defocus_disk_v; // Vertical defocus disk vector
};

// Function to sample the defocus disk for depth of field
vec3 DefocusDiskSample(Camera camera) {
    vec2 p = random_in_unit_disk(g_seed);
    return camera.lookfrom + (p[0] * camera.defocus_disk_u) + (p[1] * camera.defocus_disk_v);
}

// Function to generate a ray from the camera given normalized pixel coordinates
Ray GetRayFromCamera(Camera camera, vec2 uv) {
    vec3 ray_origin = (camera.defocus_angle <= 0.0) ? camera.lookfrom : DefocusDiskSample(camera);
    Ray ray = Ray(ray_origin, normalize(camera.viewport_upper_left + uv.x * camera.viewport_u + uv.y * camera.viewport_v - ray_origin));
    return ray;
}

void main() {
    init_rand(gl_FragCoord.xy, iTime); // Initialize random seed

    // Camera parameters
    float defocus_angle = 10.0;
    float focus_dist = 3.4;
    float vfov = 20.0;
    vec3 lookfrom = vec3(-2.0, 2.0, 1.0);
    vec3 lookat = vec3(0.0, 0.0, -1.0);
    vec3 vup = vec3(0.0, 1.0, 0.0);
    float focal_length = length(lookfrom - lookat);
    float theta = radians(vfov);
    float h = tan(theta / 2.0);
    float viewport_height = 2.0 * h * focus_dist;
    float viewport_width = viewport_height * (iResolution.x / iResolution.y);

    // Camera coordinate system
    vec3 u, v, w;
    w = normalize(lookfrom - lookat);
    u = normalize(cross(vup, w));
    v = cross(u, w);
    vec3 viewport_u = viewport_width * u;
    vec3 viewport_v = viewport_height * -v;
    vec3 viewport_upper_left = lookfrom - (focus_dist * w) - 0.5 * viewport_u - 0.5 * viewport_v;

    // Defocus disk parameters
    float defocus_radius = focus_dist * tan(radians(defocus_angle / 2.0));
    vec3 defocus_disk_u = u * defocus_radius;
    vec3 defocus_disk_v = v * defocus_radius;

    // Define the camera
    Camera camera = Camera(lookfrom, lookat, vup, viewport_u, viewport_v, viewport_upper_left, defocus_angle, defocus_disk_u, defocus_disk_v);

    // Rendering parameters
    int samples_per_pixel = 100;
    vec3 ray_color = vec3(0.0, 0.0, 0.0);
    // Ray tracing loop for each pixel sample
    for (int i = 0; i < samples_per_pixel; i++) {
        vec2 uv = (gl_FragCoord.xy + rand2(g_seed)) / iResolution.xy; // Normalized pixel coordinates with random jitter
        Ray ray = GetRayFromCamera(camera, uv); // Generate ray from camera
        ray_color += RayColor(ray); // Accumulate color from ray tracing
    }
    ray_color /= float(samples_per_pixel); // Average color over samples
    ray_color = pow(ray_color, vec3(1.0 / 2.2)); // Apply gamma correction

    gl_FragColor = vec4(ray_color, 1.0); // Output final color
}
