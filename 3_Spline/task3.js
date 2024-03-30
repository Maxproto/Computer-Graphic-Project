function getCubicSplinePoint(p0, p1, p2, p3, t, s){
    /*s == 1: Represents the very first segment of the spline. It uses p0 repeatedly 
    because there are not enough preceding control points. The curve segment 
    here is influenced mostly by p0 and begins to integrate the influence of p1.*/
    if(s == 1){
        var v1 = p0.multiply((1-t)*(1-t)*(1-t)/6.0);
        var v2 = p0.multiply((3*t*t*t - 6*t*t + 4)/6.0);
        var v3 = p0.multiply((-3*t*t*t + 3*t*t + 3*t + 1)/6.0);
        var v4 = p1.multiply(t*t*t/6.0);
        return v1.add(v2).add(v3).add(v4);
    }
    /*s == 2: Similar to s == 1, but the curve segment starts to incorporate the 
    influence of p2, preparing for the transition to the main part of the spline.*/
    else if(s == 2){
        var v1 = p0.multiply((1-t)*(1-t)*(1-t)/6.0);
        var v2 = p0.multiply((3*t*t*t - 6*t*t + 4)/6.0);
        var v3 = p1.multiply((-3*t*t*t + 3*t*t + 3*t + 1)/6.0);
        var v4 = p2.multiply(t*t*t/6.0);
        return v1.add(v2).add(v3).add(v4);
    }
    /*s == 3: This is the standard case for a segment in the middle of the spline,
     where all four control points (p0, p1, p2, p3) are different and each contributes 
     to the shape of this segment.*/
    else if(s == 3){
        var v1 = p0.multiply((1-t)*(1-t)*(1-t)/6.0);
        var v2 = p1.multiply((3*t*t*t - 6*t*t + 4)/6.0);
        var v3 = p2.multiply((-3*t*t*t + 3*t*t + 3*t + 1)/6.0);
        var v4 = p3.multiply(t*t*t/6.0);
        return v1.add(v2).add(v3).add(v4);
    }
    /*s == 4 and s == 5: These handle the end segments of the spline, where the influence
     of the last control points (p3) becomes more dominant. In s == 4, the segment is 
     transitioning away from p1*/
    else if(s == 4){
        var v1 = p1.multiply((1-t)*(1-t)*(1-t)/6.0);
        var v2 = p2.multiply((3*t*t*t - 6*t*t + 4)/6.0);
        var v3 = p3.multiply((-3*t*t*t + 3*t*t + 3*t + 1)/6.0);
        var v4 = p3.multiply(t*t*t/6.0);
        return v1.add(v2).add(v3).add(v4);
    }
    /*s == 5, it's almost entirely influenced by p3.*/
    else if(s == 5){
        var v1 = p2.multiply((1-t)*(1-t)*(1-t)/6.0);
        var v2 = p3.multiply((3*t*t*t - 6*t*t + 4)/6.0);
        var v3 = p3.multiply((-3*t*t*t + 3*t*t + 3*t + 1)/6.0);
        var v4 = p3.multiply(t*t*t/6.0);
        return v1.add(v2).add(v3).add(v4);
    }
}


function splinePatchTesselation(patch, tesselation) {
    var vertices = []; // Array to store vertices of the spline surface
    var faces = []; // Array to store faces (polygons) of the spline surface

    // Calculate the number of segments based on the tesselation factor
    var num_seg = tesselation * 5;
    var seg = [tesselation, tesselation, tesselation, tesselation, tesselation];
    
    // Generate coefficients for spline points calculation
    var coefficient1 = [];
    for(var i = 0; i < seg.length; i++){
        for(var j = 0; j < seg[i]; j++){
            coefficient1.push(j / seg[i]);
        }
    }
    coefficient1.push(1.0); // Ensure the end point is included
    var coefficient2 = coefficient1; // Use the same coefficients for both U and V directions

    // Counters to determine which set of control points to use
    var counter1 = 0;
    var counter2 = 0;

    // Iterate over each pair of coefficients to calculate spline surface vertices
    for(var v = 0; v < coefficient2.length; v += 1){
        if(coefficient2[v] == 0)
            counter2++;
            
        for(var u = 0; u < coefficient1.length; u += 1){
            if(coefficient1[u] == 0)
                counter1++;
            
            // Calculate spline points in U direction
            var p0 = getCubicSplinePoint(patch[0][0], patch[0][1], patch[0][2], patch[0][3], coefficient1[u], counter1);
            var p1 = getCubicSplinePoint(patch[1][0], patch[1][1], patch[1][2], patch[1][3], coefficient1[u], counter1);
            var p2 = getCubicSplinePoint(patch[2][0], patch[2][1], patch[2][2], patch[2][3], coefficient1[u], counter1);
            var p3 = getCubicSplinePoint(patch[3][0], patch[3][1], patch[3][2], patch[3][3], coefficient1[u], counter1);

            // Use the calculated U direction points as control points to calculate a point on the surface
            var p = getCubicSplinePoint(p0, p1, p2, p3, coefficient2[v], counter2);
            vertices.push(p); // Add the calculated point to the vertices array
        }
        counter1 = 0; // Reset counter1 for the next row of points
    }
    
    // Calculate faces of the spline surface
    var n = num_seg;
    for(var i = 0; i < n; i++){
        for(var j = 0; j < n; j++){
            // Each face is a quad defined by four vertices
            faces.push([j + i * (n + 1), j + 1 + i * (n + 1), j + 1 + (i + 1) * (n + 1), j + (i + 1) * (n + 1)]);
        }
    }
    
    // Return the vertices and faces that make up the spline surface
    return {'vertices': vertices, 'faces': faces};
};


var Task3 = function(gl) {
    this.pitch = 0;
    this.yaw = 0;
    this.selectedModel = 0;
    this.subdivisionLevel = 1;
    this.gl = gl;

    gl.enable(gl.DEPTH_TEST);
    gl.depthFunc(gl.LEQUAL);

    this.controlCages = [
        this.buildDebugPatch(),
        {'vertices': TeapotVertices, 'patches': TeapotPatches}
    ];

    this.wireCages = [];
    for (var i = 0; i < this.controlCages.length; ++i)
        this.wireCages.push(this.buildWireCage(this.controlCages[i]));
}

Task3.prototype.buildDebugPatch = function() {
    var transform = Matrix.rotate(25, 1, 0, 0).multiply(Matrix.rotate(45, 0, 1, 0));

    var vertices = [];
    var coords = [-1.5, -0.5, 0.5, 1.5];
    var height = [0, 1, 1, 0]
    for (var i = 0; i < 4; ++i)
        for (var j = 0; j < 4; ++j)
            vertices.push(transform.transformPoint(new Vector(coords[i], height[i]*height[j], coords[j])));

    var patch = [
         0,  1,  2,  3,
         4,  5,  6,  7,
         8,  9, 10, 11,
        12, 13, 14, 15
    ];

    return {'vertices': vertices, 'patches': [patch]};
}

Task3.prototype.buildWireCage = function(cage) {
    var vertices = [];
    var faces = [];
    for (var i = 0; i < cage.patches.length; ++i) {
        for (var m = 0; m < 3; ++m) {
            for (var n = 0; n < 3; ++n) {
                faces.push([
                    vertices.length + (m + 0)*4 + (n + 0),
                    vertices.length + (m + 0)*4 + (n + 1),
                    vertices.length + (m + 1)*4 + (n + 1),
                    vertices.length + (m + 1)*4 + (n + 0)
                ]);
            }
        }
        for (var j = 0; j < 16; ++j)
            vertices.push(cage.vertices[cage.patches[i][j]]);
    }

    return new Mesh(vertices, faces, false).toTriangleMesh(this.gl);
}

Task3.prototype.setSubdivisionLevel = function(subdivisionLevel) {
    this.subdivisionLevel = subdivisionLevel;
    this.computeMesh();
}

Task3.prototype.selectModel = function(idx) {
    this.selectedModel = idx;
    this.computeMesh();
}

Task3.prototype.computeMesh = function() {
    var vertices = [];
    var faces = [];

    var cage = this.controlCages[this.selectedModel];
    for (var i = 0; i < cage.patches.length; ++i) {
        var patch = [];
        for (var m = 0; m < 4; ++m) {
            patch.push([]);
            for (var n = 0; n < 4; ++n)
                patch[m].push(cage.vertices[cage.patches[i][m*4 + n]].clone());
        }

        var result = splinePatchTesselation(patch, this.subdivisionLevel);
        for (var j = 0; j < result.faces.length; ++j)
            for (var k = 0; k < result.faces[j].length; ++k)
                result.faces[j][k] += vertices.length;

        vertices = vertices.concat(result.vertices);
        faces = faces.concat(result.faces);
    }

    this.mesh = new Mesh(vertices, faces, false).toTriangleMesh(this.gl);
}

Task3.prototype.render = function(gl, w, h) {
    gl.viewport(0, 0, w, h);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    var projection = Matrix.perspective(35, w/h, 0.1, 100);
    var view =
        Matrix.translate(0, 0, -5).multiply(
        Matrix.rotate(this.pitch, 1, 0, 0)).multiply(
        Matrix.rotate(this.yaw, 0, 1, 0));
    var model = new Matrix();

    this.wireCages[this.selectedModel].render(gl, model, view, projection, false, true, new Vector(0.7, 0.7, 0.7));

    this.mesh.render(gl, model, view, projection);
}

Task3.prototype.dragCamera = function(dx, dy) {
    this.pitch = Math.min(Math.max(this.pitch + dy*0.5, -90), 90);
    this.yaw = this.yaw + dx*0.5;
}