package ;

import flash.display.Sprite;

class Main extends Sprite {
  static function main() {
    flash.Lib.current.addChild(new openfl.display.FPS());
    
    S3D.main();
  }
}