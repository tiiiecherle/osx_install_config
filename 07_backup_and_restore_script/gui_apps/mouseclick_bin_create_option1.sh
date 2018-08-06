#!/bin/bash

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
#echo "$SCRIPT_DIR"
touch "$SCRIPT_DIR"/mouseclick.m
cat > "$SCRIPT_DIR"/mouseclick.m << EOF
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

int main(int argc, char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSUserDefaults *args = [NSUserDefaults standardUserDefaults];

    int x = [args integerForKey:@"x"];
    int y = [args integerForKey:@"y"];

    CGPoint pt;
    pt.x = x;
    pt.y = y;

    CGEventRef mouseDownEv = CGEventCreateMouseEvent (NULL,kCGEventLeftMouseDown,pt,kCGMouseButtonLeft);
    CGEventPost (kCGHIDEventTap, mouseDownEv);
    usleep(100000);
    
    CGEventRef mouseUpEv = CGEventCreateMouseEvent (NULL,kCGEventLeftMouseUp,pt,kCGMouseButtonLeft);
    CGEventPost (kCGHIDEventTap, mouseUpEv );
    usleep(100000);

    [pool release];
    return 0;
}
EOF

gcc -o "$SCRIPT_DIR"/mouseclick "$SCRIPT_DIR"/mouseclick.m -framework ApplicationServices -framework Foundation

#chmod +x "$SCRIPT_DIR"/mouseclick
chmod 770 "$SCRIPT_DIR"/mouseclick
rm "$SCRIPT_DIR"/mouseclick.m

# usage 
# mouseclick -x [coord] -y [coord]
# example 
# mouseclick -x 100 -y 600
