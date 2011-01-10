//
//  Twitter.m
//  MAL Updater OS X - Twitter Class
//
//  Created by Nanoha Takamachi on 1/5/11.
//  Copyright 2009-2011 Chikorita157's Anime Blog. All rights reserved. All rights reserved. Code licensed under New BSD License.
//

#import "Twitter.h"


@implementation Twitter
-(void)postupdate:(NSString *)message; {
	//Load Defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *TwitterKey = [defaults objectForKey:@"OAUTH_MAL Updater OS X_twitter.com_KEY"];
	NSString *TwitterSecret = [defaults objectForKey:@"OAUTH_MAL Updater OS X_twitter.com_SECRET"];
	// Check Twitter Auth
	if (TwitterKey.length > 0 && TwitterSecret.length > 0) {
		if ([defaults boolForKey:@"EnableTwitterUpdates"] == 1) {
			NSLog(@"Posting Update");
			if (twitterEngine == nil) {
				NSLog(@"Creating MGTwitterEngine");
				// Create a TwitterEngine
				twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
				[twitterEngine setUsesSecureConnection:NO];
				[twitterEngine setConsumerKey:consumerKey secret:consumerSecret];
			}
			// See if OAuth token is nil
			if (token == nil) {
				NSLog(@"Retreving Auth Token");
				// Is nil... retreve token.
				token = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:@"MAL Updater OS X" prefix:@"twitter.com"];
			}
			// Set OAuth Token
			[twitterEngine setAccessToken:token];
			// Send Update
			[twitterEngine sendUpdate:message];
		}
	}

}
- (void)requestSucceeded:(NSString *)requestIdentifier {
}
- (void)requestFailed:(NSString *)requestIdentifier withError:(NSError *)error {
// Report Error
	[GrowlApplicationBridge notifyWithTitle:@"Twitter Error"
								description:[NSString stringWithFormat:@"%@",[error localizedDescription]]
						   notificationName:@"Message"
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:[NSDate date]];
}
@end
