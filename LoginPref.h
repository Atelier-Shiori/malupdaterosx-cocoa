//
//  LoginPref.h
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>
#import "MAL_Updater_OS_XAppDelegate.h"
#import "MyAnimeList+Keychain.h"

@interface LoginPref : NSViewController <MASPreferencesViewController>
@property (strong) IBOutlet NSImageView *logo;
//Login Preferences
@property (strong) IBOutlet NSTextField *fieldusername;
@property (strong) IBOutlet NSTextField *fieldpassword;
@property (strong) IBOutlet NSButton *savebut;
@property (strong) IBOutlet NSButton *clearbut;
@property (strong) IBOutlet NSTextField *loggedinuser;
@property (strong) MAL_Updater_OS_XAppDelegate *appdelegate;
@property (strong) MyAnimeList *MALEngine;
@property (strong) IBOutlet NSView *loginview;
@property (strong) IBOutlet NSView *loggedinview;
- (id)initwithAppDelegate:(MAL_Updater_OS_XAppDelegate *)adelegate;
- (IBAction)startlogin:(id)sender;
- (IBAction)clearlogin:(id)sender;
- (IBAction)registermal:(id)sender;
- (void)login:(NSString *)username password:(NSString *)password;
- (void)loadlogin;
@end
