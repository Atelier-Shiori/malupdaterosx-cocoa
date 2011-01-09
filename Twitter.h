//
//  Twitter.h
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGTwitterEngine.h"
#import "MAL_Updater_OS_XAppDelegate.h"

@class OAToken;

@interface Twitter : NSObject <MGTwitterEngineDelegate> {
    MGTwitterEngine *twitterEngine;
	
	OAToken *token;
	IBOutlet NSTextField * twitterusername;
	IBOutlet NSTextField * twitterpassword;
	IBOutlet NSButton * twitterlogin;
	IBOutlet NSButton * twitterlogout;
	IBOutlet NSButton * chkenabletwitter;
	IBOutlet NSTextField * usernamelbl;
	IBOutlet NSTextField * passwordlbl;
	IBOutlet NSTextField * logintwitterlbl;
	IBOutlet NSTextField * authorizedstatus;
}

-(IBAction)authTwitter:(id)sender;
-(void)postupdate:(NSString *)message;
-(IBAction)logouttwitter:(id)sender;
@end
