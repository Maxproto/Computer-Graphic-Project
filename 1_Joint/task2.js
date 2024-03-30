var WireframeMesh_Two = function(vertexPositions, indices)
{
    this.positions = vertexPositions;
    this.indices = indices;
}

WireframeMesh_Two.prototype.vertex = function(index)
{
    return [this.positions[3*index], this.positions[3*index+1], this.positions[3*index+2], 1];
}

WireframeMesh_Two.prototype.render = function(canvas, model, view, projection)
{
    var context = canvas.getContext('2d');
    
    // TODO: To complete this task fully you must first implement several methods in matrix.js
    
    // TODO: Assemble the full perspective transformation chain consisting of the
    //       model-view-projection matrix and a viewport matrix.
    //
    //       Multiplying a point by the model-view-projection matrix
    //       should be equivalent to multiplying it by the model matrix,
    //       then the inverse view matrix, then the projection matrix
    //
    //       The viewport matrix rescales and centers the points properly in the canvas viewport.
    //
    //       The full perspective transformation chain consists of the model-view-projection matrix
    //       premultiplied by the viewport matrix.
    //
    // Hint: You can use matrix.inverse() to get the inverse of a matrix
    //

// ################ Edit your code below
    var inverseView = view.inverse();
    var modelView = SimpleMatrix.multiply(inverseView, model);
    var modelViewProjectionMatrix = SimpleMatrix.multiply(projection, modelView);
    var viewportMatrix = SimpleMatrix.viewport(canvas.width, canvas.height);
    var fullTransformChain = SimpleMatrix.multiply(viewportMatrix, modelViewProjectionMatrix);

// ################

    context.beginPath();
    for (var i = 0; i < this.indices.length; i+=2)
    {
        var index1 = this.indices[i];
        var index2 = this.indices[i+1];

        var xyz1 = this.vertex(index1);
        var xyz2 = this.vertex(index2);

        // TODO: Modify your render implementation from before to perform the full perspective
        //       transformation chain: apply the full transform chain to every vertex.
        
        xyz1 = SimpleMatrix.multiplyVector(fullTransformChain, xyz1);
        xyz2 = SimpleMatrix.multiplyVector(fullTransformChain, xyz2);

// ################ Edit your code below
        var uv1 = [xyz1[0]/xyz1[3], xyz1[1]/xyz1[3]];
        var uv2 = [xyz2[0]/xyz2[3], xyz2[1]/xyz2[3]];

// ################
        // draw the line segment
        context.moveTo(uv1[0], uv1[1]);
        context.lineTo(uv2[0], uv2[1]);
    }
    context.stroke();
}

var Task2 = function(canvas)
{
    this.mesh1 = new WireframeMesh_Two(WireCubePositions, WireCubeIndices);
    this.mesh2 = new WireframeMesh_Two(WireCubePositions, WireCubeIndices);
    this.mesh3 = new WireframeMesh_Two(SpherePositions, SphereIndices);
    this.cameraAngle = 0;
}

function clear(context, w, h)
{
    context.fillStyle = "white";
    context.fillRect(0, 0, w, h);
}

Task2.prototype.render = function(canvas, gl, w, h)
{
    var time = Date.now()/1000;
    var cosTime = Math.cos(time);
    var sinTime = Math.sin(time);

    var context = canvas.getContext('2d');
    clear(context, w, h);
    
    var projection = SimpleMatrix.perspective(45, w/h, 0.1, 100);
    
    var view = SimpleMatrix.rotate(this.cameraAngle, 1, 0, 0).multiply(
        SimpleMatrix.translate(0, 0, 8));
        
    var modelMatrix1 = SimpleMatrix.scale(Math.abs(cosTime), Math.abs(cosTime), 1);
    var modelMatrix2 = SimpleMatrix.translate(-3, 0, 0).multiply(SimpleMatrix.translate(sinTime, cosTime, 0));
    var modelMatrix3 = SimpleMatrix.translate(3, 0, 0).multiply(SimpleMatrix.rotate(time*30, 1, 1, 1));

    this.mesh1.render(canvas, modelMatrix1, view, projection);
    this.mesh2.render(canvas, modelMatrix2, view, projection);
    this.mesh3.render(canvas, modelMatrix3, view, projection);
}

Task2.prototype.dragCamera = function(dy)
{
    this.cameraAngle = Math.min(Math.max(this.cameraAngle - dy*0.5, -90), 90);
}
