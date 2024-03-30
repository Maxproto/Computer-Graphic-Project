// Crude SVG -> spline converter
// Here be dragons
function generateLetterCurves()
{
    var svg = [
        'm', 160,322,
        'c', -1.20, 1.68, -3.32, 2.88, -6.00, 2.88,
             -4.72, 0.00, -8.04,-3.52, -8.04,-8.68,
              0.00,-5.00,  3.40,-8.68,  8.16,-8.68,
              2.16, 0.00,  4.44, 0.84,  5.72, 2.60,
        'l',  4.64,-4.64,
        'c', -2.36,-2.72, - 6.64,- 4.16, -10.60,- 4.16,
             -8.64, 0.00, -15.36,  5.80, -15.36, 14.88,
              0.00, 8.88,   6.52, 14.96,  15.24, 14.96,
              4.76, 0.00,   8.52,- 1.80,  11.00,- 4.68,
        'z', 0.00,
        
        'm', 188-160,305-322,
        'c', -2.48,-2.28, -6.08,-3.48, -9.28,-3.48,
        -5.28,0, -10.96,2.6, -10.96,8.88,
        0.00,5.12, 3.64,6.96, 7.24,8.12,
        3.72,1.2, 5.88,1.88, 5.88,4.04,
        0.00,2.28, -1.84,3.08, -3.92,3.08,
        -2.24,0, -4.76,-1.28, -6.12,-3,
        'l', -4.48, 4.56,
        'c',  2.48, 2.60,   6.56, 4.08,  10.60, 4.08,
              5.60, 0.00,  10.84,-2.92,  10.84,-9.44,
              0.00,-5.64, - 4.96,-7.28, - 8.80,-8.52,
             -2.68,-0.84, - 4.36,-1.44, - 4.36,-3.32,
              0.00,-2.24,   2.20,-2.84,   3.96,-2.84,
              1.76, 0.00,   3.88, 0.96,   5.04, 2.44,
        'z', 0.00,
        'm', 207-185,303-300, 'l', 0.00,-5.36, 'l', -20.56,0, 'l', 0.00,5.76, 'l', 13.4,0, 'l', -11.48,22.56, 'l', 7.8,0, 'z', 0.00,
        'm', 236-213,303-303, 'l', 0.00,-5.36, 'l', -20.56,0, 'l', 0.00,5.76, 'l', 13.4,0, 'l', -11.48,22.56, 'l', 7.8,0, 'z', 0.00,
    ];
    
    var cId = 'letters';
    var canvas = document.getElementById('letters');
    var ctx = canvas.getContext('2d');
    
    var segments = [];
    var command = 'm';
    var zx = 0.00, zy = 0;
    var x = -135, y = -287;
    var s = 8;
    for (var i = 0; i < svg.length;) {
        function readRelative() {
            x += svg[i++];
            y += svg[i++];
        }
        if (typeof svg[i] === 'string' || svg[i] instanceof String) {
            command = svg[i++];
            continue;
        } else {
            switch(command) {
            case 'm':
                readRelative();
                zx = x;
                zy = y;
                break;
            case 'l':
                var x0 = x;
                var y0 = y;
                readRelative();
                var x1 = x;
                var y1 = y;
                
                var curve = new BezierCurve(cId, ctx);
                curve.nodes.push(new Node(x0*s, y0*s));
                curve.nodes.push(new Node(x0*s, y0*s));
                curve.nodes.push(new Node(x1*s, y1*s));
                curve.nodes.push(new Node(x1*s, y1*s));
                segments.push(curve);
                break;
            case 'c':
                var x0 = x, y0 = y;
                var x1 = x + svg[i++]; var y1 = y + svg[i++];
                var x2 = x + svg[i++]; var y2 = y + svg[i++];
                var x3 = x + svg[i++]; var y3 = y + svg[i++];
                x = x3;
                y = y3;
                
                var curve = new BezierCurve(cId, ctx);
                curve.nodes.push(new Node(x0*s, y0*s));
                curve.nodes.push(new Node(x1*s, y1*s));
                curve.nodes.push(new Node(x2*s, y2*s));
                curve.nodes.push(new Node(x3*s, y3*s));
                segments.push(curve);
            
                break;
            case 'z':
                var curve = new BezierCurve(cId, ctx);
                curve.nodes.push(new Node(x *s, y *s));
                curve.nodes.push(new Node(x *s, y *s));
                curve.nodes.push(new Node(zx*s, zy*s));
                curve.nodes.push(new Node(zx*s, zy*s));
                segments.push(curve);
                x = zx;
                y = zy;
                i++;
                break;
            }
        }
    }
    
    return segments;
}