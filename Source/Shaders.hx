package ;

import flash.display3D.*;

class SShader {
  var c:Context3D;
  var dshad:SS;
  var nowri:SS;
  var onowri:SS;
  
  public function new(c:Context3D) {
    this.c = c;
#if flash
    dshad = new DShader();
    nowri = new NOWrite();
    onowri = new ONOWrite();
#else
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

  inline public function dshader(vb:VertexBuffer3D, ib:IndexBuffer3D, triangles:Int, color:Array<Float>, mvp:flash.geom.Matrix3D) {
#if flash
    cast(dshad,DShader).color = new flash.geom.Vector3D(color[0], color[1], color[2], color[3]);
    cast(dshad,DShader).mvp = mvp;
    dshad.bind(c,vb);
    c.drawTriangles(ib, 0, triangles);
    dshad.unbind(c);
#else
    c.setProgram(dshad);
    c.setGLSLProgramConstantsFromVector4("color", color);
    c.setGLSLVertexBufferAt("pos", vb, 0, FLOAT_2);
    c.drawTriangles(ib, 0, triangles);
#end
  }
  inline public function nowrite(vb:VertexBuffer3D, ib:IndexBuffer3D, triangles:Int, mvp:flash.geom.Matrix3D) {
#if flash
    cast(nowri,NOWrite).mvp = mvp;
    nowri.bind(c,vb);
    c.drawTriangles(ib, 0, triangles);
    nowri.unbind(c);
#else
    c.setProgram(nowri);
    c.setGLSLVertexBufferAt("pos", vb, 0, FLOAT_2);
    c.drawTriangles(ib, 0, triangles);
#end
  }
  inline public function onowrite(vb:VertexBuffer3D, ib:IndexBuffer3D, triangles:Int, color:Array<Float>, mvp:flash.geom.Matrix3D) {
#if flash
    cast(onowri,ONOWrite).mvp = mvp;
    cast(onowri,ONOWrite).color = new flash.geom.Vector3D(color[0], color[1], color[2], color[3]);
    onowri.bind(c,vb);
    c.drawTriangles(ib, 0, triangles);
    onowri.unbind(c);
#else
    c.setProgram(onowri);
    c.setGLSLVertexBufferAt("pos", vb, 0, FLOAT_2);
    c.setGLSLVertexBufferAt("uv" , vb, 2, FLOAT_2);
    c.drawTriangles(ib, 0, triangles);
#end
  }

  inline public function bind(vb:VertexBuffer3D, ib:IndexBuffer3D, mvp:flash.geom.Matrix3D) {
#if flash
    var s = cast (onowri, ONOWrite);
    s.mvp = mvp;

    var cl = new flash.geom.Vector3D(1.0, 0, 0, 1.0);
    s.color = cl;
    s.bind(c,vb);

    return function(startIndex, triangles, color) {
      cl.x = color[0]; cl.y = color[1]; cl.z = color[2]; cl.w = color[3];
      s.color = cl;
      s.bind(c,vb);
      c.drawTriangles(ib, startIndex, triangles);
    }
#else
    throw "Not yet implemented";
#end
  }
}

#if flash
class DShader extends hxsl.Shader {
  static var SRC = {
    var input : { pos:Float2 };
                    function vertex(mvp:Matrix) {
                      out = [input.pos.x, input.pos.y, 0.0, 1.0] * mvp;
                    }
                    function fragment(color:Float4) {
                      out = color;
                    }
                   }
}

class ONOWrite extends hxsl.Shader {
  static var SRC = {
    var input : { pos:Float2, uv:Float2 };
                    function vertex(mvp:Matrix) {
                      uv = input.uv;
                      out = [input.pos.x, input.pos.y, 0.0, 1.0] * mvp;
                    }
                    var uv:Float2;
                    function fragment(color:Float4) {
                      var f = uv.x*uv.x - uv.y;
                      kill(f*-1); //All pixels on the inside of the curve will be less than 0
                      out = color;
                    }
                   }
} 

class NOWrite extends hxsl.Shader {
  static var SRC = {
    var input : { pos:Float2 };
                    function vertex(mvp:Matrix) {
                      out = [input.pos.x, input.pos.y, 0.0, 1.0] * mvp;
                    }
                    function fragment() {
                      out = [0,0,0,0];
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