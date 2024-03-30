var LambertVertexSource = `
    uniform mat4 ModelViewProjection;
    uniform mat4 NormalMatrix;
    uniform mat4 ModelMatrix;

    attribute vec3 Position;
    attribute vec3 Normal;

    varying vec3 Color;
    
    // TODO: Implement a vertex shader that
    //       a) applies the ModelViewProjection matrix to the vertex position and stores the result in gl_Position
    //       b) computes the lambert shaded color at the vertex and stores the result in Color
    
    //       You may need multiple uniforms to get all the required matrices
    //       for transforming points, vectors and normals.
    
    
    // Constants you should use to compute the final color
    const vec3 LightPosition = vec3(4, 1, 4);
    const vec3 LightIntensity = vec3(20);
    const vec3 ka = 0.3*vec3(1, 0.5, 0.5);
    const vec3 kd = 0.7*vec3(1, 0.5, 0.5);
    
    void main() {

// ################ Edit your code below
    vec4 normalTransformed = NormalMatrix*vec4(Normal, 0.0);
    vec4 positionTransformed = ModelMatrix*vec4(Position, 1.0);
    vec3 positionTransformedVec3 = positionTransformed.xyz;
    vec3 normalTransformedVec3 = normalTransformed.xyz;
    vec3 lightDirection = normalize(LightPosition - positionTransformedVec3);

    // Lambertian Reflectance
    float distanceToLight = length(LightPosition - positionTransformedVec3);
    float lambertian = max(dot(normalTransformedVec3, lightDirection), 0.0);
    
    Color = ka + kd * (LightIntensity/(distanceToLight*distanceToLight)) * lambertian;
    gl_Position = ModelViewProjection*vec4(Position, 1.0);
// ################
    }
`;
var LambertFragmentSource = `
    precision highp float;
    
    varying vec3 Color;
    
    // TODO: Implement a fragment shader that copies Color into gl_FragColor
    // Hint: Color is RGB; you need to extend it with an alpha channel to assign it to gl_FragColor

    void main() {
// ################ Edit your code below
        gl_FragColor = vec4(Color, 1.0);
// ################
    }
`;

var Task2 = function(gl)
{
    this.pitch = 0;
    this.yaw = 0;
    this.sphereMesh = new ShadedTriangleMesh(gl, SpherePositions, SphereNormals, SphereTriIndices, LambertVertexSource, LambertFragmentSource);
    this.cubeMesh = new ShadedTriangleMesh(gl, CubePositions, CubeNormals, CubeIndices, LambertVertexSource, LambertFragmentSource);
    
    gl.enable(gl.DEPTH_TEST);
}

Task2.prototype.render = function(gl, w, h)
{
    gl.clearColor(1.0, 1.0, 1.0, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    
    var projection = Matrix.perspective(45, w/h, 0.1, 100);    
    var view = Matrix.rotate(-this.yaw, 0, 1, 0).multiply(Matrix.rotate(-this.pitch, 1, 0, 0)).multiply(Matrix.translate(0, 0, 5)).inverse();
    var rotation = Matrix.rotate(Date.now()/25, 0, 1, 0);
    var cubeModel = Matrix.translate(-1.8, 0, 0).multiply(rotation);
    var sphereModel = Matrix.translate(1.8, 0, 0).multiply(rotation).multiply(Matrix.scale(1.2, 1.2, 1.2));

    this.sphereMesh.render(gl, sphereModel, view, projection);
    this.cubeMesh.render(gl, cubeModel, view, projection);
}

Task2.prototype.dragCamera = function(dx, dy)
{
    this.pitch = Math.min(Math.max(this.pitch + dy*0.5, -90), 90);
    this.yaw = this.yaw + dx*0.5;
}

