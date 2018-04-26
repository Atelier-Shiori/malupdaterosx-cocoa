//
//  LoginPref.h
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 MAL Updater OS X Group. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>
#import "MAL_Updater_OS_XAppDelegate.h"
#import "MyAnimeList+Keychain.h"

@class AuthWindow;

@interface LoginPref : NSViewController <MASPreferencesViewController>
@property (strong) IBOutlet NSImageView *logo;
//Login Preferences
@property (strong) IBOutlet NSButton *savebut;
@property (strong) IBOutlet NSButton *clearbut;
@property (strong) IBOutlet NSTextField *loggedinuser;
@property (strong) MAL_Updater_OS_XAppDelegate *appdelegate;
@property (strong) MyAnimeList *MALEngine;
@property (strong) IBOutlet NSView *loginview;
@property (strong) IBOutlet NSView *loggedinview;
@property (strong) AuthWindow *authw;
- (id)initwithAppDelegate:(MAL_Updater_OS_XAppDelegate *)adelegate;
- (IBAction)clearlogin:(id)sender;
- (IBAction)registermal:(id)sender;
- (void)login:(NSString *)pin withChallenge:(NSString *)challenge;
- (void)loadlogin;
@end
