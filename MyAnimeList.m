//
//  MyAnimeList.m
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList.h"

@implementation MyAnimeList

/* 
 
 Accessors
 
 */
-(NSString *)getLastScrobbledTitle
{
    return LastScrobbledTitle;
}
-(NSString *)getLastScrobbledEpisode
{
    return LastScrobbledEpisode;
}
-(NSString *)getAniID
{
    return AniID;
}
-(NSString *)getTotalEpisodes
{
	return TotalEpisodes;
}
-(int)getScore
{
    return [TitleScore integerValue];
}
-(int)getWatchStatus
{
	if ([WatchStatus isEqualToString:@"watching"])
		return 0;
	else if ([WatchStatus isEqualToString:@"completed"])
		return 1;
	else if ([WatchStatus isEqualToString:@"on-hold"])
		return 2;
	else if ([WatchStatus isEqualToString:@"dropped"])
		return 3;
    else if ([WatchStatus isEqualToString:@"plan-to-watch"])
        return 4;
	else
		return 0; //fallback
}
-(BOOL)getSuccess{
    return Success;
}

/*
 
 Update Methods
 
 */

- (int)startscrobbling {
    // 0 - nothing playing; 1 - same episode playing; 21 - Add Title Successful; 22 - Update Title Successful;  51 - Can't find Title; 52 - Add Failed; 53 - Update Failed; 54 - Scrobble Failed; 
    int status, detectstatus;
	//Set up Delegate
	
    detectstatus = [self detectmedia];
	if (detectstatus == 2) { // Detects Title
		
		NSLog(@"Getting AniID");
		AniID = [self searchanime];
		if (AniID.length > 0) {
            NSLog(@"Found %@", AniID);
			// Check Status and Update
			BOOL UpdateBool = [self checkstatus:AniID];
			if (UpdateBool == 1) {
			if ([WatchStatus isEqualToString:@"Nothing"]) {
				//Title is not on list. Add Title
				Success = [self addtitle:AniID];
                if (Success)
                    status = 21;
                else
                    status = 52;
			}
			else {
				// Update Title as Usual
                int s = [self updatetitle:AniID];
                if (s == 1 || s == 22) {
                    Success = true;
                }
                else{
                    Success = false;}
                status = s;
                
			}
				//Set last successful scrobble to statusItem Tooltip
				//[appDelegate setStatusToolTip:[NSString stringWithFormat:@"MAL Updater OS X - Last Scrobble: %@ - %@", LastScrobbledTitle, LastScrobbledEpisode]];
				//Retain Scrobbled Title, Title ID, Title Score, WatchStatus and Episode
			}
            else{
                status = 54;
            }
		}
		else {
			// Not Successful
            status = 51;
			
		}
		// Empty out Detected Title/Episode to prevent same title detection
		DetectedTitle = @"";
		DetectedEpisode = @"";
		// Release Detected Title/Episode.
        return status;
	}

    return detectstatus;
}
-(NSString *)searchanime{
	NSLog(@"Searching For Title");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Escape Search Term
	NSString * searchterm = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
																				NULL,
																				(CFStringRef)DetectedTitle,
																				NULL,
																				(CFStringRef)@"!*'();:@&=+$,/?%#[]",
																				kCFStringEncodingUTF8 ));
	MALApiUrl = [defaults objectForKey:@"MALAPIURL"];

	//Set Search API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/anime/search?q=%@",MALApiUrl, searchterm]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
	//Set Token
	[request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"Basic %@",[defaults objectForKey:@"Base64Token"]]];
	//Perform Search
	[request startSynchronous];
	//Set up Delegate
	
	// Get Status Code
	int statusCode = [request responseStatusCode];
			NSString *response = [request responseString];
	switch (statusCode) {
		case 200:
			return [self findaniid:response];
			break;
			
		default:
			Success = NO;
			return @"";
			break;
	}
	
}
-(int)detectmedia {
	//Set up Delegate
	//
	// LSOF mplayer to get the media title and segment

    NSArray * player = [NSArray arrayWithObjects:@"mplayer", @"mpv", @"VLC", @"QTKitServer", nil];
    NSString *string;
	
    for(int i = 0; i <4; i++){
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/sbin/lsof"];
    [task setArguments: [NSArray arrayWithObjects:@"-c", [NSString stringWithFormat:@"%@", [player objectAtIndex:i]], @"-F", @"n", nil]]; 		//lsof -c '<player name>' -Fn
	NSPipe *pipe;
	pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	
	[task launch];
	
	NSData *data;
	data = [file readDataToEndOfFile];

    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

    if (string.length > 0)
        break;
    }
	if (string.length > 0) {
        //Regex time
        //Get the filename first
        regex = [OGRegularExpression regularExpressionWithString:@"^.+(avi|mkv|mp4|ogm)$"];
        NSEnumerator    *enumerator;
        enumerator = [regex matchEnumeratorInString:string];
        while ((match = [enumerator nextObject]) != nil) {
            string = [match matchedString];
        }
        //Accented e temporary fix
        regex = [OGRegularExpression regularExpressionWithString:@"e\\\\xcc\\\\x81"];
        string = [regex replaceAllMatchesInString:string
                                       withString:@"è"];
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
        regex = [OGRegularExpression regularExpressionWithString:@"~"];
        string = [regex replaceAllMatchesInString:string
                                       withString:@""];
        // Set Title Info
        regex = [OGRegularExpression regularExpressionWithString:@"( \\-) (episode |ep |ep|e)?(\\d+)([\\w\\-! ]*)$"];
        DetectedTitle = [regex replaceAllMatchesInString:string
                                              withString:@""];
        regex = [OGRegularExpression regularExpressionWithString:@"-"];
        string = [regex replaceAllMatchesInString:string
                                       withString:@""];
        regex = [OGRegularExpression regularExpressionWithString: @"\\b\\S\\d+$"];
        DetectedTitle = [regex replaceAllMatchesInString:DetectedTitle
                                              withString:@""];
        // Set Episode Info
        regex = [OGRegularExpression regularExpressionWithString: DetectedTitle];
        string = [regex replaceAllMatchesInString:string
                                       withString:@""];
        regex = [OGRegularExpression regularExpressionWithString:@"v[\\d]"];
        DetectedEpisode = [regex replaceAllMatchesInString:string
                                                withString:@""];
		// Trim Whitespace
		DetectedTitle = [DetectedTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		DetectedEpisode = [DetectedEpisode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //release
		regex = nil;
		enumerator = nil;
		string = @"";
		// Check if the title was previously scrobbled
		if ([DetectedTitle isEqualToString:LastScrobbledTitle] && [DetectedEpisode isEqualToString: LastScrobbledEpisode] && Success == 1) {
			// Do Nothing
			//[appDelegate setStatusText:@"Scrobble Status: Same Episode Playing, Scrobble not needed."];
			//[appDelegate setLastScrobbledTitle:[NSString stringWithFormat:@"Last Scrobbled: %@ - %@",DetectedTitle,DetectedEpisode]];
            return 1;
		}
		else {
			// Not Scrobbled Yet or Unsuccessful
            return 2;
		}
	}
	else {
		// Nothing detected
		//[appDelegate setStatusText:@"Scrobble Status: Idle..."];
        return 0;
	}
}
-(NSString *)findaniid:(NSString *)ResponseData {
	// Initalize JSON parser
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSArray *searchdata = [parser objectWithString:ResponseData error:nil];
	NSString *titleid = @"";
	//Initalize NSString to dump the title temporarily
	NSString *theshowtitle = @"";
    NSString *theshowtype = @"";
	//Set Regular Expressions to omit any preceding words
	NSString *findpre = [NSString stringWithFormat:@"(%@)",DetectedTitle];
	findpre = [findpre stringByReplacingOccurrencesOfString:@" " withString:@"|"]; // NSString *findpre = [NSString stringWithFormat:@"^%@",DetectedTitle];
	regex = [OGRegularExpression regularExpressionWithString:findpre options:OgreIgnoreCaseOption];
	//Retrieve the ID. Note that the most matched title will be on the top
    BOOL idok; // Checks the status
    // For Sanity (TV shows and OVAs usually have more than one episode)
    if(DetectedEpisode.length == 0){
        // Title is a movie
        NSLog(@"Title is a movie");
        DetectedTitleisMovie = true;
    }
    else{
        // Is TV Show
        NSLog(@"Title is not a movie.");
        DetectedTitleisMovie = false;
    }
	for (NSDictionary *searchentry in searchdata) {
		//Store title from search entry
		theshowtitle = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"title"]];
        theshowtype = [NSString stringWithFormat:@"%@", [searchentry objectForKey:@"type"]];
        NSLog(@"%@ - %@", theshowtitle,theshowtype);
        // Checks to make sure MAL Updater OS X is updating the correct type of show
        if (DetectedTitleisMovie) {
            if ([theshowtype isEqualToString:@"Movie"]) {
                DetectedEpisode = @"1"; // Usually, there is one episode in a movie.
                idok = true;
            }
            else {
                idok = false;
            }
        }
        else if([theshowtype isEqualToString:@"Movie"]){
            idok = false; // Rejects result, not a movie.
        }
        else{
            //OK to go
            idok = true;
        }
        if (idok) { // Good to go, check the title with regular expressions
            if ([regex matchInString:theshowtitle] != nil) {
                //Return titleid
                titleid = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"id"]];
                goto foundtitle;
                
            }
        }
		//Test each title until it matches

	}
foundtitle:
	//Return the AniID
	return titleid;
}
-(BOOL)checkstatus:(NSString *)titleid {
	NSLog(@"Checking Status");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Set Search API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/anime/%@?mine=1",MALApiUrl, titleid]];
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
		// Initalize JSON parser
		NSDictionary *animeinfo = [response JSONValue];
		if ([animeinfo objectForKey:@"episodes"] == [NSNull null]) { // To prevent the scrobbler from failing because there is no episode total.
			TotalEpisodes = @"0"; // No Episode Total, Set to 0.
		}
		else { // Episode Total Exists
			TotalEpisodes = [animeinfo objectForKey:@"episodes"];
		}
		DetectedCurrentEpisode = [animeinfo objectForKey:@"watched_episodes"];
		// Watch Status
		if ([animeinfo objectForKey:@"watched_status"] == [NSNull null]) {
			NSLog(@"Not on List");
			WatchStatus = @"Nothing";
			TitleScore = @"0"; 
		}
		else {
			NSLog(@"Title on List");
			WatchStatus = [animeinfo objectForKey:@"watched_status"];
			if ([animeinfo objectForKey:@"score"] == [NSNull null]){
				// Score is null, set to 0
				TitleScore = @"0";
			}
			else {
				TitleScore = [animeinfo objectForKey:@"score"]; 
			}
			NSLog(@"Title Score %@", TitleScore);
			//Retain Title Score
		}
        LastScrobbledInfo = animeinfo;
		// Makes sure the values don't get released
		return YES;
	}
	else {
		// Some Error. Abort
		//Set up Delegate
		//
		//[appDelegate setStatusText:@"Scrobble Status: Scrobble Failed. Retrying in 5 mins..."];
		return NO;
	}
	//Should never happen, but...
	return NO;
}
-(int)updatetitle:(NSString *)titleid {
	NSLog(@"Updating Title");
	//Set up Delegate
	
	if ([DetectedEpisode intValue] <= [DetectedCurrentEpisode intValue] ) { 
		// Already Watched, no need to scrobble
        // Store Scrobbled Title and Episode
		LastScrobbledTitle = DetectedTitle;
		LastScrobbledEpisode = DetectedEpisode;
        return 1;
	}
	else {
		// Update the title
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		//Set library/scrobble API
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/animelist/anime/%@", MALApiUrl, titleid]];
		ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
		//Ignore Cookies
		[request setUseCookiePersistence:NO];
		//Set Token
		[request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"Basic %@",[defaults objectForKey:@"Base64Token"]]];
	    [request setRequestMethod:@"PUT"];
	    [request setPostValue:DetectedEpisode forKey:@"episodes"];
		//Set Status
		if([DetectedEpisode intValue] == [TotalEpisodes intValue]) {
			//Set Title State for Title (use for Twitter feature)
			WatchStatus = @"completed";
			// Since Detected Episode = Total Episode, set the status as "Complete"
			[request setPostValue:WatchStatus forKey:@"status"];
		}
		else {
			//Set Title State for Title (use for Twitter feature)
			WatchStatus = @"watching";
			// Still Watching
			[request setPostValue:WatchStatus forKey:@"status"];
		}	
		// Set existing score to prevent the score from being erased.
		[request setPostValue:TitleScore forKey:@"score"];
		// Do Update
		[request startSynchronous];
		
		// Store Scrobbled Title and Episode
		LastScrobbledTitle = DetectedTitle;
		LastScrobbledEpisode = DetectedEpisode;
		//NSLog(@"%i", [request responseStatusCode]);
		//NSLog(@"%@", [request responseString]);
		switch ([request responseStatusCode]) {
			case 200:
				// Update Successful
                return 22;
				break;
			default:
				// Update Unsuccessful

                return 53;
				break;
		}

	}
}
-(BOOL)addtitle:(NSString *)titleid {
	NSLog(@"Adding Title");
	//Set up Delegate
	
	// Add the title
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Set library/scrobble API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/animelist/anime", MALApiUrl]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
	//Set Token
	[request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"Basic %@",[defaults objectForKey:@"Base64Token"]]];
	[request setPostValue:titleid forKey:@"anime_id"];
	[request setPostValue:DetectedEpisode forKey:@"episodes"];
	[request setPostValue:@"watching" forKey:@"status"];	
	// Do Update
	[request startSynchronous];

	// Store Scrobbled Title and Episode
	LastScrobbledTitle = DetectedTitle;
	LastScrobbledEpisode = DetectedEpisode;
	
	//Set Title State for Title (use for Twitter feature)
	TitleState = @"started watching";
	WatchStatus = @"watching";
	NSLog(@"%i", [request responseStatusCode]);
	//NSLog(@"%@", [request responseString]);
	switch ([request responseStatusCode]) {
		case 200:
		case 201:
			// Update Successful
			return YES;
			break;
		default:
			// Update Unsuccessful

			return NO;
			break;
	}
}
-(BOOL)updatestatus:(NSString *)titleid
			 score:(int)showscore
	   watchstatus:(NSString*)showwatchstatus
{
	NSLog(@"Updating Status for %@", titleid);
	//Set up Delegate
	
	// Update the title
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Set library/scrobble API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/animelist/anime/%@", MALApiUrl, titleid]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
	//Set Token
	[request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"Basic %@",[defaults objectForKey:@"Base64Token"]]];
	[request setRequestMethod:@"PUT"];
	//Set current episode
	[request setPostValue:LastScrobbledEpisode forKey:@"episodes"];
	//Set new watch status
	[request setPostValue:showwatchstatus forKey:@"status"];	
	//Set new score.
	[request setPostValue:[NSString stringWithFormat:@"%i", showscore] forKey:@"score"];
	// Do Update
	[request startSynchronous];
	NSLog(@"%i", [request responseStatusCode]);
	//NSLog(@"%@", [request responseString]);
	switch ([request responseStatusCode]) {
		case 200:
			// Update Successful
			if ([TitleScore intValue] == showscore && [WatchStatus isEqualToString:showwatchstatus])
			{
				//Nothing changed, do nothing.
			}
			else {
			//Set New Values
			TitleScore = [NSString stringWithFormat:@"%i", showscore];
			WatchStatus = showwatchstatus;
                return true;
			break;
		default:
			// Update Unsuccessful
                return false;
			break;
	}
	
}
    return false;
}
-(NSDictionary *)getLastScrobbledInfo{
	return LastScrobbledInfo;
}
    
@end
