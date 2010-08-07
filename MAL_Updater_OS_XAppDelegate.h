//
//  MAL_Updater_OS_XAppDelegate.h
//  MAL Updater OS X
//
//  Created by Tohno Minagi on 8/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MAL_Updater_OS_XAppDelegate : NSObject {
    NSWindow *window;
	IBOutlet NSMenu *statusMenu;
    NSStatusItem                *statusItem;
    NSImage                        *statusImage;
    NSImage                        *statusHighlightImage;
}

@property (assign) IBOutlet NSWindow *window;
@end
