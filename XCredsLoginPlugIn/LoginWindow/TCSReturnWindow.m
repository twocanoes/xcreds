//
//  TCSReturnWindow.m
//  Boot Runner
//
//  Created by Tim Perfitt on 9/6/17.
//
//

#import "TCSReturnWindow.h"

@implementation TCSReturnWindow
- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(__unused NSWindowStyleMask)aStyle
                  backing:(__unused NSBackingStoreType)bufferingType
                    defer:(__unused BOOL)flag {
    
    // Using NSBorderlessWindowMask results in a window without a title bar.
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    if (self != nil) {
        // Start with no transparency for all drawing into the window
        [self setAlphaValue:0.5];
        //Set backgroundColor to clearColor
        self.backgroundColor = NSColor.grayColor;
        // Turn off opacity so that the parts of the window that are not drawn into are transparent.
//        [self setOpaque:NO];
    }
    return self;
}
@end
