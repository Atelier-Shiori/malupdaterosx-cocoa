//
//  MyAnimeList.m
//  MAL Updater OS X
//
//  Created by Tohno Minagi on 8/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MyAnimeList.h"
#import "ASIHTTPRequest.h"

@implementation MyAnimeList
- (IBAction)toggletimer:(id)sender {
	if (timer == nil) {
		//Create Timer
		timer = [[NSTimer scheduledTimerWithTimeInterval:60
												  target:self
												selector:@selector(firetimer:)
												userInfo:nil
												 repeats:YES] retain];
		[togglescrobbler setTitle:@"Stop Auto Scrobbling"];
		[ScrobblerStatus setObjectValue:@"Scrobble Status: Started"];
		//[GrowlApplicationBridge notifyWithTitle:@"MAL Updater OS X"
		//							description:@"Auto Scrobble is now turned on."
		//					   notificationName:@"Message"
		//							   iconData:nil
		//							   priority:0
		//							   isSticky:NO
		//						   clickContext:[NSDate date]];
	}
	else {
		//Stop Timer
		// Remove Timer
		[timer invalidate];
		[timer release];
		timer = nil;
		[togglescrobbler setTitle:@"Start Auto Scrobbling"];
		[ScrobblerStatus setObjectValue:@"Scrobble Status: Stopped"];
		//[GrowlApplicationBridge notifyWithTitle:@"MAL Updater OS X"
		//							description:@"Auto Scrobble is now turned off."
		//					   notificationName:@"Message"
		//							   iconData:nil
		//							   priority:0
		//							   isSticky:NO
		//						   clickContext:[NSDate date]];
	}
	
}
- (void)firetimer:(NSTimer *)aTimer {
	if ([self detectmedia] == 1) {
		NSLog(@"Detected : %@ - %@", DetectedTitle, DetectedEpisode);
		[DetectedTitle release];
		[DetectedEpisode release];
		NSString * AniID = [self searchanime];
		NSLog(@"%@",AniID);
		if (AniID.length > 0) {
			// Check Status and Update
			
		}
		[AniID release];
	}

}
-(NSString *)searchanime{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Escape Search Term
	NSString * searchterm = (NSString *)CFURLCreateStringByAddingPercentEscapes(
																				NULL,
																				(CFStringRef)DetectedTitle,
																				NULL,
																				(CFStringRef)@"!*'();:@&=+$,/?%#[]",
																				kCFStringEncodingUTF8 );

	//Set Search API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://mal-api.com/anime/search?q=%@",searchterm]];
	NSLog(@"%@",[NSString stringWithFormat:@"http://mal-api.com/anime/search?q=%@",searchterm]);
	//Release searchterm
	[searchterm release];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
	//Set Token
	[request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"Basic %@",[defaults objectForKey:@"Base64Token"]]];
	//Perform Search
	[request startSynchronous];
	// Get Status Code
	int statusCode = [request responseStatusCode];
			NSString *response = [request responseString];
	if (statusCode == 200 ) {
		return [self RegExSearchTitle:response];
		//release
		response = nil;
	}
	else {
		return @"";
	}

	//release
	request = nil;
	url = nil;
	
}
-(BOOL)detectmedia {
	// LSOF mplayer to get the media title and segment
	NSTask *task;
	task = [[NSTask alloc] init];
	[task setLaunchPath: @"/usr/sbin/lsof"];
	NSString * player;
	//Load Selected Player from Preferences
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	// Player Selection
	switch ([defaults integerForKey:@"PlayerSel"]) {
		case 0:
			player = @"mplayer";
			break;
		case 1:
			player = @"QTKitServer";
			break;
		case 2:
			player = @"vlc";
			break;
		case 3:
			player = @"QuickTime Player";
			break;
		default:
			break;
	}
	//lsof -c '<player name>' -Fn		
	[task setArguments: [NSArray arrayWithObjects:@"-c", player, @"-F", @"n", nil]];
	
	[player release];
	
	NSPipe *pipe;
	pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	
	[task launch];
	
	NSData *data;
	data = [file readDataToEndOfFile];
	
	//Release task
	[task autorelease];
	
	NSString *string;
	string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]autorelease];
	if (string.length > 0) {
		//Regex time
		//Setup OgreKit
		OGRegularExpressionMatch    *match;
		OGRegularExpression    *regex;
		//Get the filename first
		regex = [OGRegularExpression regularExpressionWithString:@"^.+(avi|mkv|mp4|ogm)$"];
		NSEnumerator    *enumerator;
		enumerator = [regex matchEnumeratorInString:string];		
		while ((match = [enumerator nextObject]) != nil) {
			string = [match matchedString];
		}
		//Cleanup
		regex = [OGRegularExpression regularExpressionWithString:@"^.+/"];
		string = [regex replaceAllMatchesInString:string
									   withString:@""];
		regex = [OGRegularExpression regularExpressionWithString:@"\\.\\w+$"];
		string = [regex replaceAllMatchesInString:string
									   withString:@""];
		regex = [OGRegularExpression regularExpressionWithString:@"[\\s_]*\\[[^\\]]+\\]\\s*"];
		string = [regex replaceAllMatchesInString:string
									   withString:@""];
		regex = [OGRegularExpression regularExpressionWithString:@"[\\s_]*\\([^\\)]+\\)$"];
		string = [regex replaceAllMatchesInString:string
									   withString:@""];
		regex = [OGRegularExpression regularExpressionWithString:@"_"];
		string = [regex replaceAllMatchesInString:string
									   withString:@" "];
		// Set Title Info
		regex = [OGRegularExpression regularExpressionWithString:@"( \\-)? (episode |ep |ep|e)?(\\d+)([\\w\\-! ]*)$"];
		DetectedTitle = [regex replaceAllMatchesInString:string
														 withString:@""];
		// Set Episode Info
		regex = [OGRegularExpression regularExpressionWithString:@" - "];
		string = [regex replaceAllMatchesInString:string
									   withString:@""];
		regex = [OGRegularExpression regularExpressionWithString: DetectedTitle];
		DetectedEpisode = [regex replaceAllMatchesInString:string
													  withString:@""];
		// Trim Whitespace
		DetectedTitle = [DetectedTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		//release
		regex = nil;
		enumerator = nil;
		// Set Status
		[DetectedTitle retain];
		[DetectedEpisode retain];
		return YES;
	}
	else {
		return NO;
	}
	string = nil;
	
	
}
-(NSString *)RegExSearchTitle:(NSString *)ResponseData {
	OGRegularExpressionMatch    *match;
	OGRegularExpression    *regex;
	//Get the filename first
	regex = [OGRegularExpression regularExpressionWithString:DetectedTitle];
	NSEnumerator    *enumerator;
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSArray *searchdata = [parser objectWithString:ResponseData error:nil];
	for (id obj in searchdata) {
		// Look in every RegEx Entry until the extact title is found.
		enumerator = [regex matchEnumeratorInString:[obj objectForKey:@"title"]];
		while ((match = [enumerator nextObject]) != nil) {
			// Return the AniID for the matched title
			return [obj objectForKey:@"id"];
		}
	}
	// Nothing Found, return nothing
	return @"";
}

@end
