

var ShadedTriangleMesh = function(gl, vertexPositions, vertexNormals, indices, vertexSource, fragmentSource) {
    this.indexCount = indices.length;
    this.positionVbo = createVertexBuffer(gl, vertexPositions);
    this.normalVbo = createVertexBuffer(gl, vertexNormals);
    this.indexIbo = createIndexBuffer(gl, indices);
    this.shaderProgram = createShaderProgram(gl, vertexSource, fragmentSource);
}

ShadedTriangleMesh.prototype.render = function(gl, model, view, projection) {
    
    gl.useProgram(this.shaderProgram);
    
    // Assemble a model-view-projection matrix from the specified matrices.
    var modelViewProjection = projection.multiply(view).multiply(model);

    // Pass the matrix to a shader uniform
    // IMPORTANT: OpenGL has different matrix conventions than our JS program. We need to transpose the matrix before passing it
    // to OpenGL to get the correct matrix in the shader.
    gl.uniformMatrix4fv(gl.getUniformLocation(this.shaderProgram, "ModelViewProjection"), false, modelViewProjection.transpose().m); 
    
    // TODO: Currently the code only passes the model-view-projection matrix. You may need access to additional
    //       matrices or vectors in your shaders to solve the remaining tasks. Use the existing code as a template and pass however
    //       many additional uniforms you need.

// ################ Edit your code below
    var normalMatrix = model.transpose().inverse();
    
    var modelMatrixLocation = gl.getUniformLocation(this.shaderProgram, "ModelMatrix");
    gl.uniformMatrix4fv(modelMatrixLocation, false, model.transpose().m);

    var normalMatrixLocation = gl.getUniformLocation(this.shaderProgram, "NormalMatrix");
    gl.uniformMatrix4fv(normalMatrixLocation, false, normalMatrix.transpose().m);

    var viewMatrixLocation = gl.getUniformLocation(this.shaderProgram, "ViewMatrix");
    gl.uniformMatrix4fv(viewMatrixLocation, false, view.inverse().transpose().m);
// ################
    
    // OpenGL setup beyond this point
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.indexIbo);
    
    gl.bindBuffer(gl.ARRAY_BUFFER, this.positionVbo);
    var positionAttrib = gl.getAttribLocation(this.shaderProgram, "Position");
    if (positionAttrib >= 0) {
        gl.enableVertexAttribArray(positionAttrib);
        gl.vertexAttribPointer(positionAttrib, 3, gl.FLOAT, false, 0, 0);
    }
    
    gl.bindBuffer(gl.ARRAY_BUFFER, this.normalVbo);
    var normalAttrib = gl.getAttribLocation(this.shaderProgram, "Normal");
    if (normalAttrib >= 0) {
        gl.enableVertexAttribArray(normalAttrib);
        gl.vertexAttribPointer(normalAttrib, 3, gl.FLOAT, false, 0, 0);
    }
    
    gl.drawElements(gl.TRIANGLES, this.indexCount, gl.UNSIGNED_SHORT, 0);
}