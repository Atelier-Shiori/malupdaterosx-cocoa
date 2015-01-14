//
//  MyAnimeList.m
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList.h"
#import "Recognition.h"
#import "EasyNSURLConnection.h"

@interface MyAnimeList ()
-(int)detectmedia; // 0 - Nothing, 1 - Same, 2 - Update
-(NSString *)searchanime;
-(NSString *)findaniid:(NSData *)ResponseData searchterm:(NSString *) term;
-(BOOL)checkstatus:(NSString *)titleid;
-(int)updatetitle:(NSString *)titleid confirming:(bool) confirming;
-(int)addtitle:(NSString *)titleid confirming:(bool) confirming;
-(NSString *)desensitizeSeason:(NSString *)title;
-(NSDictionary *)detectStream;
-(void)addtoCache:(NSString *)title showid:(NSString *)showid;
-(bool)checkifIgnored:(NSString *)filename;
@end

@implementation MyAnimeList
-(id)init{
    confirmed = true;
    return [super init];
}
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
-(NSString *)getLastScrobbledActualTitle{
    return LastScrobbledActualTitle;
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
-(int)getCurrentEpisode{
    return [DetectedCurrentEpisode intValue];
}
-(BOOL)getConfirmed{
    return confirmed;
}
-(BOOL)getisNewTitle{
    return LastScrobbledTitleNew;
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

    // 0 - nothing playing; 1 - same episode playing; 2 - No Update Needed; 3 - Confirm title before updating  21 - Add Title Successful; 22 - Update Title Successful;  51 - Can't find Title; 52 - Add Failed; 53 - Update Failed; 54 - Scrobble Failed;
    int detectstatus;
	//Set up Delegate
	
    detectstatus = [self detectmedia];
	if (detectstatus == 2) { // Detects Title
        return [self scrobble];
	}

    return detectstatus;
}
-(int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode{
	correcting = true;
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
            AniID = [self searchanime]; // Cache empty, search
        }
    }
    else {
        AniID = [self searchanime]; // Search Cache Disabled
    }
    if (AniID.length > 0) {
        NSLog(@"Found %@", AniID);
        // Check Status and Update
        BOOL UpdateBool = [self checkstatus:AniID];
        if (UpdateBool == 1) {
            if (LastScrobbledTitleNew) {
                //Title is not on list. Add Title
                int s = [self addtitle:AniID confirming:confirmed];
                if (s == 21 || s == 3){
                    Success = true;}
                else{
					Success = false;}
				status = s;
            }
            else {
                // Update Title as Usual
                int s = [self updatetitle:AniID confirming:confirmed];
                if (s == 2 || s == 3 ||s == 22 ) {
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
	
    // Release Detected Title/Episode.
    return status;

}
-(NSString *)searchanime{
	NSString * searchtitle;
    NSLog(@"Check Exceptions List");
    // Check Exceptions
    NSArray *exceptions = [[NSUserDefaults standardUserDefaults] objectForKey:@"exceptions"];
    if (exceptions.count > 0) {
        NSString * correcttitle;
        for (NSDictionary *d in exceptions) {
            NSString * title = [d objectForKey:@"detectedtitle"];
            if ([title isEqualToString:DetectedTitle]) {
                NSLog(@"%@ found on exceptions list as %@!", title, [d objectForKey:@"correcttitle"]);
                correcttitle = [d objectForKey:@"correcttitle"];
                break;
            }
        }
        if (correcttitle.length > 0) {
            searchtitle = correcttitle;
            // Remove Season to avoid conflicts
            DetectedSeason = 0;
        }
    }
    if (searchtitle.length == 0) {
        // Use detected title for search
        searchtitle = DetectedTitle;
    }
	NSLog(@"Searching For Title");
    // Set Season for Search Term if any detected.
    if (DetectedSeason > 1) {
        searchtitle = [NSString stringWithFormat:@"%@ %i season", [self desensitizeSeason:searchtitle], DetectedSeason];
    }
    //Escape Search Term
    NSString * searchterm = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (CFStringRef)searchtitle,
                                                                                                  NULL,
                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                  kCFStringEncodingUTF8 ));

	//Set Search API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/anime/search?q=%@",MALApiUrl, searchterm]];
	EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
	//Ignore Cookies
	[request setUseCookies:NO];
	//Perform Search
	[request startRequest];
	//Set up Delegate
	
	// Get Status Code
	int statusCode = [request getStatusCode];
	switch (statusCode) {
        case 0:
            online = false;
            Success = NO;
            return @"";
            break;
		case 200:
            online = true;
			return [self findaniid:[request getResponseData] searchterm:searchtitle];
			break;
			
		default:
            online = true;
			Success = NO;
			return @"";
			break;
	}
	
}
-(int)detectmedia {
	// LSOF mplayer to get the media title and segment

    NSArray * player = [NSArray arrayWithObjects:@"mplayer", @"mpv", @"mplayer-mt", @"VLC", @"QuickTime Playe", @"QTKitServer", @"Kodi", nil];
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
    OGRegularExpression    *regex = [OGRegularExpression regularExpressionWithString:@"^.+(avi|mkv|mp4|ogm|rm|rmvb|wmv|divx|mov|flv|mpg|3gp)$" options:OgreIgnoreCaseOption];
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
    //Check if thee file name or directory is on any ignore list
    BOOL onIgnoreList = [self checkifIgnored:string];
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
-(BOOL)confirmupdate{
    DetectedTitle = LastScrobbledTitle;
    DetectedEpisode = LastScrobbledEpisode;
    int status;
	if(LastScrobbledTitleNew)
	{
		status = [self addtitle:AniID confirming:true];
	}
	else{
		status = [self updatetitle:AniID confirming:true];
	}
    switch (status) {
        case 21:
        case 22:
            // Clear Detected Episode and Title
            DetectedTitle = nil;
            DetectedEpisode = nil;
            return true;
            break;
            
        default:
            return false;
            break;
    }
}
-(NSString *)findaniid:(NSData *)ResponseData searchterm:(NSString *)term{
	// Initalize JSON parser
    NSError* error;
    NSArray *searchdata = [NSJSONSerialization JSONObjectWithData:ResponseData options:kNilOptions error:&error];
    NSString *titleid = @"";
	//Initalize NSString to dump the title temporarily
	NSString *theshowtitle = @"";
    NSString *theshowtype = @"";
	//Set Regular Expressions to omit any preceding words
	NSString *findpre = [NSString stringWithFormat:@"(%@)",term];
    NSString *findinit = [NSString stringWithFormat:@"(%@)",term];
	findpre = [findpre stringByReplacingOccurrencesOfString:@" " withString:@"|"];
    OGRegularExpression    *regex;
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
    // Initalize Arrays for each Media Type
    NSMutableArray * movie = [[NSMutableArray alloc] init];
    NSMutableArray * tv = [[NSMutableArray alloc] init];
    NSMutableArray * ona = [[NSMutableArray alloc] init];
    NSMutableArray * ova = [[NSMutableArray alloc] init];
    NSMutableArray * special = [[NSMutableArray alloc] init];
    NSMutableArray * other = [[NSMutableArray alloc] init];
    // Organize Them
    for (NSDictionary *entry in searchdata) {
        theshowtype = [NSString stringWithFormat:@"%@", [entry objectForKey:@"type"]];
        if ([theshowtype isEqualToString:@"Movie"])
            [movie addObject:entry];
        else if ([theshowtype isEqualToString:@"TV"])
            [tv addObject:entry];
        else if ([theshowtype isEqualToString:@"ONA"])
            [ona addObject:entry];
        else if ([theshowtype isEqualToString:@"OVA"])
            [ova addObject:entry];
        else if ([theshowtype isEqualToString:@"Special"])
            [special addObject:entry];
        else if (![theshowtype isEqualToString:@"Music"])
            [other addObject:entry];
    }
    // Concatinate Arrays
    NSMutableArray * sortedArray;
    if (DetectedTitleisMovie) {
        sortedArray = [NSMutableArray arrayWithArray:movie];
        [sortedArray addObjectsFromArray:special];
    }
    else{
        sortedArray = [NSMutableArray arrayWithArray:tv];
        [sortedArray addObjectsFromArray:ona];
        [sortedArray addObjectsFromArray:special];
        [sortedArray addObjectsFromArray:ova];
        [sortedArray addObjectsFromArray:other];
    }
    // Search
    for (int i = 0; i < 2; i++) {
        switch (i) {
            case 0:
                regex = [OGRegularExpression regularExpressionWithString:findinit options:OgreIgnoreCaseOption];
                break;
            case 1:
                regex = [OGRegularExpression regularExpressionWithString:findpre options:OgreIgnoreCaseOption];
                break;
            default:
                break;
        }
    if (DetectedTitleisMovie) {
        //Check movies and Specials First
        for (NSDictionary *searchentry in sortedArray) {
        theshowtitle = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"title"]];
        if ([regex matchInString:theshowtitle] != nil) {
        }
            DetectedEpisode = @"1"; // Usually, there is one episode in a movie.
            if ([[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"type"]] isEqualToString:@"Special"]) {
                DetectedTitleisMovie = false;
            }
            //Return titleid
            titleid = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"id"]];
            goto foundtitle;
        }
    }
    // Check TV, ONA, Special, OVA, Other
    for (NSDictionary *searchentry in sortedArray) {
        theshowtitle = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"title"]];
        if ([regex matchInString:theshowtitle] != nil) {
            if ([[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"type"]] isEqualToString:@"TV"]) { // Check Seasons if the title is a TV show type
                // Used for Season Checking
                OGRegularExpression    *regex2 = [OGRegularExpression regularExpressionWithString:[NSString stringWithFormat:@"(%i(st|nd|rd|th) season|\\W%i)", DetectedSeason, DetectedSeason] options:OgreIgnoreCaseOption];
                OGRegularExpressionMatch * smatch = [regex2 matchInString:theshowtitle];
                if (DetectedSeason >= 2) { // Season detected, check to see if there is a matcch. If not, continue.
                    if (smatch == nil) {
                        continue;
                    }
                }
                else{
                    if (smatch != nil) { // No Season, check to see if there is a season or not. If so, continue.
                        continue;
                    }
                }
            }
            //Return titleid if episode is valid
            if ( [[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"episodes"]] intValue] == 0 || ([[NSString stringWithFormat:@"%@",[searchentry objectForKey:@"episodes"]] intValue] >= [DetectedEpisode intValue])) {
                NSLog(@"Valid Episode Count");
                titleid = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"id"]];
                goto foundtitle;
            }
            else{
                // Detected episodes exceed total episodes
                continue;
            }

        }
    }
    }
    foundtitle:
    //Check to see if Seach Cache is enabled. If so, add it to the cache.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"] && titleid.length > 0) {
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
	EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
	//Ignore Cookies
	[request setUseCookies:NO];
	//Set Token
	[request addHeader:[NSString stringWithFormat:@"Basic %@",[defaults objectForKey:@"Base64Token"]]  forKey:@"Authorization"];
	//Perform Search
	[request startRequest];
	// Get Status Code
	int statusCode = [request getStatusCode];
	if (statusCode == 200 ) {
        online = true;
        NSError* error;
		NSDictionary *animeinfo = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&error];
		if ([animeinfo objectForKey:@"episodes"] == [NSNull null]) { // To prevent the scrobbler from failing because there is no episode total.
			TotalEpisodes = @"0"; // No Episode Total, Set to 0.
		}
		else { // Episode Total Exists
			TotalEpisodes = [animeinfo objectForKey:@"episodes"];
		}
		// Watch Status
		if ([animeinfo objectForKey:@"watched_status"] == [NSNull null]) {
			NSLog(@"Not on List");
			LastScrobbledTitleNew = true;
			DetectedCurrentEpisode = @"0";
			TitleScore = @"0"; 
		}
		else {
			NSLog(@"Title on List");
			LastScrobbledTitleNew = false;
			WatchStatus = [animeinfo objectForKey:@"watched_status"];
			DetectedCurrentEpisode = [animeinfo objectForKey:@"watched_episodes"];
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
        // New Update Confirmation
        if (([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && LastScrobbledTitleNew)|| ([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !LastScrobbledTitleNew)) {
            // Manually confirm updates
            confirmed = false;
        }
        else{
            // Automatically confirm updates
            confirmed = true;
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
        online = true;
		// Some Error. Abort
		return NO;
	}
	//Should never happen, but...
	return NO;
}
-(int)updatetitle:(NSString *)titleid confirming:(bool)confirming{
	NSLog(@"Updating Title");
	
	if ([DetectedEpisode intValue] <= [DetectedCurrentEpisode intValue] ) { 
		// Already Watched, no need to scrobble
        // Store Scrobbled Title and Episode
        confirmed = true;
		LastScrobbledTitle = DetectedTitle;
		LastScrobbledEpisode = DetectedEpisode;
        LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",[LastScrobbledInfo objectForKey:@"title"]];
        return 2;
	}
	else if (!LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !confirmed && !correcting && !confirming) {
        // Confirm before updating title
        LastScrobbledTitle = DetectedTitle;
        LastScrobbledEpisode = DetectedEpisode;
        LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",[LastScrobbledInfo objectForKey:@"title"]];
        return 3;
    }
	else {
		// Update the title
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		//Set library/scrobble API
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/animelist/anime/%@", MALApiUrl, titleid]];
		EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
		//Ignore Cookies
		[request setUseCookies:NO];
		//Set Token
		[request addHeader:[NSString stringWithFormat:@"Basic %@",[defaults objectForKey:@"Base64Token"]]  forKey:@"Authorization"];
	    [request setPostMethod:@"PUT"];
	    [request addFormData:DetectedEpisode forKey:@"episodes"];
		//Set Status
		if([DetectedEpisode intValue] == [TotalEpisodes intValue]) {
			//Set Title State for Title (use for Twitter feature)
			WatchStatus = @"completed";
			// Since Detected Episode = Total Episode, set the status as "Complete"
			[request addFormData:WatchStatus forKey:@"status"];
		}
		else {
			//Set Title State for Title (use for Twitter feature)
			WatchStatus = @"watching";
			// Still Watching
			[request addFormData:WatchStatus forKey:@"status"];
		}	
		// Set existing score to prevent the score from being erased.
		[request addFormData:TitleScore forKey:@"score"];
		// Do Update
		[request startFormRequest];
		
		//NSLog(@"%i", [request getStatusCode]);
		//NSLog(@"%@", [request responseString]);
		switch ([request getStatusCode]) {
			case 200:
				// Store Last Scrobbled Title
		        LastScrobbledTitle = DetectedTitle;
		        LastScrobbledEpisode = DetectedEpisode;
                if (confirmed) {
                    LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",[LastScrobbledInfo objectForKey:@"title"]];
                }
                confirmed = true;
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
-(int)addtitle:(NSString *)titleid confirming:(bool)confirming{
	NSLog(@"Adding Title");
	//Check Confirm
    if (LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && !confirmed && !correcting && !confirming) {
        // Confirm before updating title
        LastScrobbledTitle = DetectedTitle;
        LastScrobbledEpisode = DetectedEpisode;
        LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",[LastScrobbledInfo objectForKey:@"title"]];
        return 3;
    }
	// Add the title
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Set library/scrobble API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/animelist/anime", MALApiUrl]];
	EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
	//Ignore Cookies
	[request setUseCookies:NO];
	//Set Token
	[request addHeader:[NSString stringWithFormat:@"Basic %@",[defaults objectForKey:@"Base64Token"]]  forKey:@"Authorization"];
	[request addFormData:titleid forKey:@"anime_id"];
	[request addFormData:DetectedEpisode forKey:@"episodes"];
	[request addFormData:@"watching" forKey:@"status"];	
	// Do Update
	[request startFormRequest];

	
	//Set Title State for Title (use for Twitter feature)
	TitleState = @"started watching";
	WatchStatus = @"watching";
	switch ([request getStatusCode]) {
		case 200:
		case 201:
			// Update Successful
		
		//Store last scrobbled information
        LastScrobbledTitle = DetectedTitle;
        LastScrobbledEpisode = DetectedEpisode;
            if (confirmed) {
                LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",[LastScrobbledInfo objectForKey:@"title"]];
            }
            confirmed = true;
			return 21;
			break;
		default:
			// Update Unsuccessful
		return 52;
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
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    [request addHeader:[NSString stringWithFormat:@"Basic %@",[defaults objectForKey:@"Base64Token"]]  forKey:@"Authorization"];
    //Set method to Delete
    [request setPostMethod:@"DELETE"];
    // Do Update
    [request startFormRequest];
    switch ([request getStatusCode]) {
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
	EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
	//Ignore Cookies
	[request setUseCookies:NO];
	//Set Token
	[request addHeader:[NSString stringWithFormat:@"Basic %@",[defaults objectForKey:@"Base64Token"]]  forKey:@"Authorization"];
	[request setPostMethod:@"PUT"];
	//Set current episode
	[request addFormData:LastScrobbledEpisode forKey:@"episodes"];
	//Set new watch status
	[request addFormData:showwatchstatus forKey:@"status"];	
	//Set new score.
	[request addFormData:[NSString stringWithFormat:@"%i", showscore] forKey:@"score"];
	// Do Update
	[request startFormRequest];
	switch ([request getStatusCode]) {
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
-(void)clearAnimeInfo{
    LastScrobbledInfo = nil;
}
-(NSString *)desensitizeSeason:(NSString *)title {
    // Get rid of season references
    OGRegularExpression* regex = [OGRegularExpression regularExpressionWithString: @"(Second Season|Third Season|Fourth Season|Fifth Season|Sixth Season|Seventh Season|Eighth Season|Nineth Season)" options:OgreIgnoreCaseOption];
    title = [regex replaceAllMatchesInString:title withString:@""];
    regex = [OGRegularExpression regularExpressionWithString: @"(s)\\d" options:OgreIgnoreCaseOption];
    title = [regex replaceAllMatchesInString:title withString:@""];
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
-(bool)checkifIgnored:(NSString *)filename{
    //Checks if file name or directory is on ignore list
    filename = [filename stringByReplacingOccurrencesOfString:@"n/" withString:@"/"];
    //Check ignore directories. If on ignore directory, set onIgnoreList to true.
    NSArray * ignoredirectories = [[NSUserDefaults standardUserDefaults] objectForKey:@"ignoreddirectories"];
    if ([ignoredirectories count] > 0) {
        for (NSDictionary * d in ignoredirectories) {
            if ([[OGRegularExpression regularExpressionWithString:[[NSString stringWithFormat:@"^(%@/)+", [d objectForKey:@"directory"]] stringByReplacingOccurrencesOfString:@"/" withString:@"\\/"] options:OgreIgnoreCaseOption] matchInString:filename]) {
                NSLog(@"Video being played is in ignored directory");
                return true;
                break;
            }
        }
    }
    // Get filename only
    filename = [[OGRegularExpression regularExpressionWithString:@"^.+/"] replaceAllMatchesInString:filename withString:@""];
    NSArray * ignoredfilenames = [[NSUserDefaults standardUserDefaults] objectForKey:@"IgnoreTitleRules"];
    if ([ignoredfilenames count] > 0) {
        for (NSDictionary * d in ignoredfilenames) {
            NSString * rule = [NSString stringWithFormat:@"%@", [d objectForKey:@"rule"]];
            if ([[OGRegularExpression regularExpressionWithString:rule options:OgreIgnoreCaseOption] matchInString:filename] && rule.length !=0) { // Blank rules are infinite, thus should not be counted
                NSLog(@"Video file name is on filename ignore list.");
                return true;
                break;
            }
        }
    }
    return false;
}

@end
