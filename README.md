Requires a few fixes to properly work in the stage3d openfl target.

Not optimized, just a rough prototype. No line support, no gradient support.

(Note that currently this does two entire passes, when it should only be rendering a single quad on the second pass.)

Sources:
  http://http.developer.nvidia.com/GPUGems3/gpugems3_ch25.html	
  http://staffwww.itn.liu.se/~andyn/courses/tncg08/sketches06/sketches/0125-kokojima.pdf