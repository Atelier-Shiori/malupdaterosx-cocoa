//
//  MyAnimeList.m
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList.h"
#import "Recognition.h"

@interface MyAnimeList ()
-(int)detectmedia; // 0 - Nothing, 1 - Same, 2 - Update
-(NSString *)searchanime;
-(NSString *)findaniid:(NSData *)ResponseData;
-(BOOL)checkstatus:(NSString *)titleid;
-(int)updatetitle:(NSString *)titleid;
-(BOOL)addtitle:(NSString *)titleid;
-(int)recognizeSeason:(NSString *)season;
-(NSString *)desensitizeSeason:(NSString *)title;
-(NSDictionary *)detectStream;
@end

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
    int detectstatus;
	//Set up Delegate
	
    detectstatus = [self detectmedia];
	if (detectstatus == 2) { // Detects Title
        return [self scrobble];
	}

    return detectstatus;
}
-(int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode{
    DetectedTitle = showtitle;
    DetectedEpisode = episode;
    return [self scrobble];
}
-(int)scrobble{
    // Set MAL API URL
    MALApiUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"MALAPIURL"];
    int status;
    NSLog(@"Getting AniID");
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"]) {
        NSArray *cache = [[NSUserDefaults standardUserDefaults] objectForKey:@"searchcache"];
        if (cache.count > 0) {
            NSString * theid;
            for (NSDictionary *d in cache) {
                NSString * title = [d objectForKey:@"detectedtitle"];
                if ([title isEqualToString:DetectedTitle]) {
                    NSLog(@"%@ found in cache!", title);
                    theid = [d objectForKey:@"showid"];
                    break;
                }
            }
            if (theid.length == 0) {
                AniID = [self searchanime]; // Not in cache, search
            }
            else{
                AniID = theid; // Set cached show id as AniID
            }
        }
        else {
            AniID = [self searchanime];
        }
    }
    else {
        AniID = [self searchanime];
    }
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
        }
        else{
            if (online) {
                status = 54;
            }
            else{
                //Ofline
                status = 55;
            }
        }
    }
    else {
        if (online) {
            // Not Successful
            status = 51;
        }
        else{
            //Offline
            status = 55;
        }
        
    }
    // Empty out Detected Title/Episode to prevent same title detection
    DetectedTitle = nil;
    DetectedEpisode = nil;
    DetectedCurrentEpisode = nil;
    // Release Detected Title/Episode.
    return status;

}
-(NSString *)searchanime{
    NSLog(@"Check Exceptions List");
    // Check Exceptions
    NSArray *exceptions = [[NSUserDefaults standardUserDefaults] objectForKey:@"exceptions"];
    if (exceptions.count > 0) {
        NSString * theid;
        for (NSDictionary *d in exceptions) {
            NSString * title = [d objectForKey:@"detectedtitle"];
            if ([title isEqualToString:DetectedTitle]) {
                NSLog(@"%@ found on exceptions list as %@!", title, [d objectForKey:@"correcttitle"]);
                theid = [d objectForKey:@"showid"];
                break;
            }
        }
        if (theid.length > 0) {
            return theid;
        }
    }
	NSLog(@"Searching For Title");
    // Set Season for Search Term if any detected.
    NSString * searchtitle;
    if (DetectedSeason > 1) {
        searchtitle = [NSString stringWithFormat:@"%@ %i season", [self desensitizeSeason:DetectedTitle], DetectedSeason];
    }
    else
        searchtitle = DetectedTitle;
    //Escape Search Term
    NSString * searchterm = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (CFStringRef)searchtitle,
                                                                                                  NULL,
                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                  kCFStringEncodingUTF8 ));

	//Set Search API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/anime/search?q=%@",MALApiUrl, searchterm]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
	//Perform Search
	[request startSynchronous];
	//Set up Delegate
	
	// Get Status Code
	int statusCode = [request responseStatusCode];
	switch (statusCode) {
        case 0:
            online = false;
            Success = NO;
            return @"";
            break;
		case 200:
			return [self findaniid:[request responseData]];
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
    
    NSArray * player = [NSArray arrayWithObjects:@"mplayer", @"mpv", @"mplayer-mt", @"VLC", @"QuickTime Playe", @"QTKitServer", nil];
    NSString *string;
    
    for(int i = 0; i <[player count]; i++){
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
    OGRegularExpression    *regex = [OGRegularExpression regularExpressionWithString:@"^.+(avi|mkv|mp4|ogm)$"];
    if (string.length > 0) {
        //Regex time
        //Get the filename first
        NSEnumerator    *enumerator;
        enumerator = [regex matchEnumeratorInString:string];
        OGRegularExpressionMatch    *match;
        while ((match = [enumerator nextObject]) != nil) {
            string = [match matchedString];
        }
    }
    //Check ignore directories. If on ignore directory, set onIgnoreList to true.
    NSArray * ignoredirectories = [[NSUserDefaults standardUserDefaults] objectForKey:@"ignoreddirectories"];
    BOOL onIgnoreList = false;
    if ([ignoredirectories count] > 0) {
        for (NSDictionary * d in ignoredirectories) {
            OGRegularExpression    *regex2 = [OGRegularExpression regularExpressionWithString:[[NSString stringWithFormat:@"(%@)", [d objectForKey:@"directory"]] stringByReplacingOccurrencesOfString:@"/" withString:@"\\/"]];
            if ([regex2 matchInString:string]) {
                NSLog(@"Video being played is in ignored directory");
                onIgnoreList = true;
                break;
            }
        }
    }
    //Make sure the file name is valid, even if player is open. Do not update video files in ignored directories
    if ([regex matchInString:string] !=nil && !onIgnoreList) {
        NSDictionary *d = [[Recognition alloc] recognize:string];
        DetectedTitle = [NSString stringWithFormat:@"%@", [d objectForKey:@"title"]];
        DetectedEpisode = [NSString stringWithFormat:@"%@", [d objectForKey:@"episode"]];
        DetectedSeason = [[d objectForKey:@"season"] intValue];
        goto update;
    }
    else {
        NSLog(@"Checking Stream...");
        NSDictionary * detected = [self detectStream];
        
        if ([detected objectForKey:@"result"]  == [NSNull null]){ // Check to see if anything is playing on stream
            return 0;
        }
        else{
            NSArray * c = [detected objectForKey:@"result"];
            NSDictionary * d = [c objectAtIndex:0];
            DetectedTitle = [NSString stringWithFormat:@"%@",[d objectForKey:@"title"]];
            DetectedEpisode = [NSString stringWithFormat:@"%@",[d objectForKey:@"episode"]];
            goto update;
        }
        // Nothing detected
    }
update:
    // Check if the title was previously scrobbled
    if ([DetectedTitle isEqualToString:LastScrobbledTitle] && [DetectedEpisode isEqualToString: LastScrobbledEpisode] && Success == 1) {
        // Do Nothing
        return 1;
    }
    else {
        // Not Scrobbled Yet or Unsuccessful
        return 2;
    }
}
-(NSString *)findaniid:(NSData *)ResponseData {
	// Initalize JSON parser
    NSError* error;
    NSArray *searchdata = [NSJSONSerialization JSONObjectWithData:ResponseData options:kNilOptions error:&error];
    NSString *titleid = @"";
	//Initalize NSString to dump the title temporarily
	NSString *theshowtitle = @"";
    NSString *theshowtype = @"";
	//Set Regular Expressions to omit any preceding words
	NSString *findpre = [NSString stringWithFormat:@"(%@)",DetectedTitle];
	findpre = [findpre stringByReplacingOccurrencesOfString:@" " withString:@"|"]; // NSString *findpre = [NSString stringWithFormat:@"^%@",DetectedTitle];
	OGRegularExpression    *regex = [OGRegularExpression regularExpressionWithString:findpre options:OgreIgnoreCaseOption];
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
    //Check to see if Seach Cache is enabled. If so, add it to the cache.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"]) {
        //Save AniID
        [self addtoCache:DetectedTitle showid:titleid];
    }
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
	if (statusCode == 200 ) {
        NSError* error;
		NSDictionary *animeinfo = [NSJSONSerialization JSONObjectWithData:[request responseData] options:kNilOptions error:&error];
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
    else if (statusCode == 0){
        online = false;
        return NO;
    }
	else {
		// Some Error. Abort
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
-(bool)removetitle:(NSString *)titleid{
    NSLog(@"Removing %@", titleid);
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
    //Set method to Delete
    [request setRequestMethod:@"DELETE"];
    // Do Update
    [request startSynchronous];
    switch ([request responseStatusCode]) {
        case 200:
        case 201:
            return true;
            break;
        default:
            // Update Unsuccessful
            return false;
            break;
    }
    return false;
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
-(NSDictionary *)detectStream{
    // Create Dictionary
    NSDictionary * d;
    //Set detectream Task and Run it
    NSTask *task;
    task = [[NSTask alloc] init];
    NSBundle *myBundle = [NSBundle mainBundle];
    [task setLaunchPath:[myBundle pathForResource:@"detectstream" ofType:@""]];
    
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    // Reads Output
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    // Launch Task
    [task launch];
    
    // Parse Data from JSON and return dictionary
    NSData *data;
    data = [file readDataToEndOfFile];
    
    
    NSError* error;
    
    d = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    return d;
}
-(int)recognizeSeason:(NSString *)season{
    if ([season caseInsensitiveCompare:@"second season"] == NSOrderedSame)
        return 2;
    else if ([season caseInsensitiveCompare:@"third season"] == NSOrderedSame)
        return 3;
    else if ([season caseInsensitiveCompare:@"fourth season"] == NSOrderedSame)
        return 4;
    else if ([season caseInsensitiveCompare:@"fifth season"] == NSOrderedSame)
        return 5;
    else if ([season caseInsensitiveCompare:@"sixth season"] == NSOrderedSame)
        return 6;
    else if ([season caseInsensitiveCompare:@"seventh season"] == NSOrderedSame)
        return 7;
    else if ([season caseInsensitiveCompare:@"eighth season"] == NSOrderedSame)
        return 8;
    else if ([season caseInsensitiveCompare:@"ninth season"] == NSOrderedSame)
        return 9;
    else
        return 0;
}
-(NSString *)desensitizeSeason:(NSString *)title {
    // Get rid of season references
    OGRegularExpression* regex = [OGRegularExpression regularExpressionWithString: @"(Second Season|Third Season|Fourth Season|Fifth Season|Sixth Season|Seventh Season|Eighth Season|Nineth Season)"];
    title = [regex replaceAllMatchesInString:title withString:@"" options:OgreIgnoreCaseOption];
    regex = [OGRegularExpression regularExpressionWithString: @"(s|S)\\d"];
    title = [regex replaceAllMatchesInString:title withString:@"" options:OgreIgnoreCaseOption];
    // Remove any Whitespace
    title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return title;
}

-(void)addtoCache:(NSString *)title showid:(NSString *)showid{
    //Adds ID to cache
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *cache = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"searchcache"]];
    NSDictionary * entry = [[NSDictionary alloc] initWithObjectsAndKeys:title, @"detectedtitle", showid, @"showid", nil];
    [cache addObject:entry];
    [defaults setObject:cache forKey:@"searchcache"];
}
@end
