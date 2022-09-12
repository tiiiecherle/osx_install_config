#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### mouseclick
###

#echo "$SCRIPT_DIR"
touch "$SCRIPT_DIR"/mouseclick_double.m
cat > "$SCRIPT_DIR"/mouseclick_double.m << EOF
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

    CGEventRef mouseEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, pt, kCGMouseButtonLeft);
    CGEventPost(kCGHIDEventTap, mouseEvent);

    // Left button up
    CGEventSetType(mouseEvent, kCGEventLeftMouseUp);
    CGEventPost(kCGHIDEventTap, mouseEvent);

    usleep(200000); // Improve reliability

    // 2nd click
    CGEventSetIntegerValueField(mouseEvent, kCGMouseEventClickState, 2);

    CGEventSetType(mouseEvent, kCGEventLeftMouseDown);
    CGEventPost(kCGHIDEventTap, mouseEvent);

    CGEventSetType(mouseEvent, kCGEventLeftMouseUp);
    CGEventPost(kCGHIDEventTap, mouseEvent);

    CFRelease(mouseEvent);
    
    [pool release];
    return 0;
}
EOF

gcc -o "$SCRIPT_DIR"/mouseclick_double "$SCRIPT_DIR"/mouseclick_double.m -framework ApplicationServices -framework Foundation

#chmod +x "$SCRIPT_DIR"/mouseclick_double
chmod 770 "$SCRIPT_DIR"/mouseclick_double
rm "$SCRIPT_DIR"/mouseclick_double.m

# usage 
# mouseclick -x [coord] -y [coord]
# example 
# mouseclick -x 100 -y 600
