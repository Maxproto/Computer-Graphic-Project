#include "common.glsl"

struct Ball
{
    vec3 pos;
    float rad;
};

struct Beam
{
    vec3 start;
    vec3 dir;
};

struct Collision
{
    vec3 hit_pos;
    vec3 hit_normal;
    float time;
    bool outside;
};

vec3 ExtendBeam(Beam beam, float t)
{
    return beam.start + t * beam.dir;
}

bool DetectBall(Ball ball, Beam beam, float min_t, float max_t, inout Collision coll)
{
    vec3 offset = beam.start - ball.pos;
  	float a = dot(beam.dir, beam.dir);
  	float half_b = dot(offset, beam.dir);


  	float c = dot(offset, offset) - ball.rad * ball.rad;
    float discr  = half_b * half_b - a * c;
    if(discr < 0.0){
        return false;
    }
    float sqrtdiscr = sqrt(discr);
    float root = (-half_b - sqrtdiscr) / a;


    if (root <= min_t || max_t <= root){
        root = (-half_b + sqrtdiscr) / a;
        if(root <= min_t || max_t <= root){
            return false;
        }
    }
    coll.time = root;
    coll.hit_pos = ExtendBeam(beam, coll.time);
    coll.hit_normal = (coll.hit_pos - ball.pos) / ball.rad;
    coll.outside = dot(beam.dir, coll.hit_normal) < 0.0;


    coll.hit_normal = coll.outside ? coll.hit_normal : -coll.hit_normal;
    return true;
}

vec3 CalculateBeamColor(Beam beam){
    Ball ball = Ball(vec3(0.0, 0.0, -1.0), 0.5);
    Ball ground = Ball(vec3(0.0, -100.5, -1.0), 100.0);

    vec3 col = vec3(1.0, 1.0, 1.0);
    for(int i=0; i<MAX_RECURSION; i++){
        bool hit = false;
        Collision hit_info;


        float min_t = 0.001;
        float closest_t = MAX_FLOAT;
        if(DetectBall(ball, beam, min_t, closest_t, hit_info)){
            hit = true;
            closest_t = hit_info.time;
        }

        if(DetectBall(ground, beam, min_t, closest_t, hit_info)){
            hit = true;
            closest_t = hit_info.time;
        }
        if(hit){
            vec3 dir = hit_info.hit_normal + random_in_unit_sphere(g_seed);
            beam.start = hit_info.hit_pos;

            beam.dir = normalize(dir);
            col *= 0.5;
        }
        
        else{
            vec3 unit_dir = normalize(beam.dir);
            float t = 0.5*(unit_dir.y + 1.0);
            return col * ((1.0 - t) * vec3(1.0, 1.0, 1.0) + t * vec3(0.5, 0.7, 1.0));
        }
    }
    return vec3(0.0, 0.0, 0.0);

}

// Camera
struct Viewpoint
{
	vec3 eye;
	vec3 up;
	vec3 right;
	vec3 lower_left;
};

// Camera functions
Beam GenerateBeamFromViewpoint(Viewpoint vp, vec2 uv)
{
    Beam beam = Beam(vp.eye, normalize(vp.lower_left + uv.x * vp.right + uv.y * vp.up - vp.eye));
    return beam;
}

void main()
{    
    init_rand(gl_FragCoord.xy, iTime);
    
    float focal_len = 1.0;
    float viewport_h = 2.0;
    float viewport_w = viewport_h * (iResolution.x / iResolution.y);

    vec3 eye = vec3(0.0, 0.0, 0.0);
    vec3 up = vec3(0.0, viewport_h, 0.0);
    vec3 right = vec3(viewport_w, 0.0, 0.0);
    vec3 lower_left = eye - 0.5 * up - 0.5 * right - vec3(0.0, 0.0, focal_len);
    Viewpoint vp = Viewpoint(eye, up, right, lower_left);

    int samples = 100;
    vec3 col = vec3(0.0, 0.0, 0.0);
    for(int i=0; i<samples; i++){
        vec2 uv = (gl_FragCoord.xy + rand2(g_seed))/ iResolution.xy;
        Beam beam = GenerateBeamFromViewpoint(vp, uv);
        col += CalculateBeamColor(beam);
    }
    col /= 100.0;
    col = pow(col, vec3(1.0/2.2));
    
    gl_FragColor = vec4(col, 1.0);
}
