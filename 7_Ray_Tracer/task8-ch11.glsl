#include "common.glsl"

#define TYPE_DIFFUSE 0
#define TYPE_METAL 1
#define TYPE_GLASS 2

// Material definition
struct Material {
    vec3 tint;
    int type;
    float parameter;
};

// Sphere definition
struct Sphere {
    vec3 position;
    float radius;
    Material material;
};

// Ray definition
struct Ray {
    vec3 start;
    vec3 direction;
};

// Hit record definition
struct HitRecord {
    vec3 point;
    vec3 normal;
    float t;
    bool front;
    Material material;
};

// Function to get point along a ray
vec3 PointAt(Ray ray, float t) {
    return ray.start + t * ray.direction;
}

// Function to calculate reflection coefficient
float Reflectance(float cosine, float refraction_index) {
    float r0 = (1.0 - refraction_index) / (1.0 + refraction_index);
    r0 = r0 * r0;
    return r0 + (1.0 - r0) * pow((1.0 - cosine), 5.0);
}

// Intersection function for spheres
bool HitSphere(Sphere sphere, Ray ray, float t_min, float t_max, inout HitRecord hit_record) {
    vec3 oc = ray.start - sphere.position;
    float a = dot(ray.direction, ray.direction);
    float half_b = dot(oc, ray.direction);
    float c = dot(oc, oc) - sphere.radius * sphere.radius;
    float discriminant = half_b * half_b - a * c;
    if (discriminant > 0.0) {
        float sqrt_discriminant = sqrt(discriminant);
        float root = (-half_b - sqrt_discriminant) / a;
        if (root < t_min || t_max < root) {
            root = (-half_b + sqrt_discriminant) / a;
            if (root < t_min || t_max < root) {
                return false;
            }
        }
        hit_record.t = root;
        hit_record.point = PointAt(ray, hit_record.t);
        hit_record.normal = (hit_record.point - sphere.position) / sphere.radius;
        hit_record.front = dot(ray.direction, hit_record.normal) < 0.0;
        hit_record.normal = hit_record.front ? hit_record.normal : -hit_record.normal;
        hit_record.material = sphere.material;
        return true;
    }
    return false;
}

// Material scattering function
bool ScatterMaterial(Ray ray, HitRecord hit_record, inout vec3 attenuation, inout Ray scattered_ray) {
    if (hit_record.material.type == TYPE_DIFFUSE) {
        vec3 target = hit_record.point + hit_record.normal + random_in_unit_sphere(g_seed);
        scattered_ray = Ray(hit_record.point, normalize(target - hit_record.point));
        attenuation *= hit_record.material.tint;
        return true;
    }
    else if (hit_record.material.type == TYPE_METAL) {
        vec3 reflected = reflect(ray.direction, hit_record.normal);
        scattered_ray = Ray(hit_record.point, normalize(reflected + hit_record.material.parameter * random_in_unit_sphere(g_seed)));
        attenuation *= hit_record.material.tint;
        return dot(scattered_ray.direction, hit_record.normal) > 0.0;
    }
    else if (hit_record.material.type == TYPE_GLASS) {
        attenuation *= vec3(1.0, 1.0, 1.0);
        float refraction_ratio = hit_record.front ? (1.0 / hit_record.material.parameter) : hit_record.material.parameter;
        vec3 unit_direction = normalize(ray.direction);
        float cos_theta = min(dot(-unit_direction, hit_record.normal), 1.0);
        float sin_theta = sqrt(1.0 - cos_theta * cos_theta);
        bool cannot_refract = refraction_ratio * sin_theta > 1.0;
        vec3 direction;
        if (cannot_refract || Reflectance(cos_theta, refraction_ratio) > rand1(g_seed)) {
            direction = reflect(unit_direction, hit_record.normal);
        }
        else {
            direction = refract(unit_direction, hit_record.normal, refraction_ratio);
        }
        scattered_ray = Ray(hit_record.point, normalize(direction));
        return true;
    }
    return false;
}

// Compute color for a ray
vec3 RayColor(Ray ray) {
    Material mat_center = Material(vec3(0.1, 0.2, 0.5), TYPE_DIFFUSE, 0.0);
    Material mat_left = Material(vec3(1.0, 1.0, 1.0), TYPE_GLASS, 1.5);
    Material mat_right = Material(vec3(0.8, 0.6, 0.2), TYPE_METAL, 0.0);
    Material mat_ground = Material(vec3(0.8, 0.8, 0.0), TYPE_DIFFUSE, 0.0);

    Sphere sphere_center = Sphere(vec3(0.0, 0.0, -1.0), 0.5, mat_center);
    Sphere sphere_left = Sphere(vec3(-1.0, 0.0, -1.0), 0.5, mat_left);
    Sphere sphere_left2 = Sphere(vec3(-1.0, 0.0, -1.0), -0.4, mat_left);
    Sphere sphere_right = Sphere(vec3(1.0, 0.0, -1.0), 0.5, mat_right);
    Sphere ground = Sphere(vec3(0.0, -100.5, -1.0), 100.0, mat_ground);

    vec3 color = vec3(1.0, 1.0, 1.0);
    for (int i = 0; i < MAX_RECURSION; i++) {
        bool hit_anything = false;
        HitRecord hit_record;
        float t_min = 0.001;
        float t_max = MAX_FLOAT;
        if (HitSphere(sphere_center, ray, t_min, t_max, hit_record)) {
            hit_anything = true;
            t_max = hit_record.t;
        }
        if (HitSphere(sphere_left, ray, t_min, t_max, hit_record)) {
            hit_anything = true;
            t_max = hit_record.t;
        }
        if (HitSphere(sphere_left2, ray, t_min, t_max, hit_record)) {
            hit_anything = true;
            t_max = hit_record.t;
        }
        if (HitSphere(sphere_right, ray, t_min, t_max, hit_record)) {
            hit_anything = true;
            t_max = hit_record.t;
        }
        if (HitSphere(ground, ray, t_min, t_max, hit_record)) {
            hit_anything = true;
            t_max = hit_record.t;
        }
        if (hit_anything) {
            Ray scattered_ray;
            if (ScatterMaterial(ray, hit_record, color, scattered_ray)) {
                ray = scattered_ray;
            }
            else {
                return vec3(0.0, 0.0, 0.0);
            }
        }
        else {
            vec3 unit_direction = normalize(ray.direction);
            float t = 0.5 * (unit_direction.y + 1.0);
            return color * ((1.0 - t) * vec3(1.0, 1.0, 1.0) + t * vec3(0.5, 0.7, 1.0));
        }
    }
    return vec3(0.0, 0.0, 0.0);
}

// Camera definition
struct Camera {
    vec3 position;
    vec3 target;
    vec3 up;
    vec3 horizontal;
    vec3 vertical;
    vec3 lower_left_corner;
};

// Function to generate a ray from camera
Ray GetRay(Camera camera, vec2 uv) {
    return Ray(camera.position, normalize(camera.lower_left_corner + uv.x * camera.horizontal + uv.y * camera.vertical - camera.position));
}

void main() {
    init_rand(gl_FragCoord.xy, iTime);
    
    // Camera parameters
    float vfov = 20.0; // Vertical field of view
    vec3 view_pos = vec3(-2.0, 2.0, 1.0); // Camera position
    vec3 view_target = vec3(0.0, 0.0, -1.0); // Point the camera is looking at
    vec3 view_up = vec3(0.0, 1.0, 0.0); // Up vector
    float focal_length = length(view_pos - view_target); // Distance to the focal plane
    float theta = radians(vfov); // Convert vertical field of view to radians
    float h = tan(theta / 2.0); // Half of the viewport height
    float viewport_height = 2.0 * h * focal_length; // Viewport height
    float viewport_width = viewport_height * (iResolution.x / iResolution.y); // Viewport width

    // Orthonormal basis vectors for camera coordinate system
    vec3 u, v, w;
    w = normalize(view_pos - view_target); // Camera's forward direction
    u = normalize(cross(view_up, w)); // Camera's right direction
    v = cross(u, w); // Camera's up direction

    // Compute viewport vectors
    vec3 viewport_u = viewport_width * u;
    vec3 viewport_v = viewport_height * -v; // Negative v because y-axis is inverted in screen space
    vec3 viewport_upper_left = view_pos - (focal_length * w) - 0.5 * viewport_u - 0.5 * viewport_v; // Upper left corner of the viewport

    // Create camera object
    Camera camera = Camera(view_pos, view_target, view_up, viewport_u, viewport_v, viewport_upper_left);

    // Number of samples per pixel
    int samples_per_pixel = 100;

    // Accumulate color for each sample
    vec3 ray_color = vec3(0.0, 0.0, 0.0);
    for (int i = 0; i < samples_per_pixel; i++) {
        // Generate random offset within the pixel
        vec2 uv = (gl_FragCoord.xy + rand2(g_seed)) / iResolution.xy;
        
        // Generate ray for current sample
        Ray ray = GetRay(camera, uv);
        
        // Trace the ray and accumulate color
        ray_color += RayColor(ray);
    }

    // Average color over all samples
    ray_color /= float(samples_per_pixel);

    // Apply gamma correction
    ray_color = pow(ray_color, vec3(1.0 / 2.2));
    
    // Output final color to screen
    gl_FragColor = vec4(ray_color, 1.0);
}

