var BSpline = function(canvasId)
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

BSpline.prototype.setShowControlPolygon = function(bShow)
{
	this.showControlPolygon = bShow;
}

BSpline.prototype.setNumSegments = function(val)
{
	this.numSegments = val;
}

BSpline.prototype.mousePress = function(event)
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

BSpline.prototype.mouseMove = function(event) {
	if (this.cvState == CVSTATE.SelectPoint || this.cvState == CVSTATE.MovePoint) {
		var pos = getMousePos(event);
		this.activeNode.setPos(pos.x,pos.y);
	} else {
		// No button pressed. Ignore movement.
	}
}

BSpline.prototype.mouseRelease = function(event)
{
	this.cvState = CVSTATE.Idle; this.activeNode = null;
}

BSpline.prototype.computeCanvasSize = function()
{
	var renderWidth = Math.min(this.dCanvas.parentNode.clientWidth - 20, 820);
    var renderHeight = Math.floor(renderWidth*9.0/16.0);
    this.dCanvas.width = renderWidth;
    this.dCanvas.height = renderHeight;
}

BSpline.prototype.drawControlPolygon = function()
{
	for (var i = 0; i < this.nodes.length-1; i++)
		drawLine(this.ctx, this.nodes[i].x, this.nodes[i].y,
					  this.nodes[i+1].x, this.nodes[i+1].y);
}

BSpline.prototype.drawControlPoints = function()
{
	for (var i = 0; i < this.nodes.length; i++)
		this.nodes[i].draw(this.ctx);
}

BSpline.prototype.draw = function()
{

// ################ Edit your code below
	// TODO: Task 6: Draw the B-Spline curve (see the assignment for more details)
    // Hint: You can base this off of your Catmull-Rom code
// ################
	const numSegments = this.numSegments || 20;

    for (let i = 0; i < this.nodes.length - 3; i++) {
        for (let j = 0; j < numSegments; j++) {
            let t = j / numSegments;
            let t2 = t * t;
            let t3 = t * t * t;

            let p0 = this.nodes[i];
            let p1 = this.nodes[i + 1];
            let p2 = this.nodes[i + 2];
            let p3 = this.nodes[i + 3];

            // B-Spline basis functions
            let B0 = (1 - t) ** 3 / 6;
            let B1 = (3 * t3 - 6 * t2 + 4) / 6;
            let B2 = (-3 * t3 + 3 * t2 + 3 * t + 1) / 6;
            let B3 = t3 / 6;

            // Calculate the point on the B-Spline
            let x = p0.x * B0 + p1.x * B1 + p2.x * B2 + p3.x * B3;
            let y = p0.y * B0 + p1.y * B1 + p2.y * B2 + p3.y * B3;

            // Calculate the next point
            let tNext = (j + 1) / numSegments;
            let t2Next = tNext * tNext;
            let t3Next = t2Next * tNext;

            let B0Next = (1 - tNext) ** 3 / 6;
            let B1Next = (3 * t3Next - 6 * t2Next + 4) / 6;
            let B2Next = (-3 * t3Next + 3 * t2Next + 3 * tNext + 1) / 6;
            let B3Next = t3Next / 6;

            let xNext = p0.x * B0Next + p1.x * B1Next + p2.x * B2Next + p3.x * B3Next;
            let yNext = p0.y * B0Next + p1.y * B1Next + p2.y * B2Next + p3.y * B3Next;

            // Draw the line segment
            setColors(this.ctx, 'black');
            drawLine(this.ctx, x, y, xNext, yNext);
        }
    }
};

// NOTE: Task 6 code.
BSpline.prototype.drawTask6 = function()
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

}


// Add a control point to the curve
BSpline.prototype.addNode = function(x,y)
{
	this.nodes.push(new Node(x,y));
}
