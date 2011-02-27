//
//  PreferenceController.h
//  MAL Updater OS X
//
//  Created by James M. on 8/8/10.
//  Copyright 2009-2010 Chikorita157's Anime Blog. All rights reserved. Code licensed under New BSD License
//
#import <Sparkle/Sparkle.h>
#import "MGTwitterEngine.h"

@interface PreferenceController  : NSWindowController <MGTwitterEngineDelegate> {
	//General
	IBOutlet NSTextField * APIUrl;
	
	//Login Preferences
	IBOutlet NSTextField * fieldusername;
	IBOutlet NSTextField * fieldpassword;
	IBOutlet NSButton * savebut;
	IBOutlet NSButton * clearbut;
	
	//Twitter Preferences
	IBOutlet NSButton * twitterlogin;
	IBOutlet NSButton * twitterlogout;
	IBOutlet NSTextField * twitterusername;
	IBOutlet NSTextField * twitterpassword;
	IBOutlet NSButton * chkenabletwitter;
	IBOutlet NSButton * chkincludeshowurl;
	IBOutlet NSTextField * usernamelbl;
	IBOutlet NSTextField * passwordlbl;
	IBOutlet NSTextField * logintwitterlbl;
	IBOutlet NSTextField * authorizedstatus;
	MGTwitterEngine *twitterEngine;
	OAToken *authtoken;
	
	int choice;
}
-(IBAction)checkupdates:(id)sender;
-(void)loadlogin;
-(IBAction)startlogin:(id)sender;
-(IBAction)clearlogin:(id)sender;
-(IBAction)registermal:(id)sender;
-(IBAction)testapi:(id)sender;
-(IBAction)resetapiurl:(id)sender;
-(void)clearcookieended:(NSAlert *)alert
				   code:(int)achoice
				 conext:(void *)v;
-(void)showsheetmessage:(NSString *)message
		   explaination:(NSString *)explaination;
-(IBAction)authTwitter:(id)sender;
-(IBAction)logouttwitter:(id)sender;
@end
