#include "common.glsl"
#define lambertian 0
#define metal 1

struct Material
{
    vec3 color;
    int material_type;
    float material_dependent_var;
};


struct Ball
{
    vec3 position;
    float radius;
    Material material;
};

struct Beam
{
    vec3 start;
    vec3 direction;
};

struct Collision
{
    vec3 position;
    vec3 normal;
    float time;
    bool outside;
    Material material;
};

vec3 ExtendBeam(Beam beam, float t)
{
    return beam.start + t * beam.direction;
}

bool DetectBall(Ball ball, Beam beam, float min_t, float max_t, inout Collision collision)
{
    vec3 offset = beam.start - ball.position;
    float a = dot(beam.direction, beam.direction);
    float half_b = dot(offset, beam.direction);
    float c = dot(offset, offset) - ball.radius * ball.radius;
    float discriminant  = half_b * half_b - a * c;

    if(discriminant < 0.0){
        return false;
    }

    float sqrtd = sqrt(discriminant);
    float root = (-half_b - sqrtd) / a;

    if (root <= min_t || max_t <= root){
        root = (-half_b + sqrtd) / a;
        if(root <= min_t || max_t <= root){
            return false;
        }
    }

    collision.time = root;
    collision.position = ExtendBeam(beam, collision.time);
    collision.normal = (collision.position - ball.position) / ball.radius;
    collision.outside = dot(beam.direction, collision.normal) < 0.0;
    collision.normal = collision.outside ? collision.normal : -collision.normal;
    collision.material = ball.material;

    return true;
}

bool ScatterMaterial(Beam ray, Collision collision, inout vec3 attenuation, inout Beam scattered)
{
    if(collision.material.material_type == lambertian)
    {
        vec3 target = collision.position + collision.normal + random_in_unit_sphere(g_seed);
        scattered = Beam(collision.position, normalize(target - collision.position));
        attenuation *= collision.material.color;
        return true;
    }
    else if(collision.material.material_type == metal)
    {
        vec3 reflected = reflect(ray.direction, collision.normal);
        scattered = Beam(collision.position, normalize(reflected + collision.material.material_dependent_var * random_in_unit_sphere(g_seed)));
        attenuation *= collision.material.color;
        return dot(scattered.direction, collision.normal) > 0.0;
    }
    else
    {
        return false;
    }
}

vec3 TraceRay(Beam ray)
{
    Material material_center = Material(vec3(0.7, 0.3, 0.3), lambertian, 0.5);
    Material material_left = Material(vec3(0.8, 0.8, 0.8), metal, 0.3);
    Material material_right = Material(vec3(0.8, 0.6, 0.2), metal, 1.0);
    Material material_ground = Material(vec3(0.8, 0.8, 0.0), lambertian, 0.5);

    Ball sphere_center = Ball(vec3(0.0, 0.0, -1.0), 0.5, material_center);
    Ball sphere_left = Ball(vec3(-1.0, 0.0, -1.0), 0.5, material_left);
    Ball sphere_right = Ball(vec3(1.0, 0.0, -1.0), 0.5, material_right);
    Ball ground = Ball(vec3(0.0, -100.5, -1.0), 100.0, material_ground);

    vec3 color = vec3(1.0, 1.0, 1.0);

    for(int i = 0; i < MAX_RECURSION; i++)
    {
        bool hit_anything = false;
        Collision collision;
        float min_t = 0.001;
        float closest_so_far = MAX_FLOAT;

        if(DetectBall(sphere_center, ray, min_t, closest_so_far, collision))
        {
            hit_anything = true;
            closest_so_far = collision.time;
        }

        if(DetectBall(sphere_left, ray, min_t, closest_so_far, collision))
        {
            hit_anything = true;
            closest_so_far = collision.time;
        }

        if(DetectBall(sphere_right, ray, min_t, closest_so_far, collision))
        {
            hit_anything = true;
            closest_so_far = collision.time;
        }

        if(DetectBall(ground, ray, min_t, closest_so_far, collision))
        {
            hit_anything = true;
            closest_so_far = collision.time;
        }

        if(hit_anything)
        {
            Beam scattered;
            if(ScatterMaterial(ray, collision, color, scattered))
            {
                ray = scattered;
            }
            else
            {
                return vec3(0.0);
            }
        }
        else
        {
            vec3 unit_direction = normalize(ray.direction);
            float t = 0.5 * (unit_direction.y + 1.0);
            return color * ((1.0 - t) * vec3(1.0) + t * vec3(0.5, 0.7, 1.0));
        }
    }

    return vec3(0.0);
}

// Camera
struct Camera
{
    vec3 position;
    vec3 vertical;
    vec3 horizontal;
    vec3 lower_left_corner;
};

// Camera functions
Beam GetRayFromCamera(Camera camera, vec2 uv)
{
    Beam ray = Beam(camera.position, normalize(camera.lower_left_corner + uv.x * camera.horizontal + uv.y * camera.vertical - camera.position));
    return ray;
}

void main()
{    
    init_rand(gl_FragCoord.xy, iTime);

    float focal_length = 1.0;
    float viewport_height = 2.0;
    float viewport_width = viewport_height * (iResolution.x / iResolution.y);

    vec3 camera_position = vec3(0.0);
    vec3 camera_vertical = vec3(0.0, viewport_height, 0.0);
    vec3 camera_horizontal = vec3(viewport_width, 0.0, 0.0);
    vec3 lower_left_corner = camera_position - 0.5 * camera_vertical - 0.5 * camera_horizontal - vec3(0.0, 0.0, focal_length);
    Camera camera = Camera(camera_position, camera_vertical, camera_horizontal, lower_left_corner);

    int samples_per_pixel = 100;
    vec3 ray_color = vec3(0.0);

    for(int i = 0; i < samples_per_pixel; i++)
    {
        vec2 uv = (gl_FragCoord.xy + rand2(g_seed)) / iResolution.xy;
        Beam ray = GetRayFromCamera(camera, uv);
        ray_color += TraceRay(ray);
    }

    ray_color /= float(samples_per_pixel);
    ray_color = pow(ray_color, vec3(1.0 / 2.2));

    gl_FragColor = vec4(ray_color, 1.0);
}
