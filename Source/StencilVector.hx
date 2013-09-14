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
    endFill();
  }

  public function moveTo(x:Float, y:Float) {
    last_x = x; last_y = y;
    justMoved = true;
  }

  public function lineTo(x:Float, y:Float) {
    if (justMoved)
      current.addPivot(last_x, last_y);
    justMoved = false;
    current.addPivot(last_x = x, last_y = y);
  }

  public function curveTo(x:Float, y:Float, cx:Float, cy:Float) {
    if (justMoved)
      current.addPivot(last_x, last_y);
    justMoved = false;
    current.addPivot(x, y);
    current.addBezier(last_x, last_y,
                      cx, cy,
                      last_x = x , last_y = y);
  }

  public function beginFill(color:Int, alpha:Float) {
    shapes.push(current = new SVShape(color, alpha));
    justMoved = true;
  }

  public function endFill() {
    shapes.push(current = new SVShape(0,0));
    justMoved = false;
  }

  /* Returns a function that will render the vector object when called */
  public function build(c:Context3D):Matrix3D->Void {
    var data = shapes
      .filter(function(x) return x.color[3] > 0)
      .map(function(x) return SVUtils.makeHWVectorDef(c, x.buildVectors()));
    return function(m) {
      for (v in data)
        SVUtils.renderHWVectorDef(c, v, m);
    }
  }
}

class SVShape {
  var pivots:Vector<Float>;
  var beziers:Vector<Float>;
  var bounds:Rectangle;
  public var color(default, null):Array<Float>;
  public function new(rgb:Int, alpha:Float) {
    pivots = new Vector();
    beziers = new Vector();
    bounds = new Rectangle(POSITIVE_INFINITY, POSITIVE_INFINITY,
                           NEGATIVE_INFINITY, NEGATIVE_INFINITY);
    color = [ ((rgb>>>16) & 0xFF)/256
            , ((rgb>>>8 ) & 0xFF)/256
            , ((rgb     ) & 0xFF)/256
            , alpha
            ];
  }

  function bound(x:Float, y:Float) {
    bounds.x = min(x, bounds.x);
    bounds.width = max(x, bounds.width);

    bounds.y = min(y, bounds.y);
    bounds.height = max(y, bounds.height);
  }

  /* Anything that's not a control point */
  public function addPivot(x:Float, y:Float) {
    pivots.push(x); pivots.push(y);
    bound(x,y);
  }

  public function addBezier(xs:Float, ys:Float, cx:Float, cy:Float, xe:Float, ye:Float) {
    //x,y,  u,v   //u/v are used to determine the bezier curve fill via frag shader. where (x*x - y) < 0
    beziers.push(xs); beziers.push(ys); beziers.push(0); beziers.push(0);
    beziers.push(cx); beziers.push(cy); beziers.push(.5); beziers.push(0);
    beziers.push(xe); beziers.push(ye); beziers.push(1); beziers.push(1);
    bound(xs,ys); bound(xe,ye);
    bound(cx,cy); 
  }

  public function buildVectors() {
    return { pivots:  pivots
           , beziers: beziers
           , numPivots: pivots.length >>> 1
           , numBeziers: beziers.length >>> 2
           , bounds: bounds 
           , color: color
           }
  }
}

class SVUtils {
  static function indexBuffers(c:Context3D, pivots:Int, beziers:Int) {
    var fan = new Vector<UInt>();
    for (i in 1...pivots-1) {
      fan.push(0); fan.push(i); fan.push(i+1);
    }
    var fan_ib = if (fan.length == 0) null;
    else {
      var fan_ib = c.createIndexBuffer(fan.length);
      fan_ib.uploadFromVector(fan, 0, fan.length);
      fan_ib;
    }


    var tri = new Vector<UInt>();
    for (i in 0...beziers)
      tri.push(i);
    var tri_ib = if (tri.length == 0) null;
    else {
      var tri_ib = c.createIndexBuffer(tri.length);
      tri_ib.uploadFromVector(tri, 0, tri.length);
      tri_ib;
    }

    var bvec = new Vector<UInt>();
    for (i in [0,1,2,0,2,3])
      bvec.push(i);
    var bounds_ib = c.createIndexBuffer(6);
    bounds_ib.uploadFromVector(bvec, 0, 6);

    return { fan_ib: fan_ib
           , tri_ib: tri_ib
           , bounds_ib: bounds_ib
           }
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
    var pivot_vb = if (def.pivots.length == 0) null;
    else {
      var pivot_vb = c.createVertexBuffer(def.pivots.length >>> 1, 2);
      pivot_vb.uploadFromVector(def.pivots, 0, def.pivots.length >>> 1);
      pivot_vb;
    }

    var bezier_vb = if (def.beziers.length >>> 2 == 0) null;
    else {
      var bezier_vb = c.createVertexBuffer(def.beziers.length >>> 2, 4);
      bezier_vb.uploadFromVector(def.beziers, 0, def.beziers.length >>> 2);
      bezier_vb;
    }

    var ibs = indexBuffers(c, def.numPivots, def.numBeziers);

    return { pivots: pivot_vb
           , fan_ib: ibs.fan_ib
           , beziers: bezier_vb
           , tri_ib: ibs.tri_ib
           , numPivots: def.numPivots
           , numBeziers: def.numBeziers
           , bounds: mkBound(c, def.bounds)
           , bounds_ib: ibs.bounds_ib
           , color : def.color
           }
  }

  inline public static function renderHWVectorDef(c:Context3D, def:HWVectorDef, m:Matrix3D) {
    inline function stencil(a:Int, b:Int, compareMode, action) {
#if flash
      c.setStencilReferenceValue(a,b);
      c.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, compareMode, action, action, action);
#end
    }
    var sshader = S3D.sshader;

    //Clear the stencil buffer where we will need to work.
    //c.clear can also be used if more performant
    stencil(0, 0, Context3DCompareMode.ALWAYS, Context3DStencilAction.SET);
    sshader.nowrite(def.bounds, def.bounds_ib, 2, m);
    
    //Draw a triangle fan of all pivot points, all bezier curves, inverting the stencil mask as we go
    stencil(1, 1, Context3DCompareMode.ALWAYS, Context3DStencilAction.INVERT);
    if (def.fan_ib != null) sshader.nowrite(def.pivots, def.fan_ib, -1, m); 
    if (def.tri_ib != null) sshader.onowrite(def.beziers, def.tri_ib, -1, m);

    //The stencil mask is now 1 for valid pixels, and 0 for invalid. Render a quad filtering by stencil value
    stencil(0, 1, Context3DCompareMode.NOT_EQUAL, Context3DStencilAction.KEEP);
    sshader.dshader(def.bounds, def.bounds_ib, 2, def.color, m);
  }
}

//TODO Convert to classes to avoid Dynamic
typedef HWVectorDef = { pivots: VertexBuffer3D
                      , fan_ib: IndexBuffer3D
                      , beziers: VertexBuffer3D
                      , tri_ib: IndexBuffer3D
                      , numPivots: Int //Number of vertices 
                      , numBeziers: Int //Number of vertices
                      , bounds: VertexBuffer3D
                      , bounds_ib: IndexBuffer3D
                      , color:Array<Float>
                      }

typedef VectorDef = { pivots:Vector<Float>
                    , beziers:Vector<Float>
                    , numPivots:Int //Number of vertices
                    , numBeziers:Int //Number of vertices
                    , bounds:Rectangle
                    , color:Array<Float>
                    }