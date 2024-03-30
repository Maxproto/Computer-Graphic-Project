// Include common functions and external texture
#include "common.glsl"
#iChannel0 'file://task11.glsl'

// Define material types
#define LAMBERTIAN 0
#define METAL 1
#define DIELECTRIC 2

// Material structure to hold color and type information
struct Material
{
    vec3 color; // Color of the material
    int material_type; // Type of material (lambertian, metal, dielectric)
    float material_dependent_var; // Material-dependent variable (e.g., fuzziness for metal, refractive index for dielectric)
};

// Structure to represent a sphere
struct Sphere
{
    vec3 center; // Center of the sphere
    float radius; // Radius of the sphere
    Material material; // Material of the sphere
};

Sphere spheres[144]; // Array to store spheres

// Structure to represent a ray
struct Ray
{
    vec3 origin; // Origin point of the ray
    vec3 direction; // Direction vector of the ray
};

// Structure to hold information about a ray-sphere intersection
struct HitRecord
{
    vec3 point; // Point of intersection
    vec3 normal; // Normal at the point of intersection
    float t; // Parameter along the ray
    bool front_face; // Flag indicating if the ray intersects the front face of the object
    Material material; // Material of the intersected object
};

// Function to calculate the point at parameter t along a ray
vec3 RayAt(Ray ray, float t)
{
    return ray.origin + t * ray.direction;
}

// Function to calculate the reflectance using Schlick's approximation
float reflectance(float cosine, float ref_idx){
    float r0 = (1.0 - ref_idx) / (1.0 + ref_idx);
    r0 = r0 * r0;
    return r0 + (1.0 - r0) * pow((1.0 - cosine), 5.0);
}

// Function to check for intersection with a sphere
bool HitSphere(Sphere sphere, Ray ray, float ray_tmin, float ray_tmax, inout HitRecord rec)
{
    vec3 oc = ray.origin - sphere.center;
    float a = dot(ray.direction, ray.direction);
    float half_b = dot(oc, ray.direction);
    float c = dot(oc, oc) - sphere.radius * sphere.radius;
    float discriminant  = half_b * half_b - a * c;
    if (discriminant < 0.0){
        return false;
    }
    float sqrtd = sqrt(discriminant);
    float root = (-half_b - sqrtd) / a;
    if (root <= ray_tmin || ray_tmax <= root){
        root = (-half_b + sqrtd) / a;
        if (root <= ray_tmin || ray_tmax <= root){
            return false;
        }
    }
    rec.t = root;
    rec.point = RayAt(ray, rec.t);
    rec.normal = (rec.point - sphere.center) / sphere.radius;
    rec.front_face = dot(ray.direction, rec.normal) < 0.0;
    rec.normal = rec.front_face ? rec.normal : -rec.normal;
    rec.material = sphere.material;
    return true;
}

// Function to calculate material scattering behavior
bool MaterialScatter(Ray ray, HitRecord rec, inout vec3 attenuation, inout Ray scattered){
    if (rec.material.material_type == LAMBERTIAN){
        vec3 direction = rec.normal + random_in_unit_sphere(g_seed);
        scattered = Ray(rec.point, normalize(direction));
        attenuation *= rec.material.color;
        return true;
    }
    else if (rec.material.material_type == METAL){
        vec3 reflected = reflect(ray.direction, rec.normal);
        scattered = Ray(rec.point, normalize(reflected + rec.material.material_dependent_var * random_in_unit_sphere(g_seed)));
        attenuation *= rec.material.color;
        return (dot(scattered.direction, rec.normal) > 0.0);
    }
    else if (rec.material.material_type == DIELECTRIC){
        attenuation *= vec3(1.0, 1.0, 1.0);
        float refraction_ratio = rec.front_face ? (1.0 / rec.material.material_dependent_var) : rec.material.material_dependent_var;
        float cos_theta = min(dot(-ray.direction, rec.normal), 1.0);
        float sin_theta = sqrt(1.0 - cos_theta * cos_theta);
        bool cannot_refract = refraction_ratio * sin_theta > 1.0;
        vec3 direction;
        if (cannot_refract || reflectance(cos_theta, refraction_ratio) > rand1(g_seed))
            direction = reflect(ray.direction, rec.normal);
        else
            direction = refract(ray.direction, rec.normal, refraction_ratio);

        scattered = Ray(rec.point, normalize(direction));
        return true;
    }
    else return false;
}

// Function to generate spheres in the scene
void GenerateSpheres(inout int cnt){
    for (int a = -6; a < 6; a++){
        for (int b = -6; b < 6; b++){
            float choose_mat = rand1(g_seed);
            vec3 center = vec3(float(a) + 0.9 * rand1(g_seed), 0.2, float(b) + 0.9 * rand1(g_seed));
            if (length(center - vec3(4.0, 0.2, 0.0)) > 0.9){
                Material sphere_material;
                if (choose_mat < 0.8){
                    vec3 albedo = rand3(g_seed) * rand3(g_seed);
                    sphere_material = Material(albedo, LAMBERTIAN, 0.0);
                    spheres[cnt] = Sphere(center, 0.2, sphere_material);
                }
                else if (choose_mat < 0.95){
                    vec3 albedo = rand3(g_seed) * 0.5 + vec3(0.5, 0.5, 0.5);
                    float fuzz = rand1(g_seed) * 0.5;
                    sphere_material = Material(albedo, METAL, fuzz);
                    spheres[cnt] = Sphere(center, 0.2, sphere_material);
                } 
                else{
                    vec3 albedo = vec3(1.0, 1.0, 1.0);
                    sphere_material = Material(albedo, DIELECTRIC, 1.5);
                    spheres[cnt] = Sphere(center, 0.2, sphere_material);
                }
                cnt += 1;
            }
        }
    }
}

// Function to compute the color of a ray
vec3 RayColor(Ray ray, int cnt){
    // Define materials and objects
    Material material_ground = Material(vec3(0.5, 0.5, 0.5), LAMBERTIAN, 0.0);
    Sphere ground = Sphere(vec3(0.0, -1000.0, 0.0), 1000.0, material_ground);

    Material material1 = Material(vec3(1.0, 1.0, 1.0), DIELECTRIC, 1.5);
    Material material2 = Material(vec3(0.4, 0.2, 0.1), LAMBERTIAN, 0.0);
    Material material3 = Material(vec3(0.7, 0.6, 0.5), METAL, 0.0);

    Sphere sphere1 = Sphere(vec3(0.0, 1.0, 0.0), 1.0, material1);
    Sphere sphere2 = Sphere(vec3(-4.0, 1.0, 0.0), 1.0, material2);
    Sphere sphere3 = Sphere(vec3(4.0, 1.0, 0.0), 1.0, material3);

    // Trace rays and compute final color
    vec3 color = vec3(1.0, 1.0, 1.0);
    for (int i = 0; i < MAX_RECURSION; i++){
        bool hit_anything = false;
        HitRecord hit_record;
        float ray_tmin = 0.001;
        float closest_so_far = MAX_FLOAT;
        // Check intersection with each object
        if (HitSphere(ground, ray, ray_tmin, closest_so_far, hit_record)){
            hit_anything = true;
            closest_so_far = hit_record.t;
        }
        if (HitSphere(sphere1, ray, ray_tmin, closest_so_far, hit_record)){
            hit_anything = true;
            closest_so_far = hit_record.t;
        }
        if (HitSphere(sphere2, ray, ray_tmin, closest_so_far, hit_record)){
            hit_anything = true;
            closest_so_far = hit_record.t;
        }
        if (HitSphere(sphere3, ray, ray_tmin, closest_so_far, hit_record)){
            hit_anything = true;
            closest_so_far = hit_record.t;
        }
        for (int j = 0; j < cnt; j++){
            if (HitSphere(spheres[j], ray, ray_tmin, closest_so_far, hit_record)){
                hit_anything = true;
                closest_so_far = hit_record.t;
            }
        }
        // Handle ray interaction
        if (hit_anything){
            Ray scattered;
            if (MaterialScatter(ray, hit_record, color, scattered))
                ray = scattered;
            else
                return vec3(0.0, 0.0, 0.0);
        }
        else{
            vec3 unit_direction = normalize(ray.direction);
            float a = 0.5 * (unit_direction.y + 1.0);
            return color * ((1.0 - a) * vec3(1.0, 1.0, 1.0) + a * vec3(0.5, 0.7, 1.0));
        }
    }
    return vec3(0.0, 0.0, 0.0);
}

// Structure to represent a camera
struct Camera
{
    vec3 lookfrom; // Position of the camera
    vec3 lookat; // Point the camera is looking at
    vec3 vup; // Up direction of the camera
    vec3 viewport_u; // Horizontal dimension of the viewport
    vec3 viewport_v; // Vertical dimension of the viewport
    vec3 viewport_upper_left; // Upper left corner of the viewport
    float defocus_angle; // Angle of defocus
    vec3 defocus_disk_u; // Horizontal dimension of the defocus disk
    vec3 defocus_disk_v; // Vertical dimension of the defocus disk
};

// Function to sample points on the defocus disk
vec3 defocus_disk_sample(Camera camera){
    vec2 p = random_in_unit_disk(g_seed);
    return camera.lookfrom + (p[0] * camera.defocus_disk_u) + (p[1] * camera.defocus_disk_v);
}

// Function to generate rays from the camera
Ray GetRayFromCamera(Camera camera, vec2 uv)
{
    // Determine the origin of the ray based on defocus
    vec3 ray_origin = (camera.defocus_angle <= 0.0) ? camera.lookfrom : defocus_disk_sample(camera);
    // Calculate the direction of the ray
    Ray ray = Ray(ray_origin, normalize(camera.viewport_upper_left + uv.x * camera.viewport_u + uv.y * camera.viewport_v - ray_origin));
    return ray;
}

// Main function
void main()
{    
    // Initialize sphere count and generate spheres
    int cnt = 0;
    GenerateSpheres(cnt);
    init_rand(gl_FragCoord.xy, iTime);
    
    // Camera parameters
    float defocus_angle = 0.6;
    float focus_dist = 10.0;
    float vfov = 20.0;
    vec3 lookfrom = vec3(13.0, 2.0, 3.0);
    vec3 lookat = vec3(0.0, 0.0, 0.0);
    vec3 vup = vec3(0.0, 1.0, 0.0);
    float focal_length = length(lookfrom - lookat);
    float theta = radians(vfov);
    float h = tan(theta/2.0);
    float viewport_height = 2.0 * h * focus_dist;
    float viewport_width = viewport_height * (iResolution.x / iResolution.y);

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

    // Normalized pixel coordinates (from 0 to 1)
    vec3 ray_color = vec3(0.0, 0.0, 0.0);
    vec2 uv = (gl_FragCoord.xy )/ iResolution.xy;
    Ray ray = GetRayFromCamera(camera, uv);
    ray_color = RayColor(ray, cnt);
    ray_color = pow(ray_color, vec3(1.0/2.2));
    
    // Blend previous frame with current frame for motion blur effect
    vec3 old = texture(iChannel0, uv).rgb;
    float weight = float(iFrame+1);
    vec3 newColor = mix(old, ray_color, 1.0 / weight);
    gl_FragColor = vec4(newColor, 1.0);
}
