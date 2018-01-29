//
//  PlexPrefs.m
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/07/11.
//
//

#import "PlexPrefs.h"
#import <DetectionKit/DetectionKit.h>
#import "PlexLogin.h"
#import "MAL_Updater_OS_XAppDelegate.h"
#import "MyAnimeList.h"

@interface PlexPrefs ()
@property (strong) IBOutlet NSButton *plexlogin;
@property (strong) IBOutlet NSButton *plexlogout;
@property (strong) IBOutlet NSButton *plexcheck;
@property (strong) IBOutlet NSTextField *plexusernamelabel;
@property (strong) PlexLogin *plexloginwindowcontroller;
@property (strong) MyAnimeList *MALEngine;
@end

@implementation PlexPrefs
@synthesize MALEngine;
@synthesize plexlogin;
@synthesize plexlogout;
@synthesize plexusernamelabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    // Load Login State for Plex
    [self loadplexlogin];
}
- (id)init
{
    // Initalize MAL Engine value
    MAL_Updater_OS_XAppDelegate *appdelegate = (MAL_Updater_OS_XAppDelegate *)[NSApplication sharedApplication].delegate;
    MALEngine = appdelegate.MALEngine;
    return [super initWithNibName:@"PlexPrefs" bundle:nil];
}
#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"PlexMediaServerPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"plex"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Plex", @"Toolbar item name for the Plex Media Server preference pane");
}
#pragma mark -
#pragma mark Plex Media Server Detection Prefs
- (void)loadplexlogin {
    NSString *username = [PlexAuth checkplexaccount];
    if (username.length > 0) {
        plexusernamelabel.stringValue = [NSString stringWithFormat:@"Logged in as: %@", username];
        plexlogin.hidden = YES;
        plexlogout.hidden = NO;
    }
    else {
        plexusernamelabel.stringValue = @"Not logged in.";
        plexlogin.hidden = NO;
        plexlogout.hidden = YES;
    }
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField * textfield = notification.object;
    [MALEngine.detection setPlexReachAddress:textfield.stringValue];
    
}

- (IBAction)setPlexReach:(id)sender {
    if (_plexcheck.state == 0) {
        // Turn off reachability notification for Kodi
        [MALEngine.detection setPlexReach:false];
    }
    else {
        // Turn on reachability notification for Kodi
        [MALEngine.detection setPlexReach:true];
    }
}

- (IBAction)plexlogin:(id)sender {
    if (!_plexloginwindowcontroller) {
        _plexloginwindowcontroller = [PlexLogin new];
    }
    [self.view.window beginSheet:_plexloginwindowcontroller.window completionHandler:^(NSModalResponse returnCode) {
        [self plexloginDidEnd:returnCode];
    }];
}

- (void)plexloginDidEnd:(long)returnCode {
    if (returnCode == NSModalResponseOK) {
        [self loadplexlogin];
    }
}

- (IBAction)plexlogout:(id)sender {
    if ([PlexAuth removeplexaccount]) {
        [self loadplexlogin];
    }
}

@end
