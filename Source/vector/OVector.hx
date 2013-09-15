package vector;

import flash.display3D.*;
import flash.geom.Matrix3D;
import flash.Vector;

class OVector {
  var vertices :Vector<Float>;
  var indices  :Vector<UInt>;
  var last_x   :Float = 0.0;
  var last_y   :Float = 0.0;
  var shapes   :Array<DShape>;
  var current  :DShape;
  var justMoved:Bool = false;
  var lastPivotIndex = 0;
  inline public function new() {
    vertices = new Vector();
    indices  = new Vector();
    shapes = [];
     
    endFill();
  }

  public function toString() {
    return '
vertices: $vertices
indices : $indices
shapes  : $shapes
';
  }

  var v : VertexBuffer3D;
  var i : IndexBuffer3D;

  inline public function freeze(c:Context3D) {
    v = c.createVertexBuffer(vNum(), 4);
    v.uploadFromVector(vertices, 0, vNum());
    i = c.createIndexBuffer(indices.length);
    i.uploadFromVector(indices, 0, indices.length);

  }

  inline public function render(c:Context3D, m:Matrix3D) {
    var sshader = S3D.sshader;
   
    inline function stencil(a:Int, b:Int, compareMode, action) {
      #if flash
      c.setStencilReferenceValue(a,b);
      c.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, compareMode, action, action, action);
      #end
    }

    var blank = [0.0,0.0,0.0,0.0];

    var fn = sshader.bind(v, i, m);

    for (shape in shapes) {
      if (shape.numTriangles == 0)
        continue;

      //*
      c.clear(0, 0, 0, 0, 0, 0, Context3DClearMask.STENCIL);
      /*/
      stencil(0, 0, Context3DCompareMode.ALWAYS, Context3DStencilAction.SET);
      fn(shape.boundIndex, 2, blank);
      //*/

      stencil(1, 1, Context3DCompareMode.ALWAYS, Context3DStencilAction.INVERT);
      fn(shape.startIndex, shape.numTriangles, blank);

      stencil(0, 1, Context3DCompareMode.NOT_EQUAL, Context3DStencilAction.KEEP);
      fn(shape.startIndex, shape.numTriangles, shape.color);
      //fn(shape.boundIndex, 2, shape.color);
    }
  }

  inline public function vNum() return vertices.length >>> 2;

  inline public function pushv(x:Float, y:Float, u:Float, v:Float) {
    vertices.push(x); vertices.push(y); vertices.push(u); vertices.push(v);
  }

  inline public function addPivot(x:Float, y:Float) {
    var currentIndex = vNum();
    if (lastPivotIndex != current.startVertex) { //Only write indices if there are already two pivots. (Make sure first vertex is pivot)
      indices.push(current.startVertex);
      indices.push(lastPivotIndex);
      indices.push(currentIndex);
      current.numTriangles++;
    }
    lastPivotIndex = currentIndex;
    pushv(x, y, 0, 0); //Always pass u*u - v check
  }

  inline public function addBezier(x:Float, y:Float, cx:Float, cy:Float, x2:Float, y2:Float) {
    //Must duplicate pivots due to mistmatched uv
    addPivot(x, y); addPivot(x2, y2); 
    var i = vNum();
    indices.push(i); indices.push(i+1); indices.push(i+2);
    current.numTriangles++;
    pushv( x,  y,  0, 0);
    pushv(cx, cy, .5, 0);
    pushv(x2, y2,  1, 1);
  }

  inline public function moveTo(x:Float, y:Float) {
    last_x = x; last_y = y;
    justMoved = true;
  }

  inline public function lineTo(x:Float, y:Float) {
    if (justMoved) addPivot(last_x, last_y);
    justMoved = false;
    addPivot(last_x = x, last_y = y);
  }

  inline public function curveTo(x:Float, y:Float, cx:Float, cy:Float) {
    if (justMoved) addPivot(last_x, last_y);
    justMoved = false;
    addPivot(x, y);
    addBezier(last_x, last_y,
              cx, cy,
              last_x = x, last_y = y);
  }

  inline public function beginFill(color:Int, alpha:Float) {
    lastPivotIndex = vNum();
    shapes.push(current = new DShape(lastPivotIndex, indices.length, 0, Alg.mkColor(color, alpha)));
  }

  inline public function endFill() {
    shapes.push(current = new DShape(vNum(), indices.length, 0, [.0, .0, .0, .0]));
    justMoved = false;
  }
}

class DShape {
  public var startVertex:Int;
  public var startIndex:Int;
  public var numTriangles:Int;
  public var color:Array<Float>;
  public function new(startVertex, startIndex, numTriangles, color) { //val startVertex ...... hint hint haxe
    this.startVertex = startVertex;
    this.startIndex = startIndex;
    this.numTriangles = numTriangles;
    this.color = color;
  }
}