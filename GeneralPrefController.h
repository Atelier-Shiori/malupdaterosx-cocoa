//
//  GeneralPrefController.h
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>


@interface GeneralPrefController : NSViewController <MASPreferencesViewController> {
	//General
    IBOutlet NSButton * disablenewtitlebar;
    IBOutlet NSButton * disablevibarency;
    IBOutlet NSButton * startatlogin;
    IBOutlet NSProgressIndicator * indicator;
    IBOutlet NSButton * updateexceptionsbtn;
    IBOutlet NSButton * updateexceptionschk;
}

- (IBAction)clearSearchCache:(id)sender;
@end
