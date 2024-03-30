var CatmullRomSpline = function(canvasId)
{
	// Set up all the data related to drawing the curve
	this.cId = canvasId;
	this.dCanvas = document.getElementById(this.cId);
	this.ctx = this.dCanvas.getContext('2d');
	this.dCanvas.addEventListener('resize', this.computeCanvasSize());
	this.computeCanvasSize();

	// Setup all the data related to the actual curve.
	this.nodes = new Array();
	this.showControlPolygon = true;
	this.showTangents = true;

	// Assumes a equal parametric split strategy
	this.numSegments = 16;

	// Global tension parameter
	this.tension = 0.5;

	// Setup event listeners
	this.cvState = CVSTATE.Idle;
	this.activeNode = null;

	// closure
	var that = this;

	// Event listeners
	this.dCanvas.addEventListener('mousedown', function(event) {
        that.mousePress(event);
    });

	this.dCanvas.addEventListener('mousemove', function(event) {
		that.mouseMove(event);
	});

	this.dCanvas.addEventListener('mouseup', function(event) {
		that.mouseRelease(event);
	});

	this.dCanvas.addEventListener('mouseleave', function(event) {
		that.mouseRelease(event);
	});
}

CatmullRomSpline.prototype.setShowControlPolygon = function(bShow)
{
	this.showControlPolygon = bShow;
}

CatmullRomSpline.prototype.setShowTangents = function(bShow)
{
	this.showTangents = bShow;
}

CatmullRomSpline.prototype.setTension = function(val)
{
	this.tension = val;
}

CatmullRomSpline.prototype.setNumSegments = function(val)
{
	this.numSegments = val;
}

CatmullRomSpline.prototype.mousePress = function(event)
{
	if (event.button == 0) {
		this.activeNode = null;
		var pos = getMousePos(event);

		// Try to find a node below the mouse
		for (var i = 0; i < this.nodes.length; i++) {
			if (this.nodes[i].isInside(pos.x,pos.y)) {
				this.activeNode = this.nodes[i];
				break;
			}
		}
	}

	// No node selected: add a new node
	if (this.activeNode == null) {
		this.addNode(pos.x,pos.y);
		this.activeNode = this.nodes[this.nodes.length-1];
	}

	this.cvState = CVSTATE.SelectPoint;
	event.preventDefault();
}

CatmullRomSpline.prototype.mouseMove = function(event) {
	if (this.cvState == CVSTATE.SelectPoint || this.cvState == CVSTATE.MovePoint) {
		var pos = getMousePos(event);
		this.activeNode.setPos(pos.x,pos.y);
	} else {
		// No button pressed. Ignore movement.
	}
}

CatmullRomSpline.prototype.mouseRelease = function(event)
{
	this.cvState = CVSTATE.Idle; this.activeNode = null;
}

CatmullRomSpline.prototype.computeCanvasSize = function()
{
	var renderWidth = Math.min(this.dCanvas.parentNode.clientWidth - 20, 820);
    var renderHeight = Math.floor(renderWidth*9.0/16.0);
    this.dCanvas.width = renderWidth;
    this.dCanvas.height = renderHeight;
}

CatmullRomSpline.prototype.drawControlPolygon = function()
{
	for (var i = 0; i < this.nodes.length-1; i++)
		drawLine(this.ctx, this.nodes[i].x, this.nodes[i].y,
					  this.nodes[i+1].x, this.nodes[i+1].y);
}

CatmullRomSpline.prototype.drawControlPoints = function()
{
	for (var i = 0; i < this.nodes.length; i++)
		this.nodes[i].draw(this.ctx);
}

CatmullRomSpline.prototype.drawTangents = function()
{

// ################ Edit your code below
	// TODO: Task 4
    // Compute tangents at the nodes and draw them using drawLine(this.ctx, x0, y0, x1, y1);
	// Note: Tangents are available only for 2,..,n-1 nodes. The tangent is not defined for 1st and nth node.
    // The tangent of the i-th node can be computed from the (i-1)th and (i+1)th node
    // Normalize the tangent and compute a line with a length of 50 pixels from the current control point.
// ################
	const tangentLength = 50;

	for (let i = 1; i < this.nodes.length - 1; i++) {
		const currNode = this.nodes[i];
		const prevNode = this.nodes[i - 1];
		const nextNode = this.nodes[i + 1];

		let diffX = nextNode.x - prevNode.x;
		let diffY = nextNode.y - prevNode.y;

		const magnitude = Math.sqrt(diffX * diffX + diffY * diffY);
		// Normalization
		diffX /= magnitude;
		diffY /= magnitude;

		const endX = currNode.x + diffX * tangentLength;
		const endY = currNode.y + diffY * tangentLength;

		setColors(this.ctx, 'red');
		drawLine(this.ctx, currNode.x, currNode.y, endX, endY);
	}
}

CatmullRomSpline.prototype.draw = function()
{

// ################ Edit your code below
	// TODO: Task 5: Draw the Catmull-Rom curve (see the assignment for more details)
    // Hint: You should use drawLine to draw lines, i.e.
	// setColors(this.ctx,'black');
	// .....
	// drawLine(this.ctx, x0, y0, x1, y1);
	// ....
// ################
	const numSegments = this.numSegments || 20;

	for (let i = 0; i < this.nodes.length - 3; i++) {
		for (let j = 0; j < numSegments; j++) {
			let t = j / numSegments;
			let t2 = t * t;
			let t3 = t2 * t;

			let p0 = this.nodes[i];
			let p1 = this.nodes[i + 1];
			let p2 = this.nodes[i + 2];
			let p3 = this.nodes[i + 3];

			// Adjust tangents for tension
			let m1x = (p2.x - p0.x) * this.tension;
			let m1y = (p2.y - p0.y) * this.tension;
			let m2x = (p3.x - p1.x) * this.tension;
			let m2y = (p3.y - p1.y) * this.tension;

			// Catmull-Rom Spline Formula with Tension
			let x = (2 * p1.x - 2 * p2.x + m1x + m2x) * t3 + (-3 * p1.x + 3 * p2.x - 2 * m1x - m2x) * t2 + m1x * t + p1.x;
			let y = (2 * p1.y - 2 * p2.y + m1y + m2y) * t3 + (-3 * p1.y + 3 * p2.y - 2 * m1y - m2y) * t2 + m1y * t + p1.y;

			// Calculate the next point on the curve
			let tNext = (j + 1) / numSegments;
			let t2Next = tNext * tNext;
			let t3Next = t2Next * tNext;

			let xNext = (2 * p1.x - 2 * p2.x + m1x + m2x) * t3Next + (-3 * p1.x + 3 * p2.x - 2 * m1x - m2x) * t2Next + m1x * tNext + p1.x;
			let yNext = (2 * p1.y - 2 * p2.y + m1y + m2y) * t3Next + (-3 * p1.y + 3 * p2.y - 2 * m1y - m2y) * t2Next + m1y * tNext + p1.y;

			// Draw the line segment
			setColors(this.ctx, 'black');
			drawLine(this.ctx, x, y, xNext, yNext);
		}
	}
};

// NOTE: Task 4 code.
CatmullRomSpline.prototype.drawTask4 = function()
{
	// clear the rect
	this.ctx.clearRect(0, 0, this.dCanvas.width, this.dCanvas.height);

    if (this.showControlPolygon) {
		// Connect nodes with a line
        setColors(this.ctx,'rgb(10,70,160)');
        for (var i = 1; i < this.nodes.length; i++) {
            drawLine(this.ctx, this.nodes[i-1].x, this.nodes[i-1].y, this.nodes[i].x, this.nodes[i].y);
        }
		// Draw nodes
		setColors(this.ctx,'rgb(10,70,160)','white');
		for (var i = 0; i < this.nodes.length; i++) {
			this.nodes[i].draw(this.ctx);
		}
    }

	// We need atleast 4 points to start rendering the curve.
    if(this.nodes.length < 4) return;

	// draw all tangents
	if(this.showTangents)
		this.drawTangents();
}

// NOTE: Task 5 code.
CatmullRomSpline.prototype.drawTask5 = function()
{
	// clear the rect
	this.ctx.clearRect(0, 0, this.dCanvas.width, this.dCanvas.height);

    if (this.showControlPolygon) {
		// Connect nodes with a line
        setColors(this.ctx,'rgb(10,70,160)');
        for (var i = 1; i < this.nodes.length; i++) {
            drawLine(this.ctx, this.nodes[i-1].x, this.nodes[i-1].y, this.nodes[i].x, this.nodes[i].y);
        }
		// Draw nodes
		setColors(this.ctx,'rgb(10,70,160)','white');
		for (var i = 0; i < this.nodes.length; i++) {
			this.nodes[i].draw(this.ctx);
		}
    }

	// We need atleast 4 points to start rendering the curve.
    if(this.nodes.length < 4) return;

	// Draw the curve
	this.draw();

	if(this.showTangents)
		this.drawTangents();
}


// Add a control point to the curve
CatmullRomSpline.prototype.addNode = function(x,y)
{
	this.nodes.push(new Node(x,y));
}
