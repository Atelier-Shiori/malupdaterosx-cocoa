//
//  SoftwareUpdatesPref.h
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>

@interface SoftwareUpdatesPref : NSViewController <MASPreferencesViewController>  {
    IBOutlet NSButton * betacheck;
}
@end
