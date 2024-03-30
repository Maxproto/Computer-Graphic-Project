struct RayData {
    vec3 origin;    // Origin point of the ray
    vec3 direction; // Direction vector of the ray
};

vec3 computeRayColor(RayData ray) {
    vec3 directionNormalized = normalize(ray.direction);
    float t = 0.5 * (directionNormalized.y + 1.0);
    return (1.0 - t) * vec3(1.0) + t * vec3(0.5, 0.7, 1.0);
}

void main() {
    // Calculate normalized coordinates for the pixel
    vec2 normalizedCoords = gl_FragCoord.xy / iResolution.xy;
    // Compute the aspect ratio from the shader's resolution
    float aspectRatio = iResolution.x / iResolution.y;
    
    // Setting the viewport dimensions
    float heightOfViewport = 2.0;
    float widthOfViewport = aspectRatio * heightOfViewport;
    
    // Camera setup
    vec3 originCamera = vec3(0.0, 0.0, 0.0);
    vec3 originViewport = originCamera - vec3(widthOfViewport / 2.0, heightOfViewport / 2.0, 1.0);
    
    // Determining the direction of the ray
    vec3 directionRay = originViewport + vec3(normalizedCoords.x * widthOfViewport, normalizedCoords.y * heightOfViewport, 0.0) - originCamera;
    
    // Initializing the ray with its origin and direction
    RayData rayInstance = RayData(originCamera, normalize(directionRay));
    
    // Calculating the color for the current pixel based on the ray's direction
    vec3 colorOfPixel = computeRayColor(rayInstance);
    
    // Assigning the calculated color to the current pixel
    gl_FragColor = vec4(colorOfPixel, 1.0);
}
