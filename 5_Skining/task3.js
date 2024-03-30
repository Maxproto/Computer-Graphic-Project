// TODO: Task 3 - Skinning a custom mesh.
//
// In this task you will be skinning a given 'arm' mesh with multiple bones.
// We have already provided the initial locations of the two bones for your convenience
// You will have to add multiple bones to do a convincing job.
var Task3 = function (gl) {
	this.distance = 10;
	this.pitch = 30;
	this.yaw = 0;
	this.lookat = new Vector(5, 0, 0);
	this.animateFlag = false; // flag to stop the animation

	this.showJoints = true;

	// Create a skin mesh
	this.skin = new SkinMesh(gl);
	this.skin.createArmSkin();

	// Create an empty skeleton for now.
	this.skeleton = new Skeleton();

	// TODO: Task-3
	// Create additional joints as required.
	this.mJoint1 = new Joint(null, new Vector(-15, 0, 0), new Vector(-8.5, 0, 0), new Vector(0, 1, 0), "Upper Arm", gl);
	this.mJoint2 = new Joint(this.mJoint1, new Vector(7, 0, 0), new Vector(12.5, 0, 0), new Vector(0, -1, 0), "Forearm", gl);
	this.mWrist = new Joint(this.mJoint2, new Vector(6, 0, 0), new Vector(7.5, 0, 0), new Vector(0, 1, 0), "Wrist", gl);

	this.mThumbJoint_1 = new Joint(this.mWrist, new Vector(0.5, 0.5, 1), new Vector(1, 0.5, 1), new Vector(0, 1, 0), "Thumb 1", gl);
	this.mThumbJoint_2 = new Joint(this.mThumbJoint_1, new Vector(0.8, 0.3, 0.3), new Vector(1.2, 0.3, 0.3), new Vector(0, 0, -1), "Thumb 2", gl);

	this.mIndexFingerJoint_1 = new Joint(this.mWrist, new Vector(1.8, 0.25, 0.7), new Vector(2.6, 0.2, 0.7), new Vector(0, 1, 0), "Index Finger 1", gl);
	this.mIndexFingerJoint_2 = new Joint(this.mIndexFingerJoint_1, new Vector(0.8, 0.3, 0.1), new Vector(1.3, 0.3, 0.1), new Vector(0, 1, 0), "Index Finger 2", gl);

	this.mMiddleFingerJoint_1 = new Joint(this.mWrist, new Vector(1.6, 0, 0), new Vector(2.6, 0, 0), new Vector(0, 1, 0), "Middle Finger 1", gl);
	this.mMiddleFingerJoint_2 = new Joint(this.mMiddleFingerJoint_1, new Vector(1, 0.3, 0.1), new Vector(1.7, 0.3, 0.1), new Vector(0, 1, 0), "Middle Finger 2", gl);

	this.mRingFingerJoint_1 = new Joint(this.mWrist, new Vector(1.75, 0.2, -0.5), new Vector(2.5, 0.2, -0.5), new Vector(0, 1, 0), "Ring Finger 1", gl);
	this.mRingFingerJoint_2 = new Joint(this.mRingFingerJoint_1, new Vector(1, 0.3, -0.1), new Vector(1.5, 0.3, -0.1), new Vector(0, 1, 0), "Ring Finger 2", gl);
	
	this.mPinkyJoint_1 = new Joint(this.mWrist, new Vector(1.5, 0.4, -1), new Vector(2, 0.4, -1), new Vector(0, 1, 0), "Pinky 1", gl);
	this.mPinkyJoint_2 = new Joint(this.mPinkyJoint_1, new Vector(0.7, 0.4, -0.1), new Vector(1.1, 0.4, -0.1), new Vector(0, 1, 0), "Pinky 2", gl);
	
	// Add your joints to the skeleton here
	this.skeleton.addJoint(this.mJoint1);		
	this.skeleton.addJoint(this.mJoint2);
	this.skeleton.addJoint(this.mWrist);
	this.skeleton.addJoint(this.mThumbJoint_1);
	this.skeleton.addJoint(this.mThumbJoint_2);
	this.skeleton.addJoint(this.mIndexFingerJoint_1);
	this.skeleton.addJoint(this.mIndexFingerJoint_2);
	this.skeleton.addJoint(this.mMiddleFingerJoint_1);
	this.skeleton.addJoint(this.mMiddleFingerJoint_2);
	this.skeleton.addJoint(this.mRingFingerJoint_1);
	this.skeleton.addJoint(this.mRingFingerJoint_2);
	this.skeleton.addJoint(this.mPinkyJoint_1);
	this.skeleton.addJoint(this.mPinkyJoint_2);

	// set the skeleton
	this.skin.setSkeleton(this.skeleton, "linear");

	gl.enable(gl.DEPTH_TEST);
}

Task3.prototype.render = function (gl, w, h) {
	gl.clearColor(0.0, 0.0, 0.0, 1.0);
	gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

	var projection = Matrix.perspective(60, w / h, 0.1, 100);
	var view =
		Matrix.translate(0, 0, -this.distance).multiply(
			Matrix.rotate(this.pitch, 1, 0, 0)).multiply(
				Matrix.rotate(this.yaw, 0, 1, 0)).multiply(
					Matrix.translate(this.lookat.x, this.lookat.y, this.lookat.z)
				);

	if (this.skin)
		this.skin.render(gl, view, projection, false);

	if (this.skeleton && this.showJoints) {
		gl.clear(gl.DEPTH_BUFFER_BIT);
		this.skeleton.render(gl, view, projection);
	}
}

Task3.prototype.setJointAngle = function (id, value) {
	if (this.skeleton && id < this.skeleton.getNumJoints()) {
		this.skeleton.getJoint(id).setJointAngle(value);
		this.skin.updateSkin();
	}
}

Task3.prototype.drag = function (event) {
	var dx = event.movementX;
	var dy = event.movementY;
	this.pitch = Math.min(Math.max(this.pitch + dy * 0.5, -90), 90);
	this.yaw = this.yaw + dx * 0.5;
}

Task3.prototype.wheel = function (event) {
	const newZoom = this.distance * Math.pow(2, event.deltaY * -0.01);
	this.distance = Math.max(0.02, Math.min(100, newZoom));
}

Task3.prototype.showJointWeights = function (idx) {
	this.skin.showJointWeights(idx);
	this.skin.updateSkin();
}

Task3.prototype.setShowJoints = function (showJoints) {
	this.showJoints = showJoints;
}

Task3.prototype.animation = function () {
	this.animateFlag = true;
    const startTime = Date.now();
    const duration = 4000;
	let animationFrameId;

    const animate = () => {
		if (!this.animateFlag) {
			return;
		}

        const currentTime = Date.now();
        const timegap = currentTime - startTime;

        if (timegap <= 1000) {
            const progress = timegap / 1000; 
            this.distance = 10 + (15 - 10) * progress; 
            this.pitch = 30 + (40 - 30) * progress;
            this.yaw = 0 + (-90 - 0) * progress;
            this.lookat = new Vector(5 + (3 - 5) * progress, 0, 0);
        }

        if (timegap > 1000 && timegap <= 2000) {
            const progress = (timegap - 1000) / 1000;
            const targetAngle3 = 30 * progress;
            const targetAngle4 = 80 * progress;
            const targetAngle9 = 120 * progress;
            const targetAngle10 = 120 * progress;
            const targetAngle11 = 120 * progress;
            const targetAngle12 = 120 * progress;
            this.setJointAngle(3, targetAngle3);
            this.setJointAngle(4, targetAngle4);
            this.setJointAngle(9, targetAngle9);
            this.setJointAngle(10, targetAngle10);
            this.setJointAngle(11, targetAngle11);
            this.setJointAngle(12, targetAngle12);
        }

        if (timegap > 2000 && timegap <= 4000) {
            const baseTime = timegap - 2000;
            const angle0 = 20 * Math.abs(Math.sin(baseTime / 500 * Math.PI)); 
            const angle1 = 50 * Math.abs(Math.sin(baseTime / 500 * Math.PI)); 
            const angle2 = 30 * Math.abs(Math.sin(baseTime / 500 * Math.PI)); 
            this.setJointAngle(0, angle0);
            this.setJointAngle(1, angle1);
            this.setJointAngle(2, angle2);
        }

        if (timegap <= duration) {
            animationFrameId = requestAnimationFrame(animate);
        } else {
			this.resetState();
		}
    };

    animate();
	this.lastAnimationFrameId = animationFrameId;
};

Task3.prototype.resetState = function () {
    this.distance = 10;
    this.pitch = 30;
    this.yaw = 0;
    this.lookat = new Vector(5, 0, 0);
    this.setJointAngle(0, 0);
    this.setJointAngle(1, 0);
    this.setJointAngle(2, 0);
    this.setJointAngle(3, 0);
    this.setJointAngle(4, 0);
    this.setJointAngle(9, 0);
    this.setJointAngle(10, 0);
    this.setJointAngle(11, 0);
    this.setJointAngle(12, 0);
};

function toggleAnimation(checked) {
    if (checked) {
        task3.animation();
    } else {
		task3.animateFlag = false;
		if (task3.lastAnimationFrameId !== undefined) {
            cancelAnimationFrame(task3.lastAnimationFrameId);
        }
		task3.resetState()
    }
}
