package ;

import flash.display.*;
import flash.display3D.*;
import flash.geom.Point;
import haxe.ds.Option;

import Shaders;

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