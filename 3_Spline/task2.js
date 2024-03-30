function catmullClarkSubdivision(vertices, faces) {
    var newVertices = [];
    var newFaces = [];
    
    var edgeMap = {};
    // This function tries to insert the centroid of the edge between
    // vertices a and b into the newVertices array.
    // If the edge has already been inserted previously, the index of
    // the previously inserted centroid is returned.
    // Otherwise, the centroid is inserted and its index returned.
    function getOrInsertEdge(a, b, centroid) {
        var edgeKey = a < b ? a + ":" + b : b + ":" + a;
        if (edgeKey in edgeMap) {
            return edgeMap[edgeKey];
        } else {
            var idx = newVertices.length;
            newVertices.push(centroid);
            edgeMap[edgeKey] = idx;
            return idx;
        }
    }
    
    // TODO: Implement a function that computes one step of the Catmull-Clark subdivision algorithm.
    //
    // Input:
    // `vertices`: An array of Vectors, describing the positions of every vertex in the mesh
    // `faces`: An array of arrays, specifying a list of faces. Every face is a list of vertex
    //          indices, specifying its corners. Faces may contain an arbitrary number
    //          of vertices (expect triangles, quadrilaterals, etc.)
    //
    // Output: Fill in newVertices and newFaces with the vertex positions and
    //         and faces after one step of Catmull-Clark subdivision.
    // It should hold:
    //         newFaces[i].length == 4, for all i
    //         (even though the input may consist of any of triangles, quadrilaterals, etc.,
    //          Catmull-Clark will always output quadrilaterals)
    //
    // Pseudo code follows:

    // ************************************
    // ************** Step 1 **************
    // ******** Linear subdivision ********
    // ************************************
    // for v in vertices:
    //      addVertex(v.clone())
    
    // for face in faces:
    //      facePointIndex = addVertex(centroid(face))
    //      for v1 in face:
    //          v0 = previousVertex(face, v1)
    //          v2 = nextVertex(face, v1)
    //          edgePointA = getOrInsertEdge(v0, v1, centroid(v0, v1))
    //          edgePointB = getOrInsertEdge(v1, v2, centroid(v1, v2))
    //          addFace(facePointIndex, edgePointA, v1, edgePointB)

    // Copy all original vertices to the new vertex list
    for (var v of vertices) {
        newVertices.push(v.clone()); // Cloning ensures that the new list is independent of the original
    }
    
    // Function to calculate the centroid (geometric center) of a set of points
    function centroid(points) {
        var sum = new Vector(0, 0, 0);
        for (var p of points) {
            sum = sum.add(p);
        }
        return sum.divide(points.length);
    }
    
    // Process each face for subdivision
    for (var face of faces) {
        // Retrieve the actual vertex objects for each vertex index in the face
        var faceVertices = face.map(v => vertices[v]);
        var facePoint = centroid(faceVertices);
        var facePointIndex = newVertices.length;
        newVertices.push(facePoint);
        
        // Create new faces using original and new edge points
        for (var i = 0; i < face.length; i++) {
            var v1 = face[i]; // Current vertex
            var v0 = face[(i - 1 + face.length) % face.length]; // Previous vertex in the face
            var v2 = face[(i + 1) % face.length]; // Next vertex in the face
            
            // Calculate or retrieve the new edge points
            var edgePointA = getOrInsertEdge(v0, v1, centroid([vertices[v0], vertices[v1]]));
            var edgePointB = getOrInsertEdge(v1, v2, centroid([vertices[v1], vertices[v2]]));
            
            // Add the new face formed by the face point, two edge points, and the current vertex
            newFaces.push([facePointIndex, edgePointA, v1, edgePointB]);
        }
    }
    
    // ************************************
    // ************** Step 2 **************
    // ************ Averaging *************
    // ************************************
    // avgV = []
    // avgN = []
    // for i < len(newVertices):
    //      append(avgV, new Vector(0, 0, 0))
    //      append(avgN, 0)
    // for face in newFaces:
    //      c = centroid(face)
    //      for v in face:
    //          avgV[v] += c
    //          avgN[v] += 1
    //
    // for i < len(avgV):
    //      avgV[i] /= avgN[i]

    var avgV = new Array(newVertices.length).fill(null).map(() => new Vector(0, 0, 0));
    var avgN = new Array(newVertices.length).fill(0);

    for (var face of newFaces) {
        // calculate the centroid of current face
        var c = centroid(face.map(v => newVertices[v]));
        // Iterate over each vertex of the face
        for (var v of face) {
            // Add face's centroid to the average position of the vertex
            avgV[v] = avgV[v].add(c);
            // Increment the count of faces this vertex is part of
            avgN[v] += 1;
        }
    }

    // Update the position of all vertices to their average position
    for (var i = 0; i < avgV.length; i++) {
        // If the vertex is part of at least one face, update its position
        avgV[i] = avgV[i].divide(avgN[i]);
    }
    
    // ************************************
    // ************** Step 3 **************
    // ************ Correction ************
    // ************************************
    // for i < len(avgV):
    //      newVertices[i] = lerp(newVertices[i], avgV[i], 4/avgN[i])

    function lerp(v1, v2, t) {
        return v1.multiply(1 - t).add(v2.multiply(t));
    }

    // Adjust the position of each vertex in the newVertices array
    for (var i = 0; i < newVertices.length; i++) {
        // Only adjust vertices that are part of at least one face
        if (avgN[i] > 0) {
            // Interpolate between the original vertex position and the averaged position
            // The interpolation factor is based on the number of faces adjacent to the vertex
            newVertices[i] = lerp(newVertices[i], avgV[i], 4 / avgN[i]);
        }
    }

    // Do not remove this line
    return new Mesh(newVertices, newFaces);
};

function extraCreditMesh() {
    // TODO: Insert your own creative mesh here
    // var vertices = [
    //     new Vector( 0,  1,  0),
    //     new Vector(-1, -1,  0),
    //     new Vector( 0, -1, -1),
    //     new Vector( 1, -1,  0),
    //     new Vector( 0, -1,  1)
    // ];
    
    // var faces = [
    //     [0, 1, 2],
    //     [0, 2, 3],
    //     [0, 3, 4],
    //     [0, 4, 1],
    //     [1, 2, 3, 4]
    // ];

    var t = (1 + Math.sqrt(5)) / 2;

    // Vertices of an icosahedron
    var vertices = [
        new Vector(-1,  t,  0),
        new Vector( 1,  t,  0),
        new Vector(-1, -t,  0),
        new Vector( 1, -t,  0),
        new Vector( 0, -1,  t),
        new Vector( 0,  1,  t),
        new Vector( 0, -1, -t),
        new Vector( 0,  1, -t),
        new Vector( t,  0, -1),
        new Vector( t,  0,  1),
        new Vector(-t,  0, -1),
        new Vector(-t,  0,  1)
    ];

    // Faces of the icosahedron
    var faces = [
        [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
        [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
        [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
        [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
    ];

    
    return new Mesh(vertices, faces);
}

var Task2 = function(gl) {
    this.pitch = 0;
    this.yaw = 0;
    this.subdivisionLevel = 0;
    this.selectedModel = 0;
    this.gl = gl;
    
    gl.enable(gl.DEPTH_TEST);
    gl.depthFunc(gl.LEQUAL);
    
    this.baseMeshes = [];
    for (var i = 0; i < 6; ++i)
        this.baseMeshes.push(this.baseMesh(i).toTriangleMesh(gl));
    
    this.computeMesh();
}

Task2.prototype.setSubdivisionLevel = function(subdivisionLevel) {
    this.subdivisionLevel = subdivisionLevel;
    this.computeMesh();
}

Task2.prototype.selectModel = function(idx) {
    this.selectedModel = idx;
    this.computeMesh();
}

Task2.prototype.baseMesh = function(modelIndex) {
    switch(modelIndex) {
    case 0: return createCubeMesh(); break;
    case 1: return createTorus(8, 4, 0.5); break;
    case 2: return createSphere(4, 3); break;
    case 3: return createIcosahedron(); break;
    case 4: return createOctahedron(); break;
    case 5: return extraCreditMesh(); break;
    }
    return null;
}

Task2.prototype.computeMesh = function() {
    var mesh = this.baseMesh(this.selectedModel);
    
    for (var i = 0; i < this.subdivisionLevel; ++i)
        mesh = catmullClarkSubdivision(mesh.vertices, mesh.faces);
    
    this.mesh = mesh.toTriangleMesh(this.gl);
}

Task2.prototype.render = function(gl, w, h) {
    gl.viewport(0, 0, w, h);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    
    var projection = Matrix.perspective(35, w/h, 0.1, 100);
    var view =
        Matrix.translate(0, 0, -5).multiply(
        Matrix.rotate(this.pitch, 1, 0, 0)).multiply(
        Matrix.rotate(this.yaw, 0, 1, 0));
    var model = new Matrix();
    
    if (this.subdivisionLevel > 0)
        this.baseMeshes[this.selectedModel].render(gl, model, view, projection, false, true, new Vector(0.7, 0.7, 0.7));

    this.mesh.render(gl, model, view, projection);
}

Task2.prototype.dragCamera = function(dx, dy) {
    this.pitch = Math.min(Math.max(this.pitch + dy*0.5, -90), 90);
    this.yaw = this.yaw + dx*0.5;
}
