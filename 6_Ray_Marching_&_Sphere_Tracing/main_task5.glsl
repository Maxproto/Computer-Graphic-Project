# define PI 3.1415


float sdSphere(vec3 p, float s) {
    p = abs(p);
    return (p.x+p.y+p.z-s)*0.57735027;
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float sdTriPrism(vec3 p, vec2 h) {
    vec3 q = abs(p);
    return max(q.z - h.y, max(q.x * 0.866025 + p.y * 0.5, -p.y) - h.x * 0.5);
}

float sdCylinder(vec3 p, vec2 h) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - h;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

vec4 minWithColor(vec4 obj1, vec4 obj2) {
    if (obj2.a < obj1.a) return obj2;
    return obj1;
}

float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

mat3 rotationZ(float theta){
    return mat3(
        cos(theta) , 0.0, -sin(theta), // primera coluna
        0.0 , 1.0 , 0.0,
        sin(theta), 0.0, cos(theta) // segunda coluna
    );
}

mat3 rotationX(float theta){
    float ct = cos(theta);
    float st = sin(theta);
    return mat3(
        1.0, 0.0, 0.0, // primera coluna
        0.0, ct , st ,
        0.0, -st, ct // segunda coluna
    );
}


float sdLink( vec3 p, float le, float r1, float r2 )
{
  vec3 q = vec3( p.x, max(abs(p.y)-le,0.0), p.z );
  return length(vec2(length(q.xy)-r1,q.z)) - r2;
}

float mug(vec3 p){
    float exterior = sdCappedCylinder(p - vec3(2.5, 0, -2), 1.5, 1.5);
    float handle = sdLink(p - vec3(1, 0, -2), 0.2, 1.1, 0.2);
    float interior_cut = sdCappedCylinder(p - vec3(2.5, 0.1, -2), 1.6, 1.2);
    return max(min(exterior, handle), -interior_cut);
}

vec4 sdScene(vec3 p) {
    p.z -= 0.5;
    p = rotationZ(iTime/2.0)*p;
    
    // 缩小系数
    float scale = 0.5; // 可以根据需要调整缩小的程度

    // 计算不同形状的距离场值，并将位置参数缩小
    float sphereDist = sdSphere(p - vec3(0.0, 0.0, 0.0) * scale, 1.0);
    float boxDist = sdBox(p - vec3(3.0, 0.0, 0.0) * scale, vec3(1.0, 1.0, 1.0) * scale);
    float triPrismDist = sdTriPrism(p - vec3(6.0, 0.0, 0.0) * scale, vec2(1.0, 1.0) * scale);
    float cylinderDist = sdCylinder(p - vec3(9.0, 0.0, 0.0) * scale, vec2(1.0, 1.0) * scale);

    // 使用 minWithColor 函数来获取距离场最小的物体
    vec4 sphere = vec4(vec3(1.0, 0.0, 0.0), sphereDist);
    vec4 box = vec4(vec3(0.0, 1.0, 0.0), boxDist);
    vec4 triPrism = vec4(vec3(0.0, 0.0, 1.0), triPrismDist);
    vec4 cylinder = vec4(vec3(1.0, 1.0, 0.0), cylinderDist);
    
    vec4 mugRight = vec4(vec3(0.1, 0.9, 0.3), mug(p - vec3(0.5, 0, 0)));
    vec4 mugLeft = vec4(vec3(0.7, 0.2, 0.1), mug(p - vec3(-5.5, 0, 0)));
    
    vec4 co = minWithColor(minWithColor(minWithColor(sphere, box), triPrism), cylinder);
    co = minWithColor(minWithColor(co, mugLeft), mugRight);
    
    return co;
}


vec4 rayMarch(vec3 ro, vec3 rd, float start, float end) {
    float depth = start;
    vec4 co;
    for (int i = 0; i < 255; i++) {
        vec3 p = ro + depth * rd;
        co = sdScene(p);
        depth += co.a;
        if (co.a < 0.001 || depth > end) break;
    }
    return vec4(co.rgb, depth);
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(1.0, -1.0) * 0.0005; // epsilon
    return normalize(
        e.xyy * sdScene(p + e.xyy).a +
        e.yyx * sdScene(p + e.yyx).a +
        e.yxy * sdScene(p + e.yxy).a +
        e.xxx * sdScene(p + e.xxx).a);
}
mat4 look_at(vec3 eye, vec3 at, vec3 up) {
    vec3 w = normalize(at - eye);
    vec3 u = normalize(cross(w, up));
    vec3 v = cross(u, w);
    return mat4(
        vec4(u, 0.0),
        vec4(v, 0.0),
        vec4(-w, 0.0),
        vec4(vec3(0.0), 1.0));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
    vec3 col = vec3(0);
    vec3 ro = vec3(0.0, 5.0, 15.0);
    mat4 view = look_at(ro, vec3(0.0, -PI/6.0, -3.0), vec3(0.0, 1.0, 0.0));
    vec3 rd = normalize(vec3(uv, -1));
    rd = normalize((view * vec4(rd, 1.0)).xyz);
    
    vec4 co = rayMarch(ro, rd, 0.01, 100.0);
    
    if (co.a > 100.0) col = vec3(0.6);
    else {
        vec3 p = ro + rd * co.a;
        vec3 normal = calcNormal(p);
        vec3 lightPos = vec3(-2.0*sin(iTime), 2, 5);
        vec3 lightDir = normalize(lightPos - p);
        float ambient = 0.3;
        float difuse = clamp(dot(normal, lightDir),ambient,1.);
        col = difuse * co.rgb;
    }
    fragColor = vec4(col, 1.0);
}