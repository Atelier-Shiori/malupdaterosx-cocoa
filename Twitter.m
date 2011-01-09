//
//  Twitter.m
//  MAL Updater OS X - Twitter Class
//
//  Created by Nanoha Takamachi on 1/5/11.
//  Copyright 2009-2011 Chikorita157's Anime Blog. All rights reserved.
//

#import "Twitter.h"


@implementation Twitter
// Twitter Consumer Key and Secret
// Register for a Key/Secret at Twitter Developers Site - http://dev.twitter.com/
// Twitter Support will not work without it! XAuth support is required too. 
NSString * const consumerKey = @"<consumer key here>";
NSString * const consumerSecret = @"<consumer secret here>";

- (IBAction)authTwitter:(id)sender {
	// See if Twitter Engine is allocated
	if (twitterEngine == nil) {
		NSLog(@"Creating MGTwitterEngine");
		// Create a TwitterEngine
		twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
		[twitterEngine setUsesSecureConnection:NO];
		[twitterEngine setConsumerKey:consumerKey secret:consumerSecret];
	}
	
	//Login
	[twitterEngine getXAuthAccessTokenForUsername:[twitterusername stringValue] password:[twitterpassword stringValue]];
	
		[twitterEngine setAccessToken:token];
}

- (void)accessTokenReceived:(OAToken *)aToken forRequest:(NSString *)connectionIdentifier {	
	NSLog(@"Logged in!");
	//Retrieve Token
	token = [aToken retain];
	//Store Token in keychain
	[token storeInUserDefaultsWithServiceProviderName:@"MAL Updater OS X" prefix:@"twitter.com"];
	// Change Button States
	[twitterlogin setHidden:TRUE];
	[twitterlogout setHidden:FALSE];
	[twitterusername setHidden:TRUE];
	[twitterpassword setHidden:TRUE];
	[chkenabletwitter setHidden:FALSE];
	[usernamelbl setHidden:TRUE];
	[passwordlbl setHidden:TRUE];
	[logintwitterlbl setHidden:TRUE];
	[authorizedstatus setHidden:FALSE];
}

-(IBAction)logouttwitter:(id)sender {
	//Logout
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	// Chear Key
	[defaults setObject:@"" forKey:@"OAUTH_MAL Updater OS X_twitter.com_KEY"];
	// Clear Secret
	[defaults setObject:@"" forKey:@"OAUTH_MAL Updater OS X_twitter.com_SECRET"];
	// Change Button States
	[twitterlogin setHidden:FALSE];
	[twitterlogout setHidden:TRUE];
	[twitterusername setHidden:FALSE];
	[twitterpassword setHidden:FALSE];
	[chkenabletwitter setHidden:TRUE];
	[usernamelbl setHidden:FALSE];
	[passwordlbl setHidden:FALSE];
	[logintwitterlbl setHidden:FALSE];
	[authorizedstatus setHidden:TRUE];
}
-(void)postupdate:(NSString *)message; {
	//Load Defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *TwitterKey = [defaults objectForKey:@"OAUTH_MAL Updater OS X_twitter.com_KEY"];
	NSString *TwitterSecret = [defaults objectForKey:@"OAUTH_MAL Updater OS X_twitter.com_SECRET"];
	// Check Twitter Auth
	if (TwitterKey.length > 0 && TwitterSecret.length > 0) {
		if ([defaults boolForKey:@"ShowAtStartup"] == 0) {
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
