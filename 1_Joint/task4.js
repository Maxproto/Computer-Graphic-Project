var Bone = function(parent, position, scale, jointLocation, jointAxis) {
    this.parent = parent;
    this.position = position;
    this.scale = scale;
    this.jointLocation = jointLocation
    this.jointAxis = jointAxis;
    this.jointAngle = 0;
}

Bone.prototype.setJointAngle = function(angle) {
    this.jointAngle = angle;
}

Bone.prototype.computePoseMatrix = function() {
    var pose = new SimpleMatrix();
    // TODO: Compute the pose matrix of this bone (i.e. transformation matrix
    //       with translation x rotation, but no scaling) and return it.
    //       The matrix should translate by this.position and rotate around this.jointAxis
    //       at this.jointLocation by this.jointAngle

    //       If this.parent is not null, you should also apply the pose matrix of the parent
    //       to get a hierarchical transform.

// ################ Edit your code below
// ################
    positionTranslateMatrix = SimpleMatrix.translate(this.position[0], this.position[1], this.position[2]);
    rotationMatrix = rotateAroundAxisAtPoint(this.jointAxis, this.jointAngle, this.jointLocation);
    pose = positionTranslateMatrix.multiply(rotationMatrix).multiply(pose);

    if (this.parent != null) {
        var parentPose = this.parent.computePoseMatrix();
        pose = parentPose.multiply(pose);
    }

    return pose;
}

Bone.prototype.computeModelMatrix = function() {
    var pose = new SimpleMatrix();
    // TODO: Compute the model matrix of this bone (i.e. pose matrix x scaling)
    //       and return it.
    //       Use this.computePoseMatrix and this.scale to build the matrix

// ################ Edit your code below
// ################

    pose = this.computePoseMatrix();
    pose = pose.multiply(SimpleMatrix.scale(this.scale[0], this.scale[1], this.scale[2]));

    return pose;
}

var Task4 = function(canvas) {
    this.cameraAngle = 0;
    this.mesh = new WireframeMesh_Two(WireCubePositions, WireCubeIndices);

    var hip       = new Bone(     null, [0,    1.5, 0  ], [0.5,  0.3, 0.2], [0, 0,    0   ], [0, 1, 0]);
    var leftThigh = new Bone(      hip, [0.5, -1.1, 0.1], [0.1,  0.7, 0.1], [0, 0.7,  0   ], [1, 0, 0]);
    var leftShin  = new Bone(leftThigh, [0,   -1.5, 0  ], [0.1,  0.7, 0.1], [0, 0.7,  0   ], [1, 0, 0]);
    var leftFoot  = new Bone( leftShin, [0,   -0.9, 0.2], [0.15, 0.1, 0.3], [0, 0.1, -0.25], [1, 0, 0]);

    this.bones = [hip, leftThigh, leftShin, leftFoot];
}

Task4.prototype.setJointAngle = function(boneIndex, angle) {
    this.bones[boneIndex].setJointAngle(angle);
}

Task4.prototype.render = function(canvas, gl, w, h) {
    var context = canvas.getContext('2d');
    clear(context, w, h);
    
    var projection = SimpleMatrix.perspective(45, w/h, 0.1, 100);
    
    var view = SimpleMatrix.rotate(this.cameraAngle, 1, 0, 0).multiply(
        SimpleMatrix.translate(0, 0, 8));

    for (var i = 0; i < this.bones.length; ++i) {
        var boneModel = this.bones[i].computeModelMatrix();
        
        this.mesh.render(canvas, boneModel, view, projection);
    }
}

Task4.prototype.dragCamera = function(dy) {
    this.cameraAngle = Math.min(Math.max(this.cameraAngle - dy*0.5, -90), 90);
}
