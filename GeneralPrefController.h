//
//  GeneralPrefController.h
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"


@interface GeneralPrefController : NSViewController <MASPreferencesViewController> {
	//General
	IBOutlet NSTextField * APIUrl;
    IBOutlet NSButton * disablenewtitlebar;
    IBOutlet NSButton * disablevibarency;
    IBOutlet NSButton * startatlogin;
    IBOutlet NSProgressIndicator * indicator;
    IBOutlet NSButton * updateexceptionsbtn;
    IBOutlet NSButton * updateexceptionschk;
}
-(IBAction)testapi:(id)sender;
-(IBAction)resetapiurl:(id)sender;
-(IBAction)clearSearchCache:(id)sender;
@end
