//
//  GeneralPrefController.h
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>


@interface GeneralPrefController : NSViewController <MASPreferencesViewController>

@property (strong) IBOutlet NSButton *disablenewtitlebar;
@property (strong) IBOutlet NSButton *disablevibarency;
@property (strong) IBOutlet NSButton *startatlogin;
@property (strong) IBOutlet NSProgressIndicator *indicator;
@property (strong) IBOutlet NSButton *updateexceptionsbtn;
@property (strong) IBOutlet NSButton *updateexceptionschk;

- (IBAction)clearSearchCache:(id)sender;
@end
