function createPlane(subd) {
    var vertices = [];
    var faces = [];
    
    for (var i = 0; i <= subd; ++i) {
        for (var j = 0; j <= subd; ++j) {
            vertices.push(new Vector(2*i/subd - 1, 2*j/subd - 1, 0));
            if (i > 0 && j > 0) {
                faces.push([
                    (i - 0)*(subd + 1) + (j - 0),
                    (i - 1)*(subd + 1) + (j - 0),
                    (i - 1)*(subd + 1) + (j - 1),
                    (i - 0)*(subd + 1) + (j - 1)
                ]);
            }
        }
    }
    
    return new Mesh(vertices, faces, false);
}

var createCubeMesh = function() {
    var vertices = [
        new Vector(-1, -1, -1), new Vector(-1, -1,  1), new Vector(-1,  1, -1), new Vector(-1,  1,  1),
        new Vector( 1, -1, -1), new Vector( 1, -1,  1), new Vector( 1,  1, -1), new Vector( 1,  1,  1)
    ];
    var faces = [
        [0, 1, 3, 2], [4, 5, 7, 6],
        [0, 1, 5, 4], [2, 3, 7, 6],
        [0, 2, 6, 4], [1, 3, 7, 5]
    ]
    return new Mesh(vertices, faces, false);
}

var createTorus = function(phiSubd, thetaSubd, radius) {
    var vertices = [];
    var faces = [];
    
    for (var i = 0; i <= phiSubd; ++i) {
        for (var j = 0; j <= thetaSubd; ++j) {
            var phi = i*Math.PI*2/phiSubd;
            var theta = j*Math.PI*2/thetaSubd;
            
            vertices.push(new Vector(
                Math.cos(phi)*(1.0 + Math.cos(theta)*radius),
                Math.sin(phi)*(1.0 + Math.cos(theta)*radius),
                Math.sin(theta)*radius
            ));
            
            if (i > 0 && j > 0) {
                faces.push([
                    (i - 0)*(thetaSubd + 1) + (j - 0),
                    (i - 0)*(thetaSubd + 1) + (j - 1),
                    (i - 1)*(thetaSubd + 1) + (j - 1),
                    (i - 1)*(thetaSubd + 1) + (j - 0)
                ]);
            }
        }
    }
    
    return new Mesh(vertices, faces, true);
}

var createSphere = function(phiSubd, thetaSubd) {
    var vertices = [];
    var faces = [];
    
    for (var i = 0; i <= phiSubd; ++i) {
        for (var j = 0; j <= thetaSubd; ++j) {
            var phi = i*Math.PI*2/phiSubd;
            var theta = Math.PI*(j/thetaSubd - 0.5);
            
            vertices.push(new Vector(
                Math.cos(theta)*Math.cos(phi),
                Math.sin(theta),
                Math.cos(theta)*Math.sin(phi)
            ));
            
            if (i > 0 && j > 0) {
                faces.push([
                    (i - 0)*(thetaSubd + 1) + (j - 0),
                    (i - 0)*(thetaSubd + 1) + (j - 1),
                    (i - 1)*(thetaSubd + 1) + (j - 1),
                    (i - 1)*(thetaSubd + 1) + (j - 0)
                ]);
            }
        }
    }
    
    return new Mesh(vertices, faces, true);
}

var createIcosahedron = function() {
	var t = (1.0 + Math.sqrt(5.0))*0.5;

	var vertices = [
		new Vector(-1,  t,  0), new Vector(1, t, 0), new Vector(-1, -t,  0), new Vector( 1, -t,  0),
		new Vector( 0, -1,  t), new Vector(0, 1, t), new Vector( 0, -1, -t), new Vector( 0,  1, -t),
		new Vector( t,  0, -1), new Vector(t, 0, 1), new Vector(-t,  0, -1), new Vector(-t,  0,  1)
	];
	var faces = [
		[0, 11,  5], [0,  5,  1], [ 0,  1,  7], [ 0,  7, 10], [0, 10, 11],
		[1,  5,  9], [5, 11,  4], [11, 10,  2], [10,  7,  6], [7,  1,  8],
		[3,  9,  4], [3,  4,  2], [ 3,  2,  6], [ 3,  6,  8], [3,  8,  9],
		[4,  9,  5], [2,  4, 11], [ 6,  2, 10], [ 8,  6,  7], [9,  8,  1]
	];
    
    for (var i = 0; i < vertices.length; ++i)
        Vector.multiply(vertices[i], 1.0/t, vertices[i]);
    
    return new Mesh(vertices, faces, false);
}

function createOctahedron() {
	var vertices = [
        new Vector(1,  0, 0), new Vector(-1, 0, 0), new Vector(0, 1,  0),
        new Vector(0, -1, 0), new Vector( 0, 0, 1), new Vector(0, 0, -1)
	];
	var faces = [
		[0, 2, 4], [0, 4, 3], [0, 3, 5], [0, 5, 2],
        [1, 2, 5], [1, 5, 3], [1, 3, 4], [1, 4, 2]
	];
    
    for (var i = 0; i < vertices.length; ++i)
        Vector.multiply(vertices[i], 1.5, vertices[i]);
        
    return new Mesh(vertices, faces, false);
}
