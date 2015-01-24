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
}
-(IBAction)testapi:(id)sender;
-(IBAction)resetapiurl:(id)sender;
-(void)showsheetmessage:(NSString *)message
		   explaination:(NSString *)explaination;
-(IBAction)clearSearchCache:(id)sender;
@end
