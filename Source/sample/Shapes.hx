package sample;

class Shapes {
  public static function square(sv:StencilVector, halfSize:Float) {
    sv.moveTo(-halfSize, -halfSize);
    sv.lineTo(-halfSize,  halfSize);
    sv.lineTo( halfSize,  halfSize);
    sv.lineTo( halfSize, -halfSize);
    sv.lineTo(-halfSize, -halfSize);
  }

  public static function arc(sv:StencilVector) {
    sv.moveTo(-.5, -.5);
    sv.lineTo( .5, -.5);
    sv.curveTo(-.5, -.5, 0.0, .5);
  }

  public static function twinSquares(sv:StencilVector) {
    sv.moveTo(-.75, -.75);
    sv.lineTo(-.25, -.75);
    sv.lineTo(-.25, -.25);
    sv.lineTo(-.75, -.25);
    sv.lineTo(-.75, -.75);

    sv.moveTo(.75, .75);
    sv.lineTo(.25, .75);
    sv.lineTo(.25, .25);
    sv.lineTo(.75, .25);
    sv.lineTo(.75, .75);
  }
}