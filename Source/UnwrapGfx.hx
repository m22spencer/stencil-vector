package ;

import flash.display3D.*;
import flash.geom.Rectangle;

class UnwrapGfx extends format.gfx.Gfx {
  var sv:Dynamic;
  public function new(sv:Dynamic) {
    this.sv = sv;
    super();
  }

  override public function beginGradientFill(grad) {
    trace("Error: Gradient fills are not yet implemented");
    sv.beginFill(0xFF0000, .7);
  }

  override public function beginFill(color, alpha) {
    sv.beginFill(color, alpha);
  }

  override public function endFill() {
    sv.endFill();
  }

  override public function lineStyle(style) {
  }

  override public function endLineStyle() {
  }

  override public function moveTo(x, y) {
    sv.moveTo(x,y);
  }
   
  override public function lineTo(x, y) {
    sv.lineTo(x,y);
  }

  override public function curveTo(cx, cy, x, y) {
    sv.curveTo(x, y, cx, cy);
  }

  public function get() {
    return sv;
  }
}