#!/bin/bash

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
#echo "$SCRIPT_DIR"
touch "$SCRIPT_DIR"/mouseclick.c
cat > "$SCRIPT_DIR"/mouseclick.c << EOF
#include <ApplicationServices/ApplicationServices.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
  int x = 0, y = 0, n = 1;
  float duration = 0.1;

  if (argc < 3) {
    printf("USAGE: mouseclick X Y [N] [DURATION]\n");
    exit(1);
  }

  x = atoi(argv[1]);
  y = atoi(argv[2]);

  if (argc >= 4) {
    n = atoi(argv[3]);
  }

  if (argc >= 5) {
    duration = atof(argv[4]);
  }

  CGEventRef click_down = CGEventCreateMouseEvent(
    NULL, kCGEventLeftMouseDown,
    CGPointMake(x, y),
    kCGMouseButtonLeft
  );

  CGEventRef click_up = CGEventCreateMouseEvent(
    NULL, kCGEventLeftMouseUp,
    CGPointMake(x, y),
    kCGMouseButtonLeft
  );

  // Now, execute these events with an interval to make them noticeable
  for (int i = 0; i < n; i++) {
    CGEventPost(kCGHIDEventTap, click_down);
    usleep(100000);
    //sleep(duration);
    CGEventPost(kCGHIDEventTap, click_up);
    usleep(100000);
    //sleep(duration);
  }

  // Release the events
  CFRelease(click_down);
  CFRelease(click_up);

  return 0;
}
EOF

gcc -o "$SCRIPT_DIR"/mouseclick "$SCRIPT_DIR"/mouseclick.c -Wall -framework ApplicationServices

#chmod +x "$SCRIPT_DIR"/mouseclick
chmod 770 "$SCRIPT_DIR"/mouseclick
rm "$SCRIPT_DIR"/mouseclick.c

# usage 
# mouseclick x y [Number of times to click] [DURATION]
# example 
# mouseclick 100 600 1 1
