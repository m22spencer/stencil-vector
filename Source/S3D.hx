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
    trace("joined");

    var data = new format.svg.SVGData (Xml.parse (svg), true);
    trace("parsed");

    var lionSV  = new format.svg.SVGRenderer(data).iterate(new UnwrapGfx(new vector.OVector())).get();
    trace("converted");

    lionSV.freeze(c);
    trace("frozen");

    var tf = new flash.text.TextField();
    flash.Lib.current.addChild(tf);

    var s = flash.Lib.current;
    var w = s.stage.stageWidth;
    var h = s.stage.stageHeight;
    var hw = w *.5;
    var hh = h *.5;
    c.setRenderCallback(function(_)

                        {
                          var m = new Matrix3D();
                          m.appendScale(1/600, 1/600, 1.0);
                          m.appendTranslation(-.5, -.5, 0);
                          //m.appendRotation(180, new Vector3D(1, 0, 0, 0));
                          //m.appendRotation(-(s.mouseX - hw), new Vector3D(0, 1, 0, 0));
                          //m.appendRotation(-(s.mouseY - hh), new Vector3D(1, 0, 0, 0));
                          //m.appendTranslation(0, 0, 5);

                          c.clear(1,0,0,1);

                          var time = haxe.Timer.stamp();
                          //for (i in 0...3) {
                          lionSV.render(c, m);
                          //  m.appendTranslation(-.2, -.2, 0);
                          //}

                          var now = haxe.Timer.stamp ();
                          tf.text = "" + (now - time);

                          c.present();
                        });
  }
}