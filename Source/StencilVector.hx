package ;

import flash.geom.*;
import flash.display3D.*;

import flash.Vector;
import Alg.debug_assert;

import Math.*;

class StencilVector {
  var shapes:Array<SVShape>;
  var current:SVShape;
  var justMoved:Bool = false;
  var last_x:Float;
  var last_y:Float;
  public function new() {
    shapes = [];
  }

  public function moveTo(x:Float, y:Float) {
    debug_assert(null != current);
    debug_assert(false == justMoved); //Don't want redundant moves

    justMoved = true;
    current.addPivot(last_x = x, last_y = y);
  }

  public function lineTo(x:Float, y:Float) {
    debug_assert(null != current);

    justMoved = false;
    current.addPivot(last_x = x, last_y = y);
  }

  public function curveTo(x:Float, y:Float, cx:Float, cy:Float) {
    debug_assert(null != current);
    
    justMoved = false;
    current.addBezier(last_x, last_y,
                      cx, cy,
                      last_x = x , last_y = y);
  }

  public function beginFill(color:Int, alpha:Float) {
    debug_assert(null == current);

    justMoved = false;
    shapes.push(current = new SVShape(color, alpha));
    last_x = last_y = 0.0;
  }

  public function endFill() {
    debug_assert(null != current);

    justMoved = false;
    current = null;
  }
}

class SVShape {
  var pivots:Vector<Float>;
  var beziers:Vector<Float>;
  var bounds:Rectangle;
  public function new(color:Int, alpha:Float) {
    pivots = new Vector();
    beziers = new Vector();
    bounds = new Rectangle(POSITIVE_INFINITY, POSITIVE_INFINITY,
                           NEGATIVE_INFINITY, NEGATIVE_INFINITY);
  }

  function bound(x:Float, y:Float) {
    bounds.x = min(x, bounds.x);
    bounds.width = max(x, bounds.width);

    bounds.y = max(y, bounds.y);
    bounds.height = max(y, bounds.height);
  }

  public function addPivot(x:Float, y:Float) {
    pivots.push(x); pivots.push(y);
    bound(x,y);
  }

  public function addBezier(xs:Float, ys:Float, cx:Float, cy:Float, xe:Float, ye:Float) {
    beziers.push(xs); beziers.push(ys); beziers.push(0); beziers.push(0);
    beziers.push(cx); beziers.push(cy); beziers.push(.5); beziers.push(.5);
    beziers.push(xe); beziers.push(ye); beziers.push(1); beziers.push(1);
    bound(xs,ys); bound(cx,cy); bound(xe,ye);
  }

  public function buildVectors() {
    return { pivots:  pivots
           , beziers: beziers
           , numPivots: (pivots.length >>> 1) - 2
           , numBeziers: Std.int((pivots.length >>> 2) / 3)
           , bounds: bounds 
           }
  }
}

class SVUtils {
  static var fan_ib:IndexBuffer3D;
  static var tri_ib:IndexBuffer3D;
  static function init(c:Context3D, pivotMax:Int = 1000, bezierMax:Int = 1000) {
    var num = (pivotMax-2) * 3;
    fan_ib = c.createIndexBuffer(num);
    var fan = new Vector<UInt>();
    for (i in 1...pivotMax-1) {
      fan.push(0); fan.push(i); fan.push(i+1);
    }
    fan_ib.uploadFromVector(fan, 0, num);


    var num = bezierMax*3;
    tri_ib = c.createIndexBuffer(num);
    var tri = new Vector<UInt>();
    for (i in 0...num)
      tri.push(i);
    tri_ib.uploadFromVector(tri, 0, num);
  }
  
  static function mkBound(c:Context3D, r:Rectangle) {
    var vb = c.createVertexBuffer(4, 2);

    var v = new flash.Vector<Float>();
    for (f in [ r.x, r.y
              , r.width, r.y
              , r.width, r.height
              , r.x, r.height
              ]) v.push(f);

    vb.uploadFromVector(v, 0, 4);
    return vb;
  }

  public static function makeHWVectorDef(c:Context3D, def:VectorDef) {
    var pivot_vb = c.createVertexBuffer(def.pivots.length >>> 1, 2);
    pivot_vb.uploadFromVector(def.pivots, 0, def.pivots.length >>> 1);

    var bezier_vb = c.createVertexBuffer(def.beziers.length >>> 2, 4);
    bezier_vb.uploadFromVector(def.beziers, 0, def.beziers.length >>> 2);

    return { pivots: pivot_vb
           , beziers: bezier_vb
           , numPivots: def.numPivots
           , numBeziers: def.numBeziers
           , bounds: mkBound(c, def.bounds)
           }
  }

  public static function renderHWVectorDef(c:Context3D, def:HWVectorDef, m:Matrix3D) {
    function stencil(a:Int, b:Int, compareMode, action) {
      #if flash
      c.setStencilReferenceValue(a,b);
      c.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, compareMode, action, action, action);
      #end
    }
    var sshader = null;
    var tri_ib = null;
    var fan_ib = null;

    stencil(0, 0, Context3DCompareMode.ALWAYS, Context3DStencilAction.SET);
    sshader.nowrite(def.bounds, tri_ib, 2, m);
    
    stencil(1, 1, Context3DCompareMode.ALWAYS, Context3DStencilAction.INVERT);
    sshader.nowrite(def.pivots, fan_ib, def.numPivots, m); 
    sshader.onowrite(def.beziers, tri_ib, def.numBeziers, m);

    
    stencil(0, 1, Context3DCompareMode.NOT_EQUAL, Context3DStencilAction.KEEP);
    sshader.dshader(def.bounds, tri_ib, 2, [ 1, 0, 0, 1], m);
  }
}

typedef HWVectorDef = { pivots:VertexBuffer3D
                      , beziers:VertexBuffer3D
                      , numPivots:Int //Number of triangles 
                      , numBeziers:Int //Number of triangles
                      , bounds:VertexBuffer3D
                      }

typedef VectorDef = { pivots:Vector<Float>
                    , beziers:Vector<Float>
                    , numPivots:Int //Number of triangles
                    , numBeziers:Int //Number of tringles
                    , bounds:Rectangle
                    }