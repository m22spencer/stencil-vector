package ;

import flash.display3D.*;

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