package ;

import flash.display3D.*;
import flash.geom.Rectangle;

class UnwrapGfx extends format.gfx.Gfx {
  var sequence:Array<{
  color:Int,
      stuff:Array<Float>,
      pivots:Dynamic,
      beziers:Dynamic,
      bounds:{vb:VertexBuffer3D, ib:IndexBuffer3D}
                     }>;

  var color:Int;
  var pivots:Array<Float>;
  var beziers:Array<Float>;
  var bounds:Rectangle;

  var justMoved:Bool = false;
  var _x = 0.0;
  var _y = 0.0;
  
  var c:Context3D;
  
  public function new(c:Context3D) {
    sequence = [];
    pivots = [];
    beziers = [];
    bounds = new Rectangle(500, 500, -500, -500);
    this.c = c;
    super();
  }

  /*
    override public function beginGradientFill(grad) {
    throw "NYI";
    }
  */

  override public function beginGradientFill(grad) {
    emit();
    this.color = 0x00FF00;
  }

  override public function beginFill(color, alpha) {
    emit();
    this.color = color;
  }

  override public function endFill() {
    emit();
  }

  override public function lineStyle(style) {
    emit();
  }

  override public function endLineStyle() {
    emit();
  }

  override public function moveTo(x, y) {
    justMoved = true;
    set_prev(x,y);
  }
   
  override public function lineTo(x, y) {
    if (justMoved) {
      justMoved = false;
      pivots = pivots.concat([_x, _y, 0, 0]);
      bound(_x, _y);
    }
    pivots = pivots.concat([x , y , 0, 0]);
    bound(x,y);
    set_prev(x,y);
  }

  override public function curveTo(cx, cy, x, y) {
    if (justMoved) {
      justMoved = false;
      pivots = pivots.concat([_x, _y, 0, 0]);
    }
    pivots = pivots.concat([x, y, 0, 0]);
    beziers = beziers.concat([_x, _y, 0 , 0
                             , cx, cy, .5, 0
                             , x ,  y, 1 , 1]);
    bound(_x,_y);
    bound(x,y);
    bound(cx,cy);

    set_prev(x,y);
  }

  function emit() {
    sequence.push({pivots:fan(pivots), beziers:mk(beziers), color:color, stuff:pivots, bounds:mkBound(bounds)});
    pivots = [];
    beziers = [];
    bounds = new Rectangle();
  }

  function set_prev(x, y) {
    _x = x;
    _y = y;
  }

  function bound(x, y) {
    if (x < bounds.x) bounds.x = x;
    if (x > bounds.width) bounds.width = x;
    if (y < bounds.y) bounds.y = y;
    if (y > bounds.height) bounds.height = y;
  }

  function mk(a:Array<Float>) {
    var verts = a.length >>> 2;
    var v = new flash.Vector<Float>();
    for (x in a) v.push(x);

    var i = new flash.Vector<UInt>();
    for (x in 0...verts) i.push(x);

    return if (verts == 0) null;
    else {
      var vb = null;
      var vb = c.createVertexBuffer(verts, 4);
      vb.uploadFromVector(v, 0, verts);
      var ib = c.createIndexBuffer(verts);
      ib.uploadFromVector(i, 0, verts);
      {vb:vb, ib:ib};
    }
  }

  function fan(a:Array<Float>) {
    var verts = a.length >>> 2;
    var v = new flash.Vector<Float>();
    for (x in a) v.push(x);

    var i = new flash.Vector<UInt>();
    var p = 0;
    var l = verts;
    while (p < l-2) {
      i.push(0);
      i.push(p+1);
      i.push(p+2);
      p ++;
    }

    return if (verts == 0 || i.length == 0) null;
    else {
      var vb = c.createVertexBuffer(verts, 4);
      vb.uploadFromVector(v, 0, verts);
      var ib = c.createIndexBuffer(i.length);
      ib.uploadFromVector(i, 0, i.length);
      {vb:vb, ib:ib};     
    }
  }

  function mkBound(r:Rectangle) {
    var vb = c.createVertexBuffer(4, 2);
    var ib = c.createIndexBuffer(6);

    var v = new flash.Vector<Float>();
    for (f in [ r.x, r.y
              , r.width, r.y
              , r.width, r.height
              , r.x, r.height
              ]) v.push(f);

    var i = new flash.Vector<UInt>();
    for (f in [ 0, 1, 2
              , 0, 2, 3
              ]) i.push(f);

    vb.uploadFromVector(v, 0, 4);
    ib.uploadFromVector(i, 0, 6);

    return {vb:vb, ib:ib};
  }
  
  public function render(c:Context3D) {
    if (pivots.length + beziers.length > 0) {
      emit();
    }
    
    
    var sshader = S3D.sshader;

    var m = new flash.geom.Matrix3D();
    m.appendScale(1/300, -1/300, 1);
    m.appendTranslation(-1.0, 1.0, 0);

    for (seq in sequence) {
      /*
      c.clear(0, 0, 0, 0, 0, 0, Context3DClearMask.STENCIL);
      /*/
      c.setStencilReferenceValue(0, 0);
      c.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
                         Context3DCompareMode.ALWAYS,
                         Context3DStencilAction.SET,
                         Context3DStencilAction.SET,
                         Context3DStencilAction.SET);
      sshader.nowrite(seq.bounds.vb, seq.bounds.ib, m);

      //*/

      c.setStencilReferenceValue(1, 1);
      c.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,    
                          Context3DCompareMode.ALWAYS,               //compare mode
                          Context3DStencilAction.INVERT,          //Both pass
                          Context3DStencilAction.INVERT,               //Depth fail
                          Context3DStencilAction.INVERT);              //Stencil fail

      if (seq.pivots != null) {
        sshader.nowrite(seq.pivots.vb, seq.pivots.ib, m);
      }

      if (seq.beziers != null) {
        sshader.onowrite(seq.beziers.vb, seq.beziers.ib, m);
      }
    
      c.setStencilReferenceValue(0, 1);
      c.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
                          Context3DCompareMode.NOT_EQUAL,
                          Context3DStencilAction.KEEP,
                          Context3DStencilAction.KEEP,
                          Context3DStencilAction.KEEP);

      function col(c) {
        return [((c >>> 16) & 0xFF)/256, ((c >>> 8) & 0xFF)/256, ((c >>> 0) & 0xFF)/256, 1.0];
      }

      if (seq.pivots != null) {
        sshader.dshader(seq.bounds.vb, seq.bounds.ib, col(seq.color), m);
      }
    }
  }

  function toString() {
    return 'Beziers: $beziers ** Pivots: $pivots';
  }
}