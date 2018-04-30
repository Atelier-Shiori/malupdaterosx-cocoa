//
//  AdvancedPrefController.m
//  MAL Updater OS X
//
//  Created by Tail Red on 3/21/15.
//
//

#import "AdvancedPrefController.h"
#import "Utility.h"
#import <DetectionKit/DetectionKit.h>

@interface AdvancedPrefController ()

@end

@implementation AdvancedPrefController

@synthesize appdelegate;
@synthesize kodicheck;

- (id)init
{
    return [super initWithNibName:@"AdvancedPrefController" bundle:nil];
}
- (id)initwithAppDelegate:(MAL_Updater_OS_XAppDelegate *)adelegate{
    appdelegate = adelegate;
    return [super initWithNibName:@"AdvancedPrefController" bundle:nil];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"AdvancedPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameAdvanced];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Advanced", @"Toolbar item name for the Advanced preference pane");
}
- (IBAction)getHelp:(id)sender{
    //Show Help
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/malupdaterosx-cocoa/wiki/Advanced-Options"]];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textfield = notification.object;
    MyAnimeList *malengine = appdelegate.MALEngine;
    if ([textfield.identifier isEqualToString:@"kodihost"]) {
        [malengine.detection setKodiReachAddress:textfield.stringValue];
    }
 
}
- (IBAction)setKodiReach:(id)sender{
    MyAnimeList *malengine = appdelegate.MALEngine;
    if (kodicheck.state == 0) {
        // Turn off reachability notification for Kodi
        [malengine.detection setKodiReach:false];
    }
    else {
        // Turn on reachability notification for Kodi
        [malengine.detection setKodiReach:true];
    }
}

@end
