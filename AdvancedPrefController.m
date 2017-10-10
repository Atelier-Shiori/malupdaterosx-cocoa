//
//  AdvancedPrefController.m
//  MAL Updater OS X
//
//  Created by Tail Red on 3/21/15.
//
//

#import "AdvancedPrefController.h"
#import "Utility.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>
#import <DetectionKit/DetectionKit.h>

@interface AdvancedPrefController ()

@end

@implementation AdvancedPrefController

@synthesize APIUrl;
@synthesize appdelegate;
@synthesize kodicheck;
@synthesize testapibtn;
@synthesize testprogressindicator;

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
- (IBAction)testapi:(id)sender
{
    [testprogressindicator setHidden:NO];
    [testprogressindicator startAnimation:nil];
    [testapibtn setEnabled:NO];
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        //Load API URL
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        //Set URL
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/2.1/animelist/chikorita157", [defaults objectForKey:@"MALAPIURL"]]];
        EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
        //Ignore Cookies
        [request setUseCookies:NO];
        //Test API
        [request startRequest];
        // Get Status Code
        long statusCode = [request getStatusCode];
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (statusCode) {
                case 200:
                    [Utility showsheetmessage:@"API Test Successful" explaination:[NSString stringWithFormat:@"HTTP Code: %li", statusCode] window: self.view.window];
                    break;
                default:
                    [Utility showsheetmessage:@"API Test Unsuccessful" explaination:[NSString stringWithFormat:@"HTTP Code: %li", statusCode] window:self.view.window];
                    break;
            }
            [testprogressindicator setHidden:YES];
            [testprogressindicator stopAnimation:nil];
            [testapibtn setEnabled:YES];
        });
    });
}
- (IBAction)resetapiurl:(id)sender
{
    //Reset Unofficial MAL API URL
    APIUrl.stringValue = @"https://malapi.ateliershiori.moe";
    // Generate API Key
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults] ;
    [defaults setObject:APIUrl.stringValue forKey:@"MALAPIURL"];
    
}
- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textfield = notification.object;
    MyAnimeList *malengine = appdelegate.MALEngine;
    [malengine.detection setKodiReachAddress:textfield.stringValue];
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
