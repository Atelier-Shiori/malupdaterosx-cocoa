//
//  MyAnimeList.m
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList.h"
#import "EasyNSURLConnection.h"
#import "Detection.h"
#import "Utility.h"
#import "ExceptionsCache.h"

@interface MyAnimeList ()
-(int)detectmedia; // 0 - Nothing, 1 - Same, 2 - Update
-(NSString *)searchanime;
-(NSString *)performSearch:(NSString *)searchtitle;
-(NSString *)findaniid:(NSData *)ResponseData searchterm:(NSString *) term;
-(NSArray *)filterArray:(NSArray *)searchdata;
-(NSString *)foundtitle:(NSString *)titleid info:(NSDictionary *)found;
-(BOOL)checkstatus:(NSString *)titleid;
-(void)checkExceptions;

-(int)updatetitle:(NSString *)titleid confirming:(bool) confirming;
-(int)addtitle:(NSString *)titleid confirming:(bool) confirming;
@end

@implementation MyAnimeList
@synthesize managedObjectContext;
-(id)init{
    confirmed = true;
    return [super init];
}
-(void)setManagedObjectContext:(NSManagedObjectContext *)context{
    managedObjectContext = context;
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
-(NSString *)getLastScrobbledSource{
    return LastScrobbledSource;
}
-(NSString *)getFailedTitle{
    return FailedTitle;
}
-(NSString *)getFailedEpisode{
    return FailedEpisode;
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
    if (FailedSource == nil) {
        DetectedSource = LastScrobbledSource;
    }
    else{
        DetectedSource = FailedSource;
    }
    // Check Exceptions
    [self checkExceptions];
    // Scrobble and return status code
    return [self scrobble];
}
-(int)scrobble{
    NSLog(@"=============");
    NSLog(@"Scrobbling...");
    // Set MAL API URL
    MALApiUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"MALAPIURL"];
    int status;
    NSLog(@"Finding AniID");
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"]) {
        // Check Cache
        NSString *theid = [self checkCache];
        if (theid.length == 0)
            AniID = [self searchanime]; // Not in cache, search
        else
            AniID = theid; // Set cached show id as AniID
    }
    else {
        AniID = [self searchanime]; // Search Cache Disabled
    }
    if (AniID.length > 0) {
        NSLog(@"Found %@", AniID);
        // Nil out Failed Title and Episode
        FailedTitle = nil;
        FailedEpisode = nil;
        FailedSource = nil;
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
                NSLog(@"Error: Invalid Credentials.");
                status = 54;
            }
            else{
                NSLog(@"Error: User is offline.");
                //Ofline
                status = 55;
            }
        }
    }
    else {
        if (online) {
            // Not Successful
            NSLog(@"Error: Couldn't find title %@. Please add an Anime Exception rule.", DetectedTitle);
            // Used for Exception Adding
            FailedTitle = DetectedTitle;
            FailedEpisode = DetectedEpisode;
            FailedSource = DetectedSource;
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
    DetectedSource = nil;
    DetectedGroup = nil;
    DetectedSeason = 0;
    // Reset correcting Value
    correcting = false;
    NSLog(@"Scrobble Complete with Status Code: %i", status);
    NSLog(@"=============");
    // Release Detected Title/Episode.
    return status;

}
-(NSString *)searchanime{
    // Searches for ID of associated title
    NSString * searchtitle = DetectedTitle;
    if (DetectedSeason > 1) {
        // Specifically search for season
        for (int i = 0; i < 2; i++) {
            NSString * tmpid;
            switch (i) {
                case 0:
                    tmpid = [self performSearch:[NSString stringWithFormat:@"%@ %i", [Utility desensitizeSeason:searchtitle], DetectedSeason]];
                    break;
                case 1:
                    tmpid = [self performSearch:[NSString stringWithFormat:@"%@ %i season", [Utility desensitizeSeason:searchtitle], DetectedSeason]];
                default:
                    break;
            }
            if (tmpid.length > 0) {
                return tmpid;
            }
        }
    }
    else{
        return [self performSearch:searchtitle]; //Perform Regular Search
    }
    return [self performSearch:searchtitle];
}
-(NSString *)performSearch:(NSString *)searchtitle{
	NSLog(@"Searching For Title");
    //Escape Search Term
    NSString * searchterm = [Utility urlEncodeString:searchtitle];

	//Set Search API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/anime/search?q=%@",MALApiUrl, searchterm]];
	EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
	//Ignore Cookies
	[request setUseCookies:NO];
	//Perform Search
	[request startRequest];
	
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
    NSDictionary * result = [Detection detectmedia];
    if (result !=nil) {
        //Populate Data
        DetectedTitle = [result objectForKey:@"detectedtitle"];
        DetectedEpisode = [result objectForKey:@"detectedepisode"];
        DetectedSeason = [(NSNumber *)[result objectForKey:@"detectedseason"] intValue];
        DetectedGroup = [result objectForKey:@"group"];
        DetectedSource = [result objectForKey:@"detectedsource"];
        // Check if the title was previously scrobbled
        [self checkExceptions];
        
        if ([DetectedTitle isEqualToString:LastScrobbledTitle] && [DetectedEpisode isEqualToString: LastScrobbledEpisode] && Success == 1) {
            // Do Nothing
            return 1;
        }
        else {
            // Not Scrobbled Yet or Unsuccessful
            return 2;
        }
    }
    else{
        return 0;
    }
}
-(BOOL)confirmupdate{
    DetectedTitle = LastScrobbledTitle;
    DetectedEpisode = LastScrobbledEpisode;
    DetectedSource  = LastScrobbledSource;
    NSLog(@"=============");
    NSLog(@"Confirming: %@ - %@",LastScrobbledActualTitle, LastScrobbledEpisode);
    int status;
	if(LastScrobbledTitleNew)
	{
		status = [self addtitle:AniID confirming:true];
	}
	else{
		status = [self updatetitle:AniID confirming:true];
	}
    NSLog(@"Confirming process complete with status code: %i", status);
    switch (status) {
        case 21:
        case 22:
            // Clear Detected Episode and Title
            DetectedTitle = nil;
            DetectedEpisode = nil;
            DetectedSource = nil;
            return true;
            break;
            
        default:
            return false;
            break;
    }
}
-(NSString *)findaniid:(NSData *)ResponseData searchterm:(NSString *)term{
	// Initalize JSON parser and parse data
    NSError* error;
    NSArray *searchdata = [NSJSONSerialization JSONObjectWithData:ResponseData options:kNilOptions error:&error];
	//Initalize NSString to dump the title temporarily
	NSString *theshowtitle = @"";
    NSString *alttitle = @"";
	//Create Regular Expressions
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
    // Create a filtered Arrays
    NSArray * sortedArray = [self filterArray:searchdata];
    searchdata = nil;
    // Search
    for (int i = 0; i < 2; i++) {
        switch (i) {
            case 0:
                regex = [OGRegularExpression regularExpressionWithString:[NSString stringWithFormat:@"(%@)",term] options:OgreIgnoreCaseOption];
                break;
            case 1:
                regex = [OGRegularExpression regularExpressionWithString:[[NSString stringWithFormat:@"(%@)",term] stringByReplacingOccurrencesOfString:@" " withString:@"|"] options:OgreIgnoreCaseOption];
                break;
            default:
                break;
        }
    if (DetectedTitleisMovie) {
        //Check movies, specials and OVA
        for (NSDictionary *searchentry in sortedArray) {
            theshowtitle = (NSString *)[searchentry objectForKey:@"title"];
            //Populate Synonyms if any.
            if ([(NSDictionary *)[searchentry objectForKey:@"other_titles"] count] > 0) {
                if ([(NSDictionary *)[searchentry objectForKey:@"other_titles"] objectForKey:@"synonyms"] != nil) {
                    NSArray * a = [(NSDictionary *)[searchentry objectForKey:@"other_titles"] objectForKey:@"synonyms"];
                    for (NSString * synonym in a ) {
                        alttitle = [NSString stringWithFormat:@"- %@  %@", synonym, alttitle];
                    }
                }
            }
            else{alttitle = @"";}

        if ([Utility checkMatch:theshowtitle alttitle:alttitle regex:regex option:i]) {
        }
            DetectedEpisode = @"1"; // Usually, there is one episode in a movie.
            if ([[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"type"]] isEqualToString:@"Special"]||[[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"type"]] isEqualToString:@"OVA"]) {
                DetectedTitleisMovie = false;
            }
            //Return titleid
            return [self foundtitle:[NSString stringWithFormat:@"%@",[searchentry objectForKey:@"id"]] info:searchentry];
        }
    }
    // Check TV, ONA, Special, OVA, Other
    for (NSDictionary *searchentry in sortedArray) {
        theshowtitle = (NSString *)[searchentry objectForKey:@"title"];
        //Populate Synonyms if any.
        if ([(NSDictionary *)[searchentry objectForKey:@"other_titles"] count] > 0) {
            if ([(NSDictionary *)[searchentry objectForKey:@"other_titles"] objectForKey:@"synonyms"] != nil) {
                NSArray * a = [(NSDictionary *)[searchentry objectForKey:@"other_titles"] objectForKey:@"synonyms"];
                for (NSString * synonym in a ) {
                    alttitle = [NSString stringWithFormat:@"- %@  %@", synonym, alttitle];
                }
            }
        }
        else{alttitle = @"";}
        if ([Utility checkMatch:theshowtitle alttitle:alttitle regex:regex option:i]) {
            if ([[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"type"]] isEqualToString:@"TV"]) { // Check Seasons if the title is a TV show type
                // Used for Season Checking
                OGRegularExpression    *regex2 = [OGRegularExpression regularExpressionWithString:[NSString stringWithFormat:@"((%i(st|nd|rd|th)|%@) season|\\W%i)", DetectedSeason, [Utility seasonInWords:DetectedSeason],DetectedSeason] options:OgreIgnoreCaseOption];
                OGRegularExpressionMatch * smatch = [regex2 matchInString:[NSString stringWithFormat:@"%@ - %@",theshowtitle, alttitle]];
                // Description check
                OGRegularExpressionMatch * smatch2 = [regex2 matchInString:(NSString *)[searchentry objectForKey:@"synopsis"]];
                if (DetectedSeason >= 2) { // Season detected, check to see if there is a match. If not, continue.
                    if (smatch == nil && smatch2 == nil && [[sortedArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"TV"]] count] > 1) { // If there is a second season match, in most cases, it would be the only entry
                        continue;
                    }
                }
                else{
                    if (smatch != nil && smatch2 != nil && DetectedSeason >= 2) { // No Season, check to see if there is a season or not. If so, continue.
                        continue;
                    }
                }
            }
            //Return titleid if episode is valid
            if ( [[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"episodes"]] intValue] == 0 || ([[NSString stringWithFormat:@"%@",[searchentry objectForKey:@"episodes"]] intValue] >= [DetectedEpisode intValue])) {
                NSLog(@"Valid Episode Count");
                return [self foundtitle:[NSString stringWithFormat:@"%@",[searchentry objectForKey:@"id"]] info:searchentry];
            }
            else{
                // Detected episodes exceed total episodes
                continue;
            }

        }
    }
    }
	// Nothing found, return empty string
    return @"";
}
-(NSArray *)filterArray:(NSArray *)searchdata{
    NSMutableArray * sortedArray;
    if (DetectedTitleisMovie) {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)" , @"Movie"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Special"]]];
    }
    else{
        // Check if there is any type keywords. If so, only focus on that show type
        OGRegularExpression * check = [OGRegularExpression regularExpressionWithString:@"(Special|OVA|ONA)" options:OgreIgnoreCaseOption];
        if ([check matchInString:DetectedTitle]) {
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type LIKE %@)", [[check matchInString:DetectedTitle] matchedString]]]];
        }
        else{
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"TV"]]];
            [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"ONA"]]];
            if (DetectedSeason == 1 | DetectedSeason == 0) {
                [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Special"]]];
                [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"OVA"]]];
            }
        }
    }
    return sortedArray;
}
-(NSString *)foundtitle:(NSString *)titleid info:(NSDictionary *)found{
    //Check to see if Seach Cache is enabled. If so, add it to the cache.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"] && titleid.length > 0) {
        //Save AniID
        [ExceptionsCache addtoCache:DetectedTitle showid:titleid actualtitle:(NSString *)[found objectForKey:@"title"] totalepisodes:[(NSNumber *)[found objectForKey:@"episodes"] intValue] ];
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
    NSError * error = [request getError]; // Error Detection
	if (statusCode == 200 ) {
        online = true;
        if (DetectedEpisode.length == 0) { // Check if there is a DetectedEpisode (needed for checking
            // Set detected episode to 1
            DetectedEpisode = @"1";
        }
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
        if (([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && LastScrobbledTitleNew && !correcting)|| ([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !LastScrobbledTitleNew && !correcting)) {
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
    else if (error !=nil){
        if (error.code == NSURLErrorNotConnectedToInternet) {
            online = false;
            return NO;
        }
        else {
            online = true;
            return NO;
        }
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
        LastScrobbledActualTitle = (NSString *)[LastScrobbledInfo objectForKey:@"title"];
        LastScrobbledSource = DetectedSource;
        return 2;
	}
	else if (!LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !confirmed && !correcting && !confirming) {
        // Confirm before updating title
        LastScrobbledTitle = DetectedTitle;
        LastScrobbledEpisode = DetectedEpisode;
        LastScrobbledActualTitle = (NSString *)[LastScrobbledInfo objectForKey:@"title"];
        LastScrobbledSource = DetectedSource;
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
        
		switch ([request getStatusCode]) {
			case 200:
				// Store Last Scrobbled Title
		        LastScrobbledTitle = DetectedTitle;
		        LastScrobbledEpisode = DetectedEpisode;
                DetectedCurrentEpisode = DetectedEpisode;
                LastScrobbledSource = DetectedSource;
                if (confirmed) {
                    LastScrobbledActualTitle = (NSString *)[LastScrobbledInfo objectForKey:@"title"];
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
        LastScrobbledActualTitle = (NSString *)[LastScrobbledInfo objectForKey:@"title"];
        LastScrobbledSource = DetectedSource;
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

	
	//Set Title State for Title
	WatchStatus = @"watching";
	switch ([request getStatusCode]) {
		case 200:
		case 201:
			// Update Successful
		
		//Store last scrobbled information
        LastScrobbledTitle = DetectedTitle;
        LastScrobbledEpisode = DetectedEpisode;
        DetectedCurrentEpisode = DetectedEpisode;
		LastScrobbledSource = DetectedSource;
            if (confirmed) {
                LastScrobbledActualTitle = (NSString *)[LastScrobbledInfo objectForKey:@"title"];
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
            episode:(NSString*)episode
{
	NSLog(@"Updating Status for %@", titleid);
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
	[request addFormData:episode forKey:@"episodes"];
	//Set new watch status
	[request addFormData:showwatchstatus forKey:@"status"];	
	//Set new score.
	[request addFormData:[NSString stringWithFormat:@"%i", showscore] forKey:@"score"];
	// Do Update
	[request startFormRequest];
	switch ([request getStatusCode]) {
		case 200:
			// Update Successful
                //Set New Values
                TitleScore = [NSString stringWithFormat:@"%i", showscore];
                WatchStatus = showwatchstatus;
                LastScrobbledEpisode = episode;
                DetectedCurrentEpisode = episode;
                confirmed = true;
                return true;
			break;
		default:
			// Update Unsuccessful
                return false;
			break;
	}
}
-(NSDictionary *)getLastScrobbledInfo{
	return LastScrobbledInfo;
}
-(void)clearAnimeInfo{
    LastScrobbledInfo = nil;
}
-(NSString *)checkCache{
    NSManagedObjectContext *moc = managedObjectContext;
    NSFetchRequest * allCaches = [[NSFetchRequest alloc] init];
    [allCaches setEntity:[NSEntityDescription entityForName:@"Cache" inManagedObjectContext:moc]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"detectedTitle == %@", DetectedTitle];
    [allCaches setPredicate:predicate];
    NSError * error = nil;
    NSArray * cache = [moc executeFetchRequest:allCaches error:&error];
    if (cache.count > 0) {
        for (NSManagedObject * cacheentry in cache) {
            NSString * title = [cacheentry valueForKey:@"detectedTitle"];
            if ([title isEqualToString:DetectedTitle]) {
                NSLog(@"%@ is found in cache.", title);
                // Total Episode check
                NSNumber * totalepisodes = [cacheentry valueForKey:@"totalEpisodes"];
                if ( [DetectedEpisode intValue] <= totalepisodes.intValue || totalepisodes.intValue == 0 ) {
                    return [cacheentry valueForKey:@"id"];
                }
            }
        }
    }
    return @"";
}
-(void)checkExceptions{
    // Check Exceptions
    NSManagedObjectContext * moc = self.managedObjectContext;
	bool found = false;
	NSPredicate *predicate;
    for (int i = 0; i < 2; i++) {
        NSFetchRequest * allExceptions = [[NSFetchRequest alloc] init];
        NSError * error = nil;
        if (i == 0) {
            NSLog(@"Check Exceptions List");
            [allExceptions setEntity:[NSEntityDescription entityForName:@"Exceptions" inManagedObjectContext:moc]];
			predicate = [NSPredicate predicateWithFormat: @"detectedTitle == %@", DetectedTitle];
        }
        else if (i== 1 && [[NSUserDefaults standardUserDefaults] boolForKey:@"UseAutoExceptions"]){
                NSLog(@"Checking Auto Exceptions");
                [allExceptions setEntity:[NSEntityDescription entityForName:@"AutoExceptions" inManagedObjectContext:moc]];
				predicate = [NSPredicate predicateWithFormat: @"(detectedTitle == %@) AND (group == %@)", DetectedTitle, DetectedGroup];
        }
        else{break;}
		// Set Predicate and filter exceiptions array
        [allExceptions setPredicate:predicate];
        NSArray * exceptions = [moc executeFetchRequest:allExceptions error:&error];
        if (exceptions.count > 0) {
            NSString * correcttitle;
            for (NSManagedObject * entry in exceptions) {
                if ([DetectedTitle isEqualToString:(NSString *)[entry valueForKey:@"detectedTitle"]]) {
                    correcttitle = (NSString *)[entry valueForKey:@"correctTitle"];
                    // Set Correct Title and Episode offset (if any)
                    int threshold = [(NSNumber *)[entry valueForKey:@"episodethreshold"] intValue];
                    int offset = [(NSNumber *)[entry valueForKey:@"episodeOffset"] intValue];
                    int tmpepisode = [DetectedEpisode intValue] - offset;
                    if ((tmpepisode > threshold && threshold != 0) || tmpepisode <= 0) {
                        continue;
                    }
                    else {
                        NSLog(@"%@ is found on exceptions list as %@.", DetectedTitle, correcttitle);
                        DetectedTitle = correcttitle;
                        if (tmpepisode > 0) {
                            DetectedEpisode = [NSString stringWithFormat:@"%i", tmpepisode];
                        }
                        DetectedSeason = 0;
                        found = true;
						break;
                    }
                }
            }
            if (found){break;} //Break from exceptions check loop
        }
    }
}
@end
