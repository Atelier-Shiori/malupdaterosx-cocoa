//
//  SoftwareUpdatesPref.h
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 MAL Updater OS X Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>

@interface SoftwareUpdatesPref : NSViewController <MASPreferencesViewController>
@property (strong) IBOutlet NSButton *betacheck;
@end
