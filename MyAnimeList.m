//
//  MyAnimeList.m
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 MAL Updater OS X Group. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList.h"
#import <DetectionKit/DetectionKit.h>
#import <TwitterManagerKit/TwitterManagerKit.h>
#import "MyAnimeList+Search.h"
#import "MyAnimeList+Update.h"
#import "MyAnimeList+Keychain.h"
#import <Reachability/Reachability.h>
#import "Utility.h"
#import "TwitterConstants.h"

@interface MyAnimeList ()
- (int)detectmedia; // 0 - Nothing, 1 - Same, 2 - Update
- (void)checkExceptions;
@end

@implementation MyAnimeList
@synthesize managedObjectContext;
- (id)init {
    _confirmed = true;
    [self setupnotifier];
    //Set up Kodi Reachability
    _detection = [Detection new];
    [_detection setKodiReach:[[NSUserDefaults standardUserDefaults] boolForKey:@"enablekodiapi"]];
    [_detection setPlexReach:[[NSUserDefaults standardUserDefaults] boolForKey:@"enableplexapi"]];
    // Init Twitter Manager
    self.twittermanager = [[TwitterManager alloc] initWithConsumerKeyUsingFirstAccount:kConsumerKey withConsumerSecret:kConsumerSecret];
    // Init Discord
    self.discordmanager = [DiscordManager new];
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"usediscordrichpresence"]) {
        [self.discordmanager startDiscordRPC];
    }
    // init AFNetworking
    _syncmanager = [AFHTTPSessionManager manager];
    _syncmanager.completionQueue = dispatch_queue_create("AFNetworking+Synchronous", NULL);
    _asyncmanager = [AFHTTPSessionManager manager];
    _syncmanager.responseSerializer = [AFJSONResponseSerializer serializer];
    _asyncmanager.responseSerializer = [AFJSONResponseSerializer serializer];
    // Return Object
    return [super init];
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)context{
    managedObjectContext = context;
}
/* 
 
 Accessors
 
 */
- (int)getWatchStatus
{
    if ([_WatchStatus isEqualToString:@"watching"]) {
        return 0;
    }
    else if ([_WatchStatus isEqualToString:@"completed"]) {
        return 1;
    }
    else if ([_WatchStatus isEqualToString:@"on_hold"]) {
        return 2;
    }
    else if ([_WatchStatus isEqualToString:@"dropped"]) {
        return 3;
    }
    else if ([_WatchStatus isEqualToString:@"plan_to_watch"]) {
        return 4;
    }
    else {
        return 0; //fallback
    }
}
- (int)getQueueCount{
    __block int count = 0;
    NSManagedObjectContext *moc = self.managedObjectContext;
    [moc performBlockAndWait:^{
        NSError *error;
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(scrobbled == %i) AND (status == %i)", false, 23];
        NSFetchRequest *queuefetch = [[NSFetchRequest alloc] init];
        queuefetch.entity = [NSEntityDescription entityForName:@"OfflineQueue" inManagedObjectContext:moc];
        queuefetch.predicate = predicate;
        NSArray *queue = [moc executeFetchRequest:queuefetch error:&error];
        count = (int)queue.count;
    }];
    return count;
}
/*
 
 Update Methods
 
 */

- (int)startscrobbling {
    // Detect media
    int detectstatus;
    detectstatus = [self detectmedia];
    if (detectstatus == ScrobblerDetectedMedia) { // Detects Title
        if (_online) {
            int result = [self scrobble];
            // Empty out Detected Title/Episode to prevent same title detection
            _DetectedTitle = nil;
            _DetectedEpisode = nil;
            _DetectedSource = nil;
            _DetectedGroup = nil;
            _DetectedType = nil;
            _DetectedSeason = 0;
            // Reset correcting Value
            _correcting = false;
            return result;
        }
        else {
            __block NSError *error;
            if (![self checkifexistinqueue]) {
                // Store in offline queue
                [managedObjectContext performBlockAndWait:^{
                    NSManagedObject *obj = [NSEntityDescription
                                            insertNewObjectForEntityForName:@"OfflineQueue"
                                            inManagedObjectContext: managedObjectContext];
                    // Set values in the new record
                    [obj setValue:_DetectedTitle forKey:@"detectedtitle"];
                    [obj setValue:_DetectedEpisode forKey:@"detectedepisode"];
                    [obj setValue:_DetectedType forKey:@"detectedtype"];
                    [obj setValue:_DetectedSource forKey:@"source"];
                    [obj setValue:@(_DetectedSeason) forKey:@"detectedseason"];
                    [obj setValue:@(_DetectedTitleisMovie) forKey:@"ismovie"];
                    [obj setValue:@(_DetectedTitleisEpisodeZero) forKey:@"iszeroepisode"];
                    [obj setValue:@23 forKey:@"status"];
                    [obj setValue:@(true) forKey:@"scrobbled"];
                    //Save
                    [managedObjectContext save:&error];
                }];
            }
            // Store Last Scrobbled Title
            _LastScrobbledTitle = _DetectedTitle;
            _LastScrobbledEpisode = _DetectedEpisode;
            _DetectedCurrentEpisode = _DetectedEpisode.intValue;
            _LastScrobbledSource = _DetectedSource;
            _LastScrobbledActualTitle = _DetectedTitle;
            _confirmed = true;
            // Reset Detected Info
            _DetectedTitle = nil;
            _DetectedEpisode = nil;
            _DetectedSource = nil;
            _DetectedGroup = nil;
            _DetectedType = nil;
            _DetectedSeason = 0;
            _Success = true;
            return ScrobblerOfflineQueued;
        }
    }
    else {
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"usediscordrichpresence"] && self.discordmanager.discordrpcrunning) {
            [_discordmanager removePresence];
        }
    }

    return detectstatus;
}
- (NSDictionary *)scrobblefromqueue {
    // Restore Detected Media
    __block NSError *error;
    NSManagedObjectContext *moc = self.managedObjectContext;
    __block NSArray *queue;
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(scrobbled == %i) AND ((status == %i) OR (status == %i))", false, 23, 3];
    NSFetchRequest *queuefetch = [[NSFetchRequest alloc] init];
    queuefetch.entity = [NSEntityDescription entityForName:@"OfflineQueue" inManagedObjectContext:moc];
    queuefetch.predicate = predicate;
    [moc performBlockAndWait:^{
        queue = [moc executeFetchRequest:queuefetch error:&error];
    }];
    int successc = 0;
    int fail = 0;
    bool confirmneeded = false;
    if (queue.count > 0) {
        for (NSManagedObject *item in queue) {
            // Restore detected title and episode from coredata
            _DetectedTitle = [item valueForKey:@"detectedtitle"];
            _DetectedEpisode = [item valueForKey:@"detectedepisode"];
            _DetectedSource = [item valueForKey:@"source"];
            _DetectedType = [item valueForKey:@"detectedtype"];
            _DetectedSeason = [[item valueForKey:@"detectedseason"] intValue];
            _DetectedTitleisMovie = [[item valueForKey:@"ismovie"] boolValue];
            _DetectedTitleisEpisodeZero = [[item valueForKey:@"iszeroepisode"] boolValue];
            int result = [self scrobble];
            bool scrobbled;
            NSManagedObject *record = [self checkifexistinqueue];
            // Record Results
            [record setValue:@(result) forKey:@"status"];
            switch (result) {
                case ScrobblerTitleNotFound:
                case ScrobblerAddTitleFailed:
                case ScrobblerUpdateFailed:
                case ScrobblerFailed:
                case ScrobblerMALUpdaterOSXNeedsUpdate:
                case ScrobblerInvalidCredentials:
                    fail++;
                    scrobbled = false;
                    break;
                case ScrobblerConfirmNeeded:
                    successc++;
                    scrobbled = true;
                    break;
                default:
                    successc++;
                    scrobbled = true;
                    break;
            }
            [record setValue:@(scrobbled) forKey:@"scrobbled"];
            [moc performBlockAndWait:^{
                [moc save:&error];
            }];
            
            //Save
            if (result == ScrobblerConfirmNeeded) {
                confirmneeded = true;
                break;
            }
        }
    }
    if (successc > 0) {
        _Success = true;
    }
    return @{@"success": @(successc), @"fail": @(fail), @"confirmneeded" : @(confirmneeded)};
}
- (int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode correctonce:(BOOL)correctonce {
    _correcting = true;
    NSString *lasttitle;
    if (correctonce) {
        lasttitle = _LastScrobbledTitle;
    }
    _DetectedTitle = showtitle;
    _DetectedEpisode = episode;
    _DetectedSeason = _FailedSeason;
    if (!_FailedSource) {
        _DetectedSource = _LastScrobbledSource;
    }
    else {
        _DetectedSource = _FailedSource;
    }
    // Check Exceptions
    [self checkExceptions];
    // Scrobble and return status code
    int status = [self scrobble];
    if (correctonce) {
        _LastScrobbledTitle = lasttitle; //Set the Last Scrobbled Title to exact title.
    }
    return status;
}
- (int)performscrobbletest:(NSString *)filename delete:(bool)deletetitle{
    NSDictionary *result = [[Recognition alloc] recognize:filename];
    //Populate Data
    _DetectedTitle = result[@"title"];
    _DetectedEpisode = result[@"episode"];
    _DetectedSeason = ((NSNumber *)result[@"season"]).intValue;
    _DetectedGroup = result[@"group"];
    _DetectedSource = @"Test";
    if (((NSArray *)result[@"types"]).count > 0) {
        _DetectedType = (result[@"types"])[0];
    }
    else {
        _DetectedType = @"";
    }
    // Check for Episode 0 titles
    [self checkzeroEpisode];
    // Check Exceptions
    [self checkExceptions];

    int status = [self scrobble];
    if (deletetitle) {
        [self removetitle:_AniID];
    }
    return status;
}
- (int)scrobble{
    NSLog(@"=============");
    NSLog(@"Scrobbling...");
    // Set MAL API URL
    _MALApiUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"MALAPIURL"];
    int status;
    NSLog(@"Finding AniID");
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"]) {
        // Check Cache
        NSString *theid = [self checkCache];
        if (theid.length == 0) {
            // Search for title
            _AniID = [self startSearch];
        }
           
        else {
            _AniID = theid; // Set cached show id as AniID
            //If Detected Episode is missing, set it to 1 for sanity
            if (_DetectedEpisode.length == 0) {
                _DetectedEpisode = @"1";
            }
        }
    }
    else {
        _AniID = [self startSearch]; //Search Cache Disabled
    }
    if (_AniID.length > 0) {
        NSLog(@"Found %@", _AniID);
        // Nil out Failed Title and Episode
        _FailedTitle = nil;
        _FailedEpisode = nil;
        _FailedSource = nil;
        _FailedSeason = 0;
        // Check Status and Update
        BOOL UpdateBool = [self checkstatus:_AniID];
        if (UpdateBool == 1) {
            if (_LastScrobbledTitleNew) {
                //Title is not on list. Add Title
                int s = [self addtitle:_AniID confirming:_confirmed];
                _Success = s == ScrobblerAddTitleSuccessful || s == ScrobblerConfirmNeeded ? true : false;
                status = s;
            }
            else {
                // Update Title as Usual
                int s = [self updatetitle:_AniID confirming:_confirmed];
                _Success = s == ScrobblerUpdateNotNeeded || s == ScrobblerConfirmNeeded ||s == ScrobblerUpdateSuccessful ? true : false;
                status = s;
                
            }
        }
        else {
            if (_online) {
                NSLog(@"Error: User needs to update MAL Updater OS X");
                status = ScrobblerMALUpdaterOSXNeedsUpdate;
            }
            else {
                NSLog(@"Error: User is offline.");
                //Ofline
                status = ScrobblerFailed;
            }
        }
    }
    else {
        if (_online) {
            // Not Successful
            NSLog(@"Error: Couldn't find title %@. Please add an Anime Exception rule.", _DetectedTitle);
            // Used for Exception Adding
            _FailedTitle = _DetectedTitle;
            _FailedEpisode = _DetectedEpisode;
            _FailedSource = _DetectedSource;
            _FailedSeason = _DetectedSeason;
            status = ScrobblerTitleNotFound;
        }
        else {
            //Offline
            status = ScrobblerFailed;
        }
        
    }
    // Reset correcting Value
    _correcting = false;
    NSLog(@"Scrobble Complete with Status Code: %i", status);
    NSLog(@"=============");
    // Release Detected Title/Episode.
    return status;

}
- (int)detectmedia {
    NSDictionary *result = [_detection detectmedia];
    if (result != nil) {
        //Populate Data
        _DetectedTitle = result[@"detectedtitle"];
        _DetectedEpisode = result[@"detectedepisode"];
        _DetectedSeason = ((NSNumber *)result[@"detectedseason"]).intValue;
        _DetectedGroup = result[@"group"];
        _DetectedSource = result[@"detectedsource"];
        if (((NSArray *)result[@"types"]).count > 0) {
            _DetectedType = (result[@"types"])[0];
        }
        else {
            _DetectedType = @"";
        }
        // Check for Episode 0 titles
        [self checkzeroEpisode];
        // Check if the title was previously scrobbled
        [self checkExceptions];
        
        if ([_DetectedTitle isEqualToString:_LastScrobbledTitle] && ([_DetectedEpisode isEqualToString: _LastScrobbledEpisode]||[self checkBlankDetectedEpisode]) && _Success == 1) {
            // Do Nothing
            return 1;
        }
        else {
            // Not Scrobbled Yet or Unsuccessful
            return ScrobblerDetectedMedia;
        }
    }
    else {
        return ScrobblerNothingPlaying;
    }
}
- (int)populatevalues:(NSDictionary *) result{
    if (result !=nil) {
        //Populate Data
        _DetectedTitle = result[@"detectedtitle"];
        _DetectedEpisode = result[@"detectedepisode"];
        _DetectedSeason = ((NSNumber *)result[@"detectedseason"]).intValue;
        _DetectedGroup = result[@"group"];
        _DetectedSource = result[@"detectedsource"];
        if (((NSArray *)result[@"types"]).count > 0) {
            _DetectedType = (result[@"types"])[0];
        }
        else {
            _DetectedType = @"";
        }
        //Check for zero episode as the detected episode
        [self checkzeroEpisode];
        // Check if the title was previously scrobbled
        [self checkExceptions];
        if ([_DetectedTitle isEqualToString:_LastScrobbledTitle] && ([_DetectedEpisode isEqualToString: _LastScrobbledEpisode]||[self checkBlankDetectedEpisode]) && _Success == 1) {
            // Do Nothing
            return ScrobblerSameEpisodePlaying;
        }
        else {
            // Not Scrobbled Yet or Unsuccessful
            return ScrobblerDetectedMedia;
        }
    }
    else {
        return ScrobblerNothingPlaying;
    }
    
}
- (BOOL)checkBlankDetectedEpisode{
    if ([_LastScrobbledEpisode isEqualToString:@"1"] && _DetectedEpisode.length == 0) {
        return true;
    }
    return false;
}
- (BOOL)confirmupdate{
    _DetectedTitle = _LastScrobbledTitle;
    _DetectedEpisode = _LastScrobbledEpisode;
    _DetectedSource  = _LastScrobbledSource;
    NSLog(@"=============");
    NSLog(@"Confirming: %@ - %@",_LastScrobbledActualTitle, _LastScrobbledEpisode);
    // Check Credentials
    int status;
    if (_LastScrobbledTitleNew)
    {
        status = [self addtitle:_AniID confirming:true];
    }
    else {
        status = [self updatetitle:_AniID confirming:true];
    }
    NSLog(@"Confirming process complete with status code: %i", status);
    
    if (status == 21 || status ==22) {
            // Clear Detected Episode and Title
            _DetectedTitle = nil;
            _DetectedEpisode = nil;
            _DetectedSource = nil;
            // Record Confirm for Offline Queued Item, if exists
            NSManagedObject *obj = [self checkifexistinqueue];
            if (obj) {
                [obj setValue:@(status) forKey:@"status"];
                [obj setValue:@(true) forKey:@"scrobbled"];
             }
            return true;
    }
    else {
            return false;
    }
}
- (void)clearAnimeInfo{
    _LastScrobbledInfo = nil;
}
- (void)checkzeroEpisode{
    // For 00 Episodes
    if ([_DetectedEpisode isEqualToString:@"00"]||[_DetectedEpisode isEqualToString:@"0"]) {
        _DetectedEpisode = @"1";
        _DetectedTitleisEpisodeZero = true;
    }
    else if (([_DetectedType isLike:@"Movie"] || [_DetectedType isLike:@"OVA"] || [_DetectedType isLike:@"Special"]) && ([_DetectedEpisode isEqualToString:@"0"] || _DetectedEpisode.length == 0)) {
        _DetectedEpisode = @"1";
    }
    else {_DetectedTitleisEpisodeZero = false;}
}
- (NSString *)checkCache{
    NSManagedObjectContext *moc = managedObjectContext;
    NSFetchRequest *allCaches = [[NSFetchRequest alloc] init];
    allCaches.entity = [NSEntityDescription entityForName:@"Cache" inManagedObjectContext:moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"detectedTitle == %@", _DetectedTitle];
    allCaches.predicate = predicate;
    NSError *error = nil;
    NSArray *cache = [moc executeFetchRequest:allCaches error:&error];
    if (cache.count > 0) {
        for (NSManagedObject *cacheentry in cache) {
            NSString *title = [cacheentry valueForKey:@"detectedTitle"];
            NSNumber *season = [cacheentry valueForKey:@"detectedSeason"];
            if ([title isEqualToString:_DetectedTitle] && _DetectedSeason == season.intValue) {
                NSLog(@"%@", season.intValue > 1 ? [NSString stringWithFormat:@"%@ Season %i is found in cache.", title, season.intValue] : [NSString stringWithFormat:@"%@ is found in cache.", title]);
                // Total Episode check
                NSNumber *totalepisodes = [cacheentry valueForKey:@"totalEpisodes"];
                if ( _DetectedEpisode.intValue <= totalepisodes.intValue || totalepisodes.intValue == 0 ) {
                    return [cacheentry valueForKey:@"id"];
                }
            }
        }
    }
    return @"";
}
- (void)checkExceptions{
    // Check Exceptions
    NSManagedObjectContext *moc = self.managedObjectContext;
    bool found = false;
    NSPredicate *predicate;
    for (int i = 0; i < 2; i++) {
        
        NSFetchRequest *allExceptions = [[NSFetchRequest alloc] init];
        __block NSError *error = nil;
        if (i == 0) {
            NSLog(@"Check Exceptions List");
            allExceptions.entity = [NSEntityDescription entityForName:@"Exceptions" inManagedObjectContext:moc];
            if (_DetectedSeason > 1) {
                predicate = [NSPredicate predicateWithFormat: @"(detectedTitle ==[c] %@) AND (detectedSeason == %i)", _DetectedTitle, _DetectedSeason];
            }
            else {
                predicate = [NSPredicate predicateWithFormat: @"(detectedTitle ==[c] %@) AND ((detectedSeason == %i) OR (detectedSeason == %i))", _DetectedTitle, 0, 1];
            }
        }
        else if (i== 1 && [[NSUserDefaults standardUserDefaults] boolForKey:@"UseAutoExceptions"]) {
            NSLog(@"Checking Auto Exceptions");
            allExceptions.entity = [NSEntityDescription entityForName:@"AutoExceptions" inManagedObjectContext:moc];
            if (_DetectedSeason == 1 || _DetectedSeason == 0) {
                predicate = [NSPredicate predicateWithFormat: @"(detectedTitle ==[c] %@) AND ((group == %@) OR (group == %@))", _DetectedTitle, _DetectedGroup, @"ALL"];
            }
            else {
                predicate = [NSPredicate predicateWithFormat: @"((detectedTitle ==[c] %@) OR (detectedTitle ==[c] %@) OR (detectedTitle ==[c] %@)) AND ((group == %@) OR (group == %@))", [NSString stringWithFormat:@"%@ %i", _DetectedTitle, _DetectedSeason], [NSString stringWithFormat:@"%@ S%i", _DetectedTitle, _DetectedSeason], [NSString stringWithFormat:@"%@ %@ Season", _DetectedTitle, [Utility numbertoordinal:_DetectedSeason]], _DetectedGroup, @"ALL"];
            }
        }
        else {break;}
        // Set Predicate and filter exceiptions array
        allExceptions.predicate = predicate;
        __block NSArray *exceptions;
        [moc performBlockAndWait:^{
            exceptions = [moc executeFetchRequest:allExceptions error:&error];
        }];
        if (exceptions.count > 0) {
            NSString *correcttitle;
            for (NSManagedObject *entry in exceptions) {
                NSLog(@"%@",(NSString *)[entry valueForKey:@"detectedTitle"]);
                if ([_DetectedTitle caseInsensitiveCompare:(NSString *)[entry valueForKey:@"detectedTitle"]] == NSOrderedSame) {
                    correcttitle = (NSString *)[entry valueForKey:@"correctTitle"];
                    // Set Correct Title and Episode offset (if any)
                    int threshold = ((NSNumber *)[entry valueForKey:@"episodethreshold"]).intValue;
                    int offset = ((NSNumber *)[entry valueForKey:@"episodeOffset"]).intValue;
                    int tmpepisode = _DetectedEpisode.intValue - offset;
                    int mappedepisode;
                    if (i == 1) {
                        mappedepisode = ((NSNumber *)[entry valueForKey:@"mappedepisode"]).intValue;
                    }
                    else {
                        mappedepisode = 0;
                    }
                    bool iszeroepisode;
                    if (i == 1) {
                        iszeroepisode = ((NSNumber *)[entry valueForKey:@"iszeroepisode"]).boolValue;
                    }
                    else {
                        iszeroepisode = false;
                    }
                    if (i==1 && _DetectedTitleisEpisodeZero == true && iszeroepisode == true) {
                        NSLog(@"%@ zero episode is found on exceptions list as %@.", _DetectedTitle, correcttitle);
                        _DetectedTitle = correcttitle;
                        _DetectedEpisode = [NSString stringWithFormat:@"%i", mappedepisode];
                        _DetectedTitleisEpisodeZero = true;
                        found = true;
                        break;
                    }
                    else if (i==1 && _DetectedTitleisEpisodeZero == false && iszeroepisode == true) {
                        continue;
                    }
                    if ((tmpepisode > threshold && threshold != 0) || (tmpepisode <= 0 && threshold != 1 && i==0)||(tmpepisode <= 0 && i==1)) {
                        continue;
                    }
                    else {
                        NSLog(@"%@ found on exceptions list as %@.", _DetectedTitle, correcttitle);
                        _DetectedTitle = correcttitle;
                        if (tmpepisode > 0) {
                            _DetectedEpisode = [NSString stringWithFormat:@"%i", tmpepisode];
                        }
                        _DetectedType = @"";
                        _DetectedSeason = 0;
                        _DetectedTitleisEpisodeZero = false;
                        found = true;
                        break;
                    }
                }
            }
            if (found) {break;} //Break from exceptions check loop
        }
    }
}
- (NSString *)startSearch{
    // Performs Search
    return [self searchanime];
}
- (NSManagedObject *)checkifexistinqueue{
    // Return existing offline queue item
    NSError *error;
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(detectedtitle ==[c] %@) AND (detectedepisode ==[c] %@) AND (detectedtype ==[c] %@) AND (ismovie == %i) AND (iszeroepisode == %i) AND (detectedseason == %i) AND (source == %@)", _DetectedTitle, _DetectedEpisode, _DetectedType, _DetectedTitleisMovie, _DetectedTitleisEpisodeZero, _DetectedSeason, _DetectedSource];
    NSFetchRequest *queuefetch = [[NSFetchRequest alloc] init];
    queuefetch.entity = [NSEntityDescription entityForName:@"OfflineQueue" inManagedObjectContext:moc];
    queuefetch.predicate = predicate;
    NSArray *queue = [moc executeFetchRequest:queuefetch error:&error];
    if (queue.count > 0) {
        return (NSManagedObject *)queue[0];
    }
    return nil;
}

- (void)resetinfo {
    // Resets MAL Engine when user logs out
    _LastScrobbledInfo = nil;
    _LastScrobbledTitle = nil;
    _LastScrobbledSource = nil;
    _LastScrobbledEpisode = nil;
    _LastScrobbledTitleNew = false;
    _LastScrobbledActualTitle = nil;
    _AniID = nil;
}

- (void)setupnotifier {
    //Create Reachability Object
    _reach = [Reachability reachabilityWithHostname:[Utility getHostName]];
    // Set up blocks
    // Set the blocks
    _reach.reachableBlock = ^(Reachability*reach)
    {
        _online = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Atarashii-API is reachable.");
        });
    };
    _reach.unreachableBlock = ^(Reachability*reach)
    {
        _online = false;
        NSLog(@"Computer not connected to internet or Atarashii-API Server is down");
    };
    // Start notifier
    [_reach startNotifier];
}
- (void)changenotifierhostname {
    [_reach stopNotifier];
    [self setupnotifier];
}
@end
