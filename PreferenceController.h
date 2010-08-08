//
//  PreferenceController.h
//  MAL Updater OS X
//
//  Created by Tohno Minagi on 8/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
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
@end
