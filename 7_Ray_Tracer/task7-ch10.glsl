#include "common.glsl"

#define MAT_LAMBERTIAN 0
#define MAT_METAL 1
#define MAT_DIELECTRIC 2

// Material structure
struct Material {
    vec3 clr;
    int type;
    float var;
};

// Geometry structures
struct Sphere {
    vec3 center;
    float radius;
    Material mat;
};

// Ray structure
struct Ray {
    vec3 orig;
    vec3 dir;
};

// Hit record
struct HitRec {
    vec3 pos;
    vec3 norm;
    float t;
    bool front;
    Material mat;
};

// Ray functions
vec3 RayPoint(Ray ray, float t) {
    return ray.orig + t * ray.dir;
}

// Utility functions
float reflectivity(float cos, float idx) {
    float r0 = (1.0 - idx) / (1.0 + idx);
    r0 = r0 * r0;
    return r0 + (1.0 - r0) * pow((1.0 - cos), 5.0);
}

// Hit functions
bool HitSphere(Sphere sph, Ray ray, float tmin, float tmax, inout HitRec rec) {
    vec3 oc = ray.orig - sph.center;
    float a = dot(ray.dir, ray.dir);
    float half_b = dot(oc, ray.dir);
    float c = dot(oc, oc) - sph.radius * sph.radius;
    float discriminant = half_b * half_b - a * c;
    if (discriminant < 0.0) {
        return false;
    }
    float sqrtd = sqrt(discriminant);
    float root = (-half_b - sqrtd) / a;
    if (root <= tmin || tmax <= root) {
        root = (-half_b + sqrtd) / a;
        if (root <= tmin || tmax <= root) {
            return false;
        }
    }
    rec.t = root;
    rec.pos = RayPoint(ray, rec.t);
    rec.norm = (rec.pos - sph.center) / sph.radius;
    rec.front = dot(ray.dir, rec.norm) < 0.0;
    rec.norm = rec.front ? rec.norm : -rec.norm;
    rec.mat = sph.mat;
    return true;
}

bool ScatterMaterial(Ray ray, HitRec rec, inout vec3 atten, inout Ray scat) {
    if (rec.mat.type == MAT_LAMBERTIAN) {
        vec3 dir = rec.norm + random_in_unit_sphere(g_seed);
        scat = Ray(rec.pos, normalize(dir));
        atten *= rec.mat.clr;
        return true;
    } else if (rec.mat.type == MAT_METAL) {
        vec3 refl = reflect(ray.dir, rec.norm);
        scat = Ray(rec.pos, normalize(refl + rec.mat.var * random_in_unit_sphere(g_seed)));
        atten *= rec.mat.clr;
        return (dot(scat.dir, rec.norm) > 0.0);
    } else if (rec.mat.type == MAT_DIELECTRIC) {
        atten *= vec3(1.0, 1.0, 1.0);
        float ref_ratio = rec.front ? (1.0 / rec.mat.var) : rec.mat.var;
        float cos_theta = min(dot(-ray.dir, rec.norm), 1.0);
        float sin_theta = sqrt(1.0 - cos_theta * cos_theta);
        bool no_refract = ref_ratio * sin_theta > 1.0;
        vec3 dir;
        if (no_refract || reflectivity(cos_theta, ref_ratio) > rand1(g_seed))
            dir = reflect(ray.dir, rec.norm);
        else
            dir = refract(ray.dir, rec.norm, ref_ratio);

        scat = Ray(rec.pos, normalize(dir));
        return true;
    } else return false;
}

vec3 TraceRay(Ray ray) {
    Material mat_c = Material(vec3(0.1, 0.2, 0.5), 0, 0.0);
    Material mat_l = Material(vec3(1.0, 1.0, 1.0), 2, 1.5);
    Material mat_r = Material(vec3(0.8, 0.6, 0.2), 1, 0.0);
    Material mat_g = Material(vec3(0.8, 0.8, 0.0), 0, 0.0);

    Sphere sph_c = Sphere(vec3(0.0, 0.0, -1.0), 0.5, mat_c);
    Sphere sph_l = Sphere(vec3(-1.0, 0.0, -1.0), 0.5, mat_l);
    Sphere sph_l2 = Sphere(vec3(-1.0, 0.0, -1.0), -0.4, mat_l);
    Sphere sph_r = Sphere(vec3(1.0, 0.0, -1.0), 0.5, mat_r);
    Sphere grnd = Sphere(vec3(0.0, -100.5, -1.0), 100.0, mat_g);

    vec3 col = vec3(1.0, 1.0, 1.0);
    for (int i = 0; i < MAX_RECURSION; i++) {
        bool hit = false;
        HitRec hit_rec;
        float tmin = 0.001;
        float closest = MAX_FLOAT;
        if (HitSphere(sph_c, ray, tmin, closest, hit_rec)) {
            hit = true;
            closest = hit_rec.t;
        }
        if (HitSphere(sph_l, ray, tmin, closest, hit_rec)) {
            hit = true;
            closest = hit_rec.t;
        }
        if (HitSphere(sph_l2, ray, tmin, closest, hit_rec)) {
            hit = true;
            closest = hit_rec.t;
        }
        if (HitSphere(sph_r, ray, tmin, closest, hit_rec)) {
            hit = true;
            closest = hit_rec.t;
        }
        if (HitSphere(grnd, ray, tmin, closest, hit_rec)) {
            hit = true;
            closest = hit_rec.t;
        }
        if (hit) {
            Ray scattered;
            if (ScatterMaterial(ray, hit_rec, col, scattered))
                ray = scattered;
            else return vec3(0.0, 0.0, 0.0);
        } else {
            vec3 dir = normalize(ray.dir);
            float a = 0.5 * (dir.y + 1.0);
            return col * ((1.0 - a) * vec3(1.0, 1.0, 1.0) + a * vec3(0.5, 0.7, 1.0));
        }
    }
    return vec3(0.0, 0.0, 0.0);
}

// Camera structure
struct Camera {
    vec3 orig;
    vec3 vert;
    vec3 horiz;
    vec3 llc;
};

// Camera functions
Ray GetRay(Camera cam, vec2 uv) {
    Ray ray = Ray(cam.orig, normalize(cam.llc + uv.x * cam.horiz + uv.y * cam.vert - cam.orig));
    return ray;
}

void main() {
    init_rand(gl_FragCoord.xy, iTime);
    // Camera
    float focal_len = 1.0;
    float vp_height = 2.0;
    float vp_width = vp_height * (iResolution.x / iResolution.y);

    vec3 cam_orig = vec3(0.0, 0.0, 0.0);
    vec3 cam_vert = vec3(0.0, vp_height, 0.0);
    vec3 cam_horiz = vec3(vp_width, 0.0, 0.0);
    vec3 ll_corner = cam_orig - 0.5 * cam_vert - 0.5 * cam_horiz - vec3(0.0, 0.0, focal_len);
    Camera cam = Camera(cam_orig, cam_vert, cam_horiz, ll_corner);

    // Normalized pixel coordinates (from 0 to 1)
    int samples = 100;
    vec3 col = vec3(0.0, 0.0, 0.0);
    for (int i = 0; i < samples; i++) {
        vec2 uv = (gl_FragCoord.xy + rand2(g_seed)) / iResolution.xy;
        Ray ray = GetRay(cam, uv);
        col += TraceRay(ray);
    }
    col /= 100.0;
    col = pow(col, vec3(1.0 / 2.2));

    gl_FragColor = vec4(col, 1.0);
}
