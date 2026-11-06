// Moves the mouse pointer to a point in global display coordinates (origin at
// the top-left of the main display, as yabai reports frames).
//
//   warp_mouse <x> <y>
//
// The pointer jumps without a mouse-moved event, so focus_follows_mouse
// doesn't refocus whatever window lies under it.

#include <CoreGraphics/CoreGraphics.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv) {
  if (argc != 3) {
    fprintf(stderr, "usage: warp_mouse <x> <y>\n");
    return 1;
  }
  CGPoint point = CGPointMake(atof(argv[1]), atof(argv[2]));
  return CGWarpMouseCursorPosition(point) == kCGErrorSuccess ? 0 : 1;
}
