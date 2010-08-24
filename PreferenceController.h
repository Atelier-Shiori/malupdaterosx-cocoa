//
//  PreferenceController.h
//  MAL Updater OS X
//
//  Created by James M. on 8/8/10.
//  Copyright 2009-2010 Chikorita157's Anime Blog. All rights reserved. Code licensed under New BSD License
//
#import <Sparkle/Sparkle.h>
@interface PreferenceController  : NSWindowController {
	IBOutlet NSTextField * fieldusername;
	IBOutlet NSTextField * fieldpassword;
	IBOutlet NSButton * savebut;
	IBOutlet NSButton * clearbut;
	int choice;
}
-(IBAction)checkupdates:(id)sender;
-(void)loadlogin;
-(IBAction)startlogin:(id)sender;
-(IBAction)clearlogin:(id)sender;
-(IBAction)registermal:(id)sender;
-(void)clearcookieended:(NSAlert *)alert
				   code:(int)achoice
				 conext:(void *)v;
-(void)showsheetmessage:(NSString *)message
		   explaination:(NSString *)explaination;
@end
