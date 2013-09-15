package ;

import haxe.macro.Expr;
import haxe.macro.*;

class Alg {
  macro public static function debug_assert(e:Expr):Expr {
    return switch (e.expr) {
    case EBinop(op, e1, e2):
      var f = {expr: EBinop(op, e1, macro o_e2), pos:e.pos};

      var printer = new Printer();
      var print_full = printer.printExpr(e);
      var print_e1 = printer.printExpr(e1);
      var print_op = printer.printBinop(op);
      
      macro {
        #if debug
        var o_e2 = $e2;
        if (!$f) {
          throw "Assertion failed: " +
            $v{print_e1} + "" + $v{print_op} + "" + o_e2 + " @where: " +
            $v{print_full};

        }
        #end
      }
    case _: Context.error("debug_assert expects argument in form of: $expected (op) $expr (example: 10 == 5 + 5)", e.pos);
    }
  }

  public static function mkColor(rgb:Int, alpha:Float) {
    return [ ((rgb>>>16) & 0xFF)/256
           , ((rgb>>>8 ) & 0xFF)/256
           , ((rgb     ) & 0xFF)/256
           , alpha
           ];
  }
}