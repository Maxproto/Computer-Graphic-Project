struct LightRay {
    vec3 origin;    // Origin of the ray
    vec3 direction;   // Direction vector of the ray
};

bool sphereIntersection(vec3 sphereCenter, float sphereRadius, LightRay ray) {
    vec3 originToCenter = ray.origin - sphereCenter;
    float coeffA = dot(ray.direction, ray.direction);
    float coeffB = 2.0 * dot(originToCenter, ray.direction);
    float coeffC = dot(originToCenter, originToCenter) - sphereRadius * sphereRadius;
    float discriminant = coeffB * coeffB - 4.0 * coeffA * coeffC;
    return (discriminant >= 0.0);
}

vec3 calculateRayColor(LightRay ray) {
    if (sphereIntersection(vec3(0.0, 0.0, -1.0), 0.5, ray))
        return vec3(1.0, 0.0, 0.0); // Red for hit
    vec3 normalizedDirection = normalize(ray.direction);
    float t = 0.5 * (normalizedDirection.y + 1.0);
    return (1.0 - t) * vec3(1.0) + t * vec3(0.5, 0.7, 1.0); // Gradient background
}

void main() {
    // Convert pixel coordinates to normalized space [0,1]
    vec2 normCoords = gl_FragCoord.xy / iResolution.xy;
    // Compute the aspect ratio from the screen's resolution
    float aspectRatio = iResolution.x / iResolution.y;
    
    // Calculate viewport dimensions
    float viewportH = 2.0;
    float viewportW = aspectRatio * viewportH;
    
    // Camera setup
    vec3 camOrigin = vec3(0.0, 0.0, 0.0);
    vec3 viewOrigin = camOrigin - vec3(viewportW / 2.0, viewportH / 2.0, 1.0);
    
    // Determine the direction of the ray
    vec3 direction = viewOrigin + vec3(normCoords.x * viewportW, normCoords.y * viewportH, 0.0) - camOrigin;
    
    // Instantiate the ray
    LightRay ray = LightRay(camOrigin, normalize(direction));
    
    // Derive the color of the pixel based on the ray
    vec3 color = calculateRayColor(ray);
    
    // Output the color to the fragment
    gl_FragColor = vec4(color, 1.0);
}
