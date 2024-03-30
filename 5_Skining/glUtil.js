function setupTask(canvasId, taskFunction) {
    var canvas = document.getElementById(canvasId);
    if (!canvas) {
        console.log("Could not find canvas with id", canvasId);
        return;
    }

    try {
        var gl = canvas.getContext("webgl") || canvas.getContext("experimental-webgl");
    } catch (e) { }
    if (!gl) {
        console.log("Could not initialise WebGL");
        return;
    }

    var renderWidth, renderHeight;
    function computeCanvasSize() {
        renderWidth = Math.min(canvas.parentNode.clientWidth - 20, 820);
        renderHeight = Math.floor(renderWidth * 9.0 / 16.0);

        canvas.style.width = `${renderWidth}px`;
        canvas.style.height = `${renderHeight}px`;

        const ratio = window.devicePixelRatio || 1;

        renderWidth = Math.floor(renderWidth * ratio);
        renderHeight = Math.floor(renderHeight * ratio);

        canvas.width = renderWidth;
        canvas.height = renderHeight;
        gl.viewport(0, 0, renderWidth, renderHeight);
    }

    window.addEventListener('resize', computeCanvasSize);
    computeCanvasSize();

    var task = new taskFunction(gl);

    var mouseDown = false;
    canvas.addEventListener('mousedown', function (event) {
        if (event.button == 0)
            mouseDown = true;
        event.preventDefault();
    });
    canvas.addEventListener('mousemove', function (event) {
        if (mouseDown && event.button == 0)
            task.drag(event);
        event.preventDefault();
    });
    document.addEventListener('mouseup', function (event) {
        if (mouseDown && event.button == 0) {
            mouseDown = false;
        }
    });
    canvas.addEventListener('wheel', function (e) {
        task.wheel(e);
        e.preventDefault();
    });

    var uiContainer = div();
    var weightSelector = ["Hide Weights"];
    for (var i = 0; i < task.skeleton.getNumJoints(); ++i) {
        var jointId = i;
        var jointName = task.skeleton.getJointName(i);

        var sliderTarget = div();
        uiContainer.appendChild(div('slider-container', sliderTarget));

        new Slider(sliderTarget, 0, 120, 0, true, function (jointId, jointName, angle) {
            this.setLabel(jointName + ': ' + angle + ' deg');
            task.setJointAngle(jointId, angle);
        }, [jointId, jointName]);
        weightSelector.push(jointName + ' Weights');
    }
    var groupTarget = div();
    uiContainer.appendChild(div('button-group-container', groupTarget));
    new ButtonGroup(groupTarget, weightSelector, function (idx) {
        task.showJointWeights(idx - 1);
    });
    canvas.parentNode.appendChild(uiContainer);

    var renderLoop = function () {
        task.render(gl, renderWidth, renderHeight);
        window.requestAnimationFrame(renderLoop);
    };
    window.requestAnimationFrame(renderLoop);

    return task;
}


function createVertexBuffer(gl, vertexData) {
    var vbo = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertexData), gl.STATIC_DRAW);
    return vbo;
}

function createIndexBuffer(gl, indexData) {
    var ibo = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ibo);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(indexData), gl.STATIC_DRAW);
    return ibo;
}

function createColorBuffer(gl, colorData) {
    var cbo = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, cbo);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(colorData), gl.STATIC_DRAW);
    return cbo;
}

function createShaderObject(gl, shaderSource, shaderType) {
    var shaderObject = gl.createShader(shaderType);
    gl.shaderSource(shaderObject, shaderSource);
    gl.compileShader(shaderObject);

    if (!gl.getShaderParameter(shaderObject, gl.COMPILE_STATUS)) {
        var lines = shaderSource.split("\n");
        for (var i = 0; i < lines.length; ++i)
            lines[i] = ("   " + (i + 1)).slice(-4) + " | " + lines[i];
        shaderSource = lines.join("\n");

        throw new Error(
            (shaderType == gl.FRAGMENT_SHADER ? "Fragment" : "Vertex") + " shader compilation error for shader '" + name + "':\n\n    " +
            gl.getShaderInfoLog(shaderObject).split("\n").join("\n    ") +
            "\nThe shader source code was:\n\n" +
            shaderSource);
    }
    return shaderObject;
}

function createShaderProgram(gl, vertexSource, fragmentSource) {
    var vertexShader = createShaderObject(gl, vertexSource, gl.VERTEX_SHADER);
    var fragmentShader = createShaderObject(gl, fragmentSource, gl.FRAGMENT_SHADER);
    var program = gl.createProgram();
    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);
    return program;
}
