//
//  MAL_Updater_OS_XAppDelegate.m
//  MAL Updater OS X
//
//  Created by Tohno Minagi on 8/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MAL_Updater_OS_XAppDelegate.h"

@implementation MAL_Updater_OS_XAppDelegate

@synthesize window;
- (void) awakeFromNib{
    
    //Create the NSStatusBar and set its length
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
    
    //Used to detect where our files are
    NSBundle *bundle = [NSBundle mainBundle];
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    statusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"malupdater" ofType:@"tiff"]];
    statusHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"malupdater" ofType:@"tiff"]];
    
    //Sets the images in our NSStatusItem
    [statusItem setImage:statusImage];
    [statusItem setAlternateImage:statusHighlightImage];
    
    //Tells the NSStatusItem what menu to load
    [statusItem setMenu:statusMenu];
    //Sets the tooptip for our item
    [statusItem setToolTip:@"MAL Updater OS X"];
    //Enables highlighting
    [statusItem setHighlightMode:YES];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
}

@end
