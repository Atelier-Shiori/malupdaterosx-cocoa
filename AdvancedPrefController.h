//
//  AdvancedPrefController.h
//  MAL Updater OS X
//
//  Created by Tail Red on 3/21/15.
//
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>
#import "MAL_Updater_OS_XAppDelegate.h"
#import "MyAnimeList.h"

@interface AdvancedPrefController : NSViewController <MASPreferencesViewController>{
    	IBOutlet NSTextField *APIUrl;
        MAL_Updater_OS_XAppDelegate* appdelegate;
        IBOutlet NSButton *kodicheck;
    __weak IBOutlet NSButton *testapibtn;
    __weak IBOutlet NSProgressIndicator *testprogressindicator;
}
- (id)initwithAppDelegate:(MAL_Updater_OS_XAppDelegate *)adelegate;
- (IBAction)testapi:(id)sender;
- (IBAction)resetapiurl:(id)sender;
@end
