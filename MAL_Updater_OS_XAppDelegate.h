//
//  MAL_Updater_OS_XAppDelegate.h
//  MAL Updater OS X
//
//  Created by Tohno Minagi on 8/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PreferenceController;
@interface MAL_Updater_OS_XAppDelegate : NSObject {
    NSWindow *window;
	IBOutlet NSMenu *statusMenu;
    NSStatusItem                *statusItem;
    NSImage                        *statusImage;
    NSImage                        *statusHighlightImage;
	PreferenceController * preferenceController;
}
@property (assign) IBOutlet NSWindow *window;
-(void)showPreferences:(id)sender;
-(IBAction)togglescrobblewindow:(id)sender;
@end
