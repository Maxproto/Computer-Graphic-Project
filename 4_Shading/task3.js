// TODO: Implement a shader program to do Lambert and Phong shading
//       in the fragment shader. How you do this exactly is left up to you.

//       You may need multiple uniforms to get all the required matrices
//       for transforming points, vectors and normals.

var PhongVertexSource = `
    // Uniforms for transformation matrices
    uniform mat4 ModelViewProjection; // Combined model-view-projection matrix
    uniform mat4 ModelMatrix;         // Model matrix for transforming vertices
    uniform mat4 NormalMatrix;        // Matrix for transforming normals

    // Vertex attributes
    attribute vec3 Position;          // Vertex position
    attribute vec3 Normal;            // Vertex normal

    // Varying variables to pass data to fragment shader
    varying vec3 worldPosition;      // Transformed position (to world coordinates)
    varying vec3 normalPosition;     // Transformed normal

    void main() {
        // Transform the position to world coordinates
        worldPosition = (ModelMatrix * vec4(Position, 1.0)).xyz;

        // Transform the normal with the normal matrix
        normalPosition = (NormalMatrix * vec4(Normal, 0.0)).xyz;

        // Set the final position of the vertex
        gl_Position = ModelViewProjection * vec4(Position, 1.0);
    }
`;


var PhongFragmentSource = `
    precision highp float; // Set the precision for float types

    const vec3 LightPosition = vec3(4, 1, 4);
    const vec3 LightIntensity = vec3(20);
    const vec3 ka = 0.3*vec3(1, 0.5, 0.5);
    const vec3 kd = 0.7*vec3(1, 0.5, 0.5);
    const vec3 ks = vec3(0.4);
    const float n = 10.0;

    // Varying variables received from vertex shader
    varying vec3 worldPosition; // Position of the fragment
    varying vec3 normalPosition;   // Normal of the fragment

    uniform mat4 ViewMatrix;

    void main() {
        // Normalize the light direction vector
        vec3 lightDir = normalize(LightPosition - worldPosition);

        // Calculate the distance to the light
        float distanceToLight = length(LightPosition - worldPosition);

        // Apply the inverse square law for light falloff
        vec3 FallLightIntensity = LightIntensity / (distanceToLight * distanceToLight);

        // Calculate viewDirection in fragment shader
        vec3 cameraPosition =  ViewMatrix[3].xyz;
        vec3 viewDirection = normalize(cameraPosition - worldPosition);

        // Calculate the reflection direction
        vec3 reflectDirection = reflect(-lightDir, normalize(normalPosition));

        // Calculate the lambertian component
        float lambertian = max(dot(normalize(normalPosition), lightDir), 0.0);
        
        // Calculate the specular component using the reflection direction
        float specular = pow(max(dot(viewDirection, reflectDirection), 0.0), n);

        // Combine ambient, lambertian, and specular components with light falloff
        vec3 ambient = ka;
        vec3 diffuseColor = kd * FallLightIntensity * lambertian;
        vec3 specularColor = ks * FallLightIntensity * specular;

        // Final color of the fragment
        vec3 color = ambient + diffuseColor + specularColor;
        gl_FragColor = vec4(color, 1.0);
    }
`;

var Task3 = function(gl)
{
    this.pitch = 0;
    this.yaw = 0;
    this.sphereMesh = new ShadedTriangleMesh(gl, SpherePositions, SphereNormals, SphereTriIndices, PhongVertexSource, PhongFragmentSource);
    this.cubeMesh = new ShadedTriangleMesh(gl, CubePositions, CubeNormals, CubeIndices, PhongVertexSource, PhongFragmentSource);
    
    gl.enable(gl.DEPTH_TEST);
}

Task3.prototype.render = function(gl, w, h)
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

Task3.prototype.dragCamera = function(dx, dy)
{
    this.pitch = Math.min(Math.max(this.pitch + dy*0.5, -90), 90);
    this.yaw = this.yaw + dx*0.5;
}
