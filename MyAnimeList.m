//
//  MyAnimeList.m
//  MAL Updater OS X
//
//  Created by Tohno Minagi on 8/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MyAnimeList.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

@implementation MyAnimeList
- (IBAction)toggletimer:(id)sender {
	if (timer == nil) {
		//Create Timer
		timer = [[NSTimer scheduledTimerWithTimeInterval:30
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
		[ScrobblerStatus setObjectValue:@"Scrobble Status: Scrobbling..."];
		NSLog(@"Detected : %@ - %@", DetectedTitle, DetectedEpisode);
		NSString * AniID;
		AniID = [self searchanime];
		NSLog(@"%@",AniID);
		if (AniID.length > 0) {
			// Check Status and Update
			BOOL * UpdateBool = [self checkstatus:AniID];
			if (UpdateBool == 1) {
			switch ([DetectedCurrentEpisode intValue]) {
				case 0:
					// Add Title
					Success = [self addtitle:AniID];
					break;
				default:
					// Update Title as Usual
					Success = [self updatetitle:AniID];
					break;
			}
				//Retain Scrobbled Title and Episode
				[LastScrobbledTitle retain];
				[LastScrobbledEpisode retain];
			}
		}
		else {
			// Not Successful
			[ScrobblerStatus setObjectValue:@"Scrobble Status: Scrobbled Failed. Retrying in 5 mins..."];
			Success = NO;
		}
		[DetectedTitle release];
		[DetectedEpisode release];
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
		return [self regexsearchtitle:response];
	}
	else {
		Success = NO;
		[ScrobblerStatus setObjectValue:@"Scrobble Status: Scrobbled Failed. Retrying in 5 mins..."];
		return @"";
	}
	
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
		// Check if the title was previously scrobbled
		if ([DetectedTitle isEqualToString:LastScrobbledTitle] && [DetectedEpisode isEqualToString: LastScrobbledEpisode] && Success == 1) {
			// Do Nothing
			[ScrobblerStatus setObjectValue:@"Scrobble Status: Same Episode Playing, Scrobble not needed."];
			[LastScrobbled setObjectValue:[NSString stringWithFormat:@"Last Scrobbled: %@ - %@",DetectedTitle,DetectedEpisode]];
			[DetectedTitle release];
			[DetectedEpisode release];
			return NO;
		}
		else {
			// Not Scrobbled Yet or Unsuccessful
			[DetectedTitle retain];
			[DetectedEpisode retain];
		return YES;
		}
	}
	else {
		// Nothing detected
		return NO;
	}
}
-(NSString *)regexsearchtitle:(NSString *)ResponseData {
	OGRegularExpressionMatch    *match;
	OGRegularExpression    *regex;
	//Set Detected Anime Title
	regex = [OGRegularExpression regularExpressionWithString:[NSString stringWithFormat:@"^%@$",DetectedTitle]];
	NSEnumerator    *enumerator;
	// Initalize JSON parser
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSArray *searchdata = [parser objectWithString:ResponseData error:nil];
	NSString *titleid;
	for (id obj in searchdata) {
		// Look in every RegEx Entry until the extact title is found.
		enumerator = [regex matchEnumeratorInString:[obj objectForKey:@"title"]];
		while ((match = [enumerator nextObject]) != nil) {
			titleid = [NSString stringWithFormat:@"%@" ,[obj objectForKey:@"id"]];
		}
	}
	// Nothing Found, return nothing
	return titleid;
}
-(BOOL)checkstatus:(NSString *)AniID {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Set Search API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://mal-api.com/anime/%@?mine=1",AniID]];
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
		NSLog(@"%@", response);
		// Initalize JSON parser
		NSDictionary *animeinfo = [response JSONValue];
		TotalEpisodes = [animeinfo objectForKey:@"episodes"];
		DetectedCurrentEpisode = [animeinfo objectForKey:@"watched_episodes"];
		// Makes sure the values don't get released
		[TotalEpisodes retain];
		[DetectedCurrentEpisode retain];
		return YES;
	}
	else {
		// Some Error. Abort
		[ScrobblerStatus setObjectValue:@"Scrobble Status: Scrobbled Failed. Retrying in 5 mins..."];
		return NO;
	}
	//Should never happen, but...
	return NO;
}
-(BOOL)updatetitle:(NSString *)AniID {
	if ([DetectedEpisode intValue] == [DetectedCurrentEpisode intValue] ) {
		// Already Watched, no need to scrobble
		[ScrobblerStatus setObjectValue:@"Scrobble Status: Same Episode Playing, Scrobble not needed."];
		[LastScrobbled setObjectValue:[NSString stringWithFormat:@"Last Scrobbled: %@ - %@",DetectedTitle,DetectedEpisode]];
		return YES;
	}
	else {
		// Update the title
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		//Set library/scrobble API
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://mal-api.com/animelist/anime/%@",AniID]];
		ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
		//Ignore Cookies
		[request setUseCookiePersistence:NO];
		//Set Token
		[request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"Basic %@",[defaults objectForKey:@"Base64Token"]]];
	    [request setPostValue:@"PUT" forKey:@"_method"];
	    [request setPostValue:DetectedEpisode forKey:@"episodes"];
		//Set Status
		if ([DetectedEpisode intValue] == [TotalEpisodes intValue]) {
			// Since Detected Episode = Total Episode, set the status as "Complete"
			[request setPostValue:@"completed" forKey:@"status"];
		}
		else {
			// Still Watching
			[request setPostValue:@"watching" forKey:@"status"];
		}	
		// Do Update
		[request startSynchronous];
		
		// Store Scrobbled Title and Episode
		LastScrobbledTitle = DetectedTitle;
		LastScrobbledEpisode = DetectedEpisode;
		
		switch ([request responseStatusCode]) {
			case 200:
				// Update Successful
				[ScrobblerStatus setObjectValue:@"Scrobble Status: Scrobble Successful..."];
				[LastScrobbled setObjectValue:[NSString stringWithFormat:@"Last Scrobbled: %@ - %@",DetectedTitle,DetectedEpisode]];
				return YES;
				break;
			default:
				// Update Unsuccessful
				[ScrobblerStatus setObjectValue:@"Scrobble Status: Scrobbled Failed. Retrying in 5 mins..."];
				return NO;
				break;
		}

	}
}
-(BOOL)addtitle:(NSString *)AniID {
	// Add the title
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Set library/scrobble API
	NSURL *url = [NSURL URLWithString:@"http://mal-api.com/animelist/anime"];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
	//Set Token
	[request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"Basic %@",[defaults objectForKey:@"Base64Token"]]];
	[request setPostValue:AniID forKey:@"anime_id"];
	[request setPostValue:DetectedEpisode forKey:@"episodes"];
	[request setPostValue:@"watching" forKey:@"status"];	
	// Do Update
	[request startSynchronous];

	// Store Scrobbled Title and Episode
	LastScrobbledTitle = DetectedTitle;
	LastScrobbledEpisode = DetectedEpisode;

	switch ([request responseStatusCode]) {
		case 200:
			// Update Successful
			[ScrobblerStatus setObjectValue:@"Scrobble Status: Title Added..."];
			[LastScrobbled setObjectValue:[NSString stringWithFormat:@"Last Scrobbled: %@ - %@",DetectedTitle,DetectedEpisode]];
			return YES;
			break;
		default:
			// Update Unsuccessful
			[ScrobblerStatus setObjectValue:@"Scrobble Status: Adding of Title Failed. Retrying in 5 mins..."];
			return NO;
			break;
	}
}
@end
