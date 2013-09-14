package ;

import flash.display.*;
import flash.display3D.*;
import flash.geom.*;
import haxe.ds.Option;

import Shaders;
using sample.Shapes;

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

    var svg = Tiger.getTiger().join('\n');

    var data = new format.svg.SVGData (Xml.parse (svg), true);
    /*
    var gfx  = new format.svg.SVGRenderer(data).iterate(new UnwrapGfx(c));
    */

    var sv = new StencilVector();

    sv.beginFill(0x00ff00, .5);
    sv.twinSquares();
    sv.square(.5);
    sv.arc();
    sv.endFill();

    var ctx:Dynamic = untyped sv.shapes[0].buildVectors();

    var hwctx = StencilVector.SVUtils.makeHWVectorDef(c, ctx);

    var m = new Matrix3D();
    m.appendScale(.5, .5, 1.0);

    var s = flash.Lib.current;
    c.setRenderCallback(function(_)

                        {
                          c.clear(1,1,1,1);
                          StencilVector.SVUtils.renderHWVectorDef(c, hwctx, m);
                          c.present();
                        });
  }
}