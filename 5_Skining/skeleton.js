// Skeleton class contains all the bones in an array
// Hierarchies are established through the bones themselves.
function Skeleton(gl) {
	this.mJoints = new Array();
}

// Add a joint to the skeleton list.
Skeleton.prototype.addJoint = function (val) {
	this.mJoints.push(val);
}

// Given an index into the skeleton hierarchy, return the actual joint.
Skeleton.prototype.getJoint = function (index) {
	if (index < this.mJoints.length)
		return this.mJoints[index];
	else return null;
}

// Return the number of joints within the skeleton
Skeleton.prototype.getNumJoints = function () {
	return this.mJoints.length;
}

Skeleton.prototype.getJointName = function (index) {
	if (index < this.mJoints.length)
		return this.mJoints[index].mName;
	else return null;
}

Skeleton.prototype.computeBindingMatrices = function () {
	for (var i = 0; i < this.mJoints.length; i++)
		this.mJoints[i].computeBindingMatrix();
}

// Iterates through all the joints in the skeleton
// and renders them as a wireframe mesh.
Skeleton.prototype.render = function (gl, view, projection) {
	for (var i = 0; i < this.mJoints.length; i++)
		this.mJoints[i].render(gl, view, projection);
}
