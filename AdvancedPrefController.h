//
//  AdvancedPrefController.h
//  MAL Updater OS X
//
//  Created by Tail Red on 3/21/15.
//
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"

@interface AdvancedPrefController : NSViewController <MASPreferencesViewController>{
    	IBOutlet NSTextField * APIUrl;
}
-(IBAction)testapi:(id)sender;
-(IBAction)resetapiurl:(id)sender;
@end
