// The Joint class represents a joint and its attached bone.
// The joint is attached at `head' and ends at 'tip' (both expressed with respect to the parent joint's local coordinate system)
// The rotation direction is perpendicular to both the joint segment and 'up'
function Joint(parent, head, tip, up, name, gl) {
	this.mParent = parent;
	this.mPosition = head;
	this.mForward = tip.subtract(head).unit();
	this.mJointAxis = this.mForward.cross(up).unit();
	this.mJointAngle = 0;
	this.mUp = this.mJointAxis.cross(this.mForward);
	this.mName = name;
	this.mLength = tip.subtract(head).length();

	// The binding matrix stores the orientation of the bone at the time it was attached to the skin
	// This matrix is null until the bone is attached to the skin
	this.mBindingMatrix = null;

	this.gl = gl;
	var shader = createShaderProgram(gl, SolidVertexSource, SolidFragmentSource);
	// we'll use a diamond shape octohedron to represent bones
	var boneVertices = [
		0.5, 0, 0,
		-0.5, 0, 0,
		-0.375, 0.5, 0,
		-0.375, -0.5, 0,
		-0.375, 0, 0.5,
		-0.375, 0, -0.5
	];
	var boneIndices = [
		0, 2, 4,
		0, 4, 3,
		0, 3, 5,
		0, 5, 2,
		1, 2, 5,
		1, 5, 3,
		1, 3, 4,
		1, 4, 2
	];
	this.mesh = new TriangleMesh(this.gl, boneVertices, boneIndices, shader, true, true, new Vector(0.4, 0.7, 0.4), new Vector(0.5, 1, 0.5));
}

// Helper functions.
Joint.prototype.setJointAngle = function (angle) {
	this.mJointAngle = angle;
}

Joint.prototype.setName = function (val) {
	this.mName = val;
}

// NOTE: if the skeleton has not been attached to the skin yet, this returns null
Joint.prototype.getBindingMatrix = function () {
	return this.mBindingMatrix;
}

Joint.prototype.getName = function () {
	return this.mName;
}


// TODO: Task 1 - Subtask 1
//
// Returns the local transform of the current joint
// This matrix rotates a point by `this.mJointAngle’ about the joint’s local rotation axis, 
// and then transform it into its parent's coordinate system. 
// The function Matrix.frame can help you construct the joint’s local coordinate frame directly from 
// four column vectors (recall the geometric meaning of the four columns).
// Hint: mJointAxis, mPosition, etc. are vector objects.
Joint.prototype.getLocalMatrix = function () {
	var rotationMatrix = Matrix.rotate(this.mJointAngle, this.mJointAxis.x, this.mJointAxis.y, this.mJointAxis.z);
	var translateMatrix = Matrix.translate(this.mPosition.x, this.mPosition.y, this.mPosition.z);
	var localMatrix = Matrix.multiply(translateMatrix, rotationMatrix);

	var parent_joint = this.mParent;
	if (parent_joint != null) {
		var localFrame = Matrix.frame(parent_joint.mForward, parent_joint.mUp, parent_joint.mJointAxis);
		return localFrame.multiply(localMatrix); 	
	} else {
		return localMatrix
	}
}

// TODO: Task 1 - Subtask 1
//
// Returns the world transform of the current joint.
// This is simply the transform of the parent joint (if any) multiplied by this joint's local transform
// Use the getLocalMatrix function you implemented earlier.

Joint.prototype.getWorldMatrix = function () {
	var localMatrix = this.getLocalMatrix();
	if (this.mParent) {
		var parentWorldMatrix = this.mParent.getWorldMatrix();
		return parentWorldMatrix.multiply(localMatrix);
	} else {
		return this.getLocalMatrix();
	}
}

// TODO: Task 1 - Subtask 1
//
// Compute the binding transform matrix of the joint.
// Hint: The binding matrix transforms points from world space to the local space of the joint
//       Use getWorldMatrix and a matrix inverse.
Joint.prototype.computeBindingMatrix = function () {
// ################ Edit your code below
	this.mBindingMatrix = this.getWorldMatrix().inverse();
// ################
}

// Returns the end points of the joint in world space
// Can be used to compute the distance to the line segment
// The returned values are 'v0' and 'v1'
Joint.prototype.getJointEndPoints = function () {
	return {
		v0: this.getWorldMatrix().transformPoint(new Vector(0, 0, 0)),
		v1: this.getWorldMatrix().transformPoint(new Vector(this.mLength, 0, 0))
	};
}

// Computes the model matrix used to draw the joint.
Joint.prototype.computeModelMatrix = function () {
	// read the following three lines in reverse order:
	// Finally, place the box in the world according to the Joint's world matrix
	return this.getWorldMatrix().
		// Then offset it so that one end coincides with the joint.
		multiply(Matrix.translate(this.mLength / 2, 0, 0).
			// Scale about the origin of the cube for the correct size
			multiply(Matrix.scale(this.mLength, 0.15 * this.mLength, 0.15 * this.mLength)));
}

// Renders the joint as a cube
Joint.prototype.render = function (gl, view, projection) {
	this.mModelMatrix = this.computeModelMatrix();
	this.mesh.render(gl, this.mModelMatrix, view, projection);
}