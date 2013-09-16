package vector;

import flash.display3D.*;
import flash.geom.*;

import flash.Vector;
  
class OVector {
  var vertices :Vector<Float>;
  var indices  :Vector<UInt>;
  var last_x   :Float = 0.0;
  var last_y   :Float = 0.0;
  var shapes   :Array<DShape>;
  var current  :DShape;
  var justMoved:Bool = false;
  var bounds   :Rectangle;
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

    shapes = shapes.filter(function(x) return x.numTriangles > 0 && x.color[3] > 0);
  }

  inline public function render(c:Context3D, m:Matrix3D) {
    var sshader = S3D.sshader;
   
    inline function stencil(a:Int, b:Int, compareMode, action) {
      c.setStencilReferenceValue(a,b);
      c.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, compareMode, action, action, action);
    }

    var blank = #if flash new Vector<Float>(4) #else [.0, .0, .0, .0] #end;

    sshader.bind(v, i, m);

    for (shape in shapes) {
      /*
      c.clear(0, 0, 0, 0, 0, 0, Context3DClearMask.STENCIL);
      /*/
      stencil(0, 0, Context3DCompareMode.ALWAYS, Context3DStencilAction.SET);
      sshader.draw(v, i, shape.boundIndex, 2, blank);
      //*/

      stencil(1, 1, Context3DCompareMode.ALWAYS, Context3DStencilAction.INVERT);
      sshader.draw(v, i, shape.startIndex, shape.numTriangles, blank);

      stencil(0, 1, Context3DCompareMode.NOT_EQUAL, Context3DStencilAction.KEEP);
      sshader.draw(v, i, shape.boundIndex, 2, shape.color);
    }
  }

  inline public function vNum() return vertices.length >>> 2;

  inline public function pushv(x:Float, y:Float, u:Float, v:Float) {
    Alg.bound(bounds, x,y);
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
    var i = vNum();
    //The last pivot pushed will have the correct uv data, we can reuse it
    indices.push(lastPivotIndex); indices.push(i); indices.push(i+1);
    current.numTriangles++;
    pushv(cx, cy, .5, 0);
    pushv(x2, y2,  1, 1);
    addPivot(x2, y2);
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
    addBezier(last_x, last_y,
              cx, cy,
              last_x = x, last_y = y);
  }

  inline public function beginFill(color:Int, alpha:Float) {
    lastPivotIndex = vNum();
    var c = Alg.toVec(Alg.mkColor(color, alpha));
    shapes.push(current = new DShape(lastPivotIndex, indices.length, 0, c));
    bounds = new Rectangle(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY,
                           Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);
  }

  inline public function endFill() {
    if (current != null && current.numTriangles > 0) {
      var i = vNum();
      pushv(bounds.x,     bounds.y,      0, 0);
      pushv(bounds.width, bounds.y,      0, 0);
      pushv(bounds.width, bounds.height, 0, 0);
      pushv(bounds.x,     bounds.height, 0, 0);

      current.boundIndex = indices.length;
      indices.push(i); indices.push(i+1); indices.push(i+2);
      indices.push(i); indices.push(i+2); indices.push(i+3);
    }
    
    var c = #if flash new Vector<Float>(4) #else [.0, .0, .0, .0] #end;
    shapes.push(current = new DShape(vNum(), indices.length, 0, c));
    justMoved = false;
  }
}

class DShape {
  public var startVertex:Int;
  public var startIndex:Int;
  public var boundIndex:Int;
  public var numTriangles:Int;
  public var color:Vector<Float>;
  public function new(startVertex, startIndex, numTriangles, color) { //val startVertex ...... hint hint haxe
    this.startVertex = startVertex;
    this.startIndex = startIndex;
    this.numTriangles = numTriangles;
    this.color = color;
  }
}