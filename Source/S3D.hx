package ;

import flash.display.*;
import flash.display3D.*;
import flash.geom.Point;
import haxe.ds.Option;

using OpenFLStage3D;
#if !flash
using flash.display3D.shaders.ShaderUtils;
#end

class S3D {
  static var s:Stage3D;
  static var c:Context3D;
  public static var sshader:SShader;
  public static function main() {


    
    s = flash.Lib.current.stage.getStage3D(0);
    s.addEventListener(flash.events.Event.CONTEXT3D_CREATE, onReady);
    s.addEventListener(flash.events.ErrorEvent.ERROR, function(e)
                       {
                         throw 'Error initializing s3d $e';
                       });
    s.requestContext3D();
  }

  public static function onReady(e) {
    c = s.context3D;
    c.enableErrorChecking = true;
    var stage = flash.Lib.current.stage;
    c.configureBackBuffer (stage.stageWidth, stage.stageHeight, 0, true);
    c.setDepthTest(false, Context3DCompareMode.ALWAYS);
    c.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA,
                      Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);



    sshader = new SShader(c);

    var vb = c.createVertexBuffer(3,2);
    var vb3 = c.createVertexBuffer(3,4);
    var ib = c.createIndexBuffer(3);

    function v<T>(a:Array<T>):flash.Vector<T> {
      var out = new flash.Vector<T>(a.length);
      for (i in 0...a.length) out[i] = a[i];
      return out;
    }

    var v = new flash.Vector<Float>();
    for (x in [ 0, 0
              , 1, 0
              , 0, 1
              ]) v.push(x);
    
    vb.uploadFromVector (v,0,3);

    var v = new flash.Vector<Float>();
    for (x in [-0.5, -0.5,  0, 0
              , 0  , -0.5, .5, 0
              , 0.5,  0.5,  1, 1
              ]) v.push(x);

    vb3.uploadFromVector(v, 0, 3);
    

    var i = new flash.Vector<UInt>();
    for (x in [0,1,2]) i.push(x);
    ib.uploadFromVector (i,0,3);

    var svg = Tiger.getTiger().join('\n');

    var data = new format.svg.SVGData (Xml.parse (svg), true);
    var gfx  = new format.svg.SVGRenderer(data).iterate(new UnwrapGfx(c));
    
    var which = false;
    flash.Lib.current.stage.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function(_)
                                             {
                                               which = !which;
                                               flash.Lib.current.graphics.clear();
                                               c.clear(1,1,1,1);
                                               c.present();
                                             });

    var last = haxe.Timer.stamp();
    var frames = 0;

    new haxe.Timer(1000).run = function()
      {
        var now = haxe.Timer.stamp();
       trace("FPS: " + (frames/(now-last)));
       frames = 0;
       last = now;
      }

    var fsvg = new format.SVG(svg);

    var s = flash.Lib.current;
    c.setRenderCallback(function(_)
                        {
                          frames++;
                          if (which) {
                            s.graphics.clear();
                            fsvg
                              .render(s.graphics);
                          } else {
                            c.clear(1,1,1,1);
                            gfx.render(c);
                            c.present();
                          }
                        });
  }
}


class UnwrapGfx extends format.gfx.Gfx {
  var sequence:Array<{
  color:Int,
      stuff:Array<Float>,
      pivots:Dynamic,
      beziers:Dynamic}>;

  var color:Int;
  var pivots:Array<Float>;
  var beziers:Array<Float>;

  var justMoved:Bool = false;
  var _x = 0.0;
  var _y = 0.0;
  
  var c:Context3D;
  
  public function new(c:Context3D) {
    sequence = [];
    pivots = [];
    beziers = [];
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
    }
    pivots = pivots.concat([x , y , 0, 0]);
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
    set_prev(x,y);
  }

  function emit() {
    sequence.push({pivots:fan(pivots), beziers:mk(beziers), color:color, stuff:pivots});
    pivots = [];
    beziers = [];
  }

  function set_prev(x, y) {
    _x = x;
    _y = y;
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
  
  public function render(c:Context3D) {
    if (pivots.length + beziers.length > 0) {
      emit();
    }
    
    
    var sshader = S3D.sshader;

    for (seq in sequence) {
      c.clear(0, 0, 0, 0, 0, 0, Context3DClearMask.STENCIL);

      c.setStencilReferenceValue(1, 1);
      c.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,    
                          Context3DCompareMode.ALWAYS,               //compare mode
                          Context3DStencilAction.INVERT,          //Both pass
                          Context3DStencilAction.INVERT,               //Depth fail
                          Context3DStencilAction.INVERT);              //Stencil fail
      if (seq.pivots != null) {
        sshader.nowrite(seq.pivots.vb, seq.pivots.ib);
      }

      if (seq.beziers != null) {
        sshader.onowrite(seq.beziers.vb, seq.beziers.ib);
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
        sshader.dshader(seq.pivots.vb, seq.pivots.ib, col(seq.color));
      }
      
      if (seq.beziers != null) {
        sshader.oshader(seq.beziers.vb, seq.beziers.ib, col(seq.color));
      }
    }
  }

  function toString() {
    return 'Beziers: $beziers ** Pivots: $pivots';
  }
}

#if flash
class OShader extends hxsl.Shader {
  static var SRC = {
    var input : { pos:Float2, uv:Float2};
                    function vertex() {
                      var p = input.pos;
                      uv = input.uv;
                      //Seems I was too lazy to hook up a transform matrix. Sorry :/
                      out = [p.x/400-.9, p.y*-1/300+1.0, .5, 1.0];
                    }
                    var uv:Float2;
                    function fragment(color:Float4) {
                      var f = uv.x*uv.x - uv.y;
                      //var inside = lt(f, 0);
                      //var aa = inside*sat(abs(f*.2)); //Some very very bad inner edge AA
                      kill(f*-1);
                      out = color;
                    }
                   }
}

class DShader extends hxsl.Shader {
  static var SRC = {
    var input : { pos:Float2, uv:Float2};
                    function vertex() {
                      var p = input.pos;
                      out = [p.x/400-.9, p.y*-1/300+1.0, .5, 1.0];
                    }
                    function fragment(color:Float4) {
                      out = color;
                    }
                   }
}

class ONOWrite extends hxsl.Shader {
  static var SRC = {
    var input : { pos:Float2, uv:Float2};
                    function vertex() {
                      var p = input.pos;
                      uv = input.uv;
                      out = [p.x/400-.9, p.y*-1/300+1.0, .5, 1.0];
                    }
                    var uv:Float2;
                    function fragment() {
                      var f = uv.x*uv.x - uv.y;
                      kill(f*-1);
                      out = [0,0,0,0];
                    }
                   }
} 

class NOWrite extends hxsl.Shader {
  static var SRC = {
    var input : { pos:Float2, uv:Float2 };
                    function vertex() {
                      var p = input.pos;
                      out = [p.x/400-.9, p.y*-1/300+1.0, .5, 1.0];
                    }
                    function fragment() {
                      out = [0, 0, 0, 0];
                    }
                   }
}
#end

typedef SS =
#if flash
  hxsl.Shader;
#else
flash.display3D.Program3D;
#end

class SShader {
  var c:Context3D;
  var oshad:SS;
  var dshad:SS;
  var nowri:SS;
  var onowri:SS;
  
  public function new(c:Context3D) {
    this.c = c;
#if flash
    oshad = new OShader();
    dshad = new DShader();
    nowri = new NOWrite();
    onowri = new ONOWrite();
#else
    oshad = c.createProgram();
    oshad.upload(Context3DProgramType.VERTEX.createShader(GLSLShaders.shaderv),
                 Context3DProgramType.FRAGMENT.createShader(GLSLShaders.oshaderf));
    dshad = c.createProgram();
    dshad.upload(Context3DProgramType.VERTEX.createShader(GLSLShaders.shaderv),
                 Context3DProgramType.FRAGMENT.createShader(GLSLShaders.dshaderf));

    nowri = c.createProgram();
    nowri.upload(Context3DProgramType.VERTEX.createShader(GLSLShaders.shaderv),
                 Context3DProgramType.FRAGMENT.createShader(GLSLShaders.nowritef));

    onowri = c.createProgram();
    onowri.upload(Context3DProgramType.VERTEX.createShader(GLSLShaders.shaderv),
                  Context3DProgramType.FRAGMENT.createShader(GLSLShaders.onowritef));
#end
  }

  public function oshader(vb:VertexBuffer3D, ib:IndexBuffer3D, color:Array<Float>) {
#if flash
    cast(oshad,OShader).color = new flash.geom.Vector3D(color[0], color[1], color[2], color[3]);
    oshad.bind(c,vb);
    c.drawTriangles(ib);
    oshad.unbind(c);
#else
    c.setProgram(oshad);
    c.setGLSLProgramConstantsFromVector4("color", color);
    c.setGLSLVertexBufferAt("pos", vb, 0, FLOAT_2);
    c.setGLSLVertexBufferAt("uv" , vb, 2, FLOAT_2);
    c.drawTriangles(ib);
#end
  }

  public function dshader(vb:VertexBuffer3D, ib:IndexBuffer3D, color:Array<Float>) {
#if flash
    cast(dshad,DShader).color = new flash.geom.Vector3D(color[0], color[1], color[2], color[3]);
    dshad.bind(c,vb);
    c.drawTriangles(ib);
    dshad.unbind(c);
#else
    c.setProgram(dshad);
    c.setGLSLProgramConstantsFromVector4("color", color);
    c.setGLSLVertexBufferAt("pos", vb, 0, FLOAT_2);
    c.setGLSLVertexBufferAt("uv" , vb, 2, FLOAT_2);
    c.drawTriangles(ib);
#end
  }
  public function nowrite(vb:VertexBuffer3D, ib:IndexBuffer3D) {
#if flash
    nowri.bind(c,vb);
    c.drawTriangles(ib);
    nowri.unbind(c);
#else
    c.setProgram(nowri);
    c.setGLSLVertexBufferAt("pos", vb, 0, FLOAT_2);
    c.setGLSLVertexBufferAt("uv" , vb, 2, FLOAT_2);
    c.drawTriangles(ib);
#end
  }
  public function onowrite(vb:VertexBuffer3D, ib:IndexBuffer3D) {
#if flash
    onowri.bind(c,vb);
    c.drawTriangles(ib);
    onowri.unbind(c);
#else
    c.setProgram(onowri);
    c.setGLSLVertexBufferAt("pos", vb, 0, FLOAT_2);
    c.setGLSLVertexBufferAt("uv" , vb, 2, FLOAT_2);
    c.drawTriangles(ib);
#end
  }
}

class GLSLShaders {
  public static var shaderv = "
attribute vec2 pos;
attribute vec2 uv;
varying vec2 vuv;
void main(void) {
vuv = uv;
gl_Position = vec4(pos.x/400.0-.9, pos.y*-1/300.0+1.0, .5, 1.0);
}
";

  public static var oshaderf = "
varying vec2 vuv;
uniform vec4 color;
void main(void) {
float f = vuv.x*vuv.x - vuv.y;
if (f < 0)
discard;
else
gl_FragColor = color;
}";

  public static var dshaderf = "
uniform vec4 color;
void main(void) {
gl_FragColor = color;
}";

  public static var onowritef = "
varying vec2 vuv;
void main(void) {
float f = vuv.x*vuv.x - vuv.y;
if (f > 0)
discard;
else
gl_FragColor = vec4(0);
}";

  public static var nowritef = "
void main(void) {
gl_FragColor = vec4(0);
}
";
}