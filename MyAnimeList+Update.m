//
//  MyAnimeList+Update.m
//  MAL Updater OS X
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2015 MAL Updater OS X Group. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList+Update.h"
#import <EasyNSURLConnection/EasyNSURLConnection.h>
#import "MyAnimeList+Keychain.h"
#import "Utility.h"
#import "MyAnimeList+Twitter.h"
#import "MyAnimeList+Discord.h"

@implementation MyAnimeList (Update)
- (BOOL)checkstatus:(NSString *)titleid {
    NSLog(@"Checking Status");
    //Set Search API
    //Set Token
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self retrieveCredentials].accessToken] forHTTPHeaderField:@"Authorization"];
    //Perform status check
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject = [self.syncmanager syncGET:[NSString stringWithFormat:@"https://api.myanimelist.net/v2/anime/%@", titleid] parameters:nil task:&task error:&error];
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    if (statusCode == 200 ) {
        if (self.DetectedEpisode.length == 0) { // Check if there is a DetectedEpisode (needed for checking
            // Set detected episode to 1
            self.DetectedEpisode = @"1";
        }
        NSDictionary *animeinfo = responseObject;
        self.TotalEpisodes = animeinfo[@"num_episodes"] == [NSNull null] ? 0 : ((NSNumber *)animeinfo[@"num_episodes"]).intValue;
        // Set air status
        self.airing = ((animeinfo[@"start_date"] != [NSNull null] && animeinfo[@"end_date"] == [NSNull null]) || [(NSString *)animeinfo[@"status"] isEqualToString:@"currently_airing"]);
        self.completedairing = ((animeinfo[@"finish_date"] != [NSNull null] && animeinfo[@"finish_date"] != [NSNull null]) || [(NSString *)animeinfo[@"status"] isEqualToString:@"finished_airing"]);
        // Watch Status
        if (animeinfo[@"my_list_status"] == [NSNull null] || !animeinfo[@"my_list_status"]) {
            NSLog(@"Not on List");
            self.LastScrobbledTitleNew = true;
            self.DetectedCurrentEpisode = 0;
            self.TitleScore = 0;
        }
        else {
            NSLog(@"Title on List");
            self.LastScrobbledTitleNew = false;
            self.WatchStatus = animeinfo[@"my_list_status"][@"status"];
            self.DetectedCurrentEpisode = ((NSNumber *)animeinfo[@"my_list_status"][@"num_episodes_watched"]).intValue;
            self.TitleScore = animeinfo[@"my_list_status"][@"score"] == [NSNull null] ? 0 : ((NSNumber *)animeinfo[@"my_list_status"][@"score"]).intValue;
        }
        // New Update Confirmation
        if (([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && self.LastScrobbledTitleNew && !self.correcting)|| ([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !self.LastScrobbledTitleNew && !self.correcting)) {
            // Manually confirm updates
            self.confirmed = false;
        }
        else {
            // Automatically confirm updates
            self.confirmed = true;
        }
        self.LastScrobbledInfo = animeinfo;
        // Makes sure the values don't get released
        return YES;
    }
    else if (error !=nil) {
        return NO;
    }
    else {
        // Some Error. Abort
        return NO;
    }
    //Should never happen, but...
    return NO;
}

- (int)updatetitle:(NSString *)titleid confirming:(bool)confirming{
    NSLog(@"Checking Air Status");
    if (!self.airing && !self.completedairing) {
        // User attempting to update title that haven't been aired.
        return ScrobblerInvalidScrobble;
    }
    else if ((self.DetectedEpisode).intValue == self.TotalEpisodes && self.airing && !self.completedairing) {
        // User attempting to complete a title, which haven't finished airing
        return ScrobblerInvalidScrobble;
    }
    NSLog(@"Updating Title");
    if ((self.DetectedEpisode).intValue <= self.DetectedCurrentEpisode ) {
        // Already Watched, no need to scrobble
        // Store Scrobbled Title and Episode
        self.confirmed = true;
        [self storeLastScrobbled];
        [self sendDiscordPresence];
        return ScrobblerUpdateNotNeeded;
    }
    else if (!self.LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !self.confirmed && !self.correcting && !confirming) {
        // Confirm before updating title
        [self storeLastScrobbled];
        return ScrobblerConfirmNeeded;
    }
    // Update the title
    return [self performupdate:titleid isAdding:NO];
}
- (int)addtitle:(NSString *)titleid confirming:(bool)confirming {
    NSLog(@"Checking Air Status");
    if (!self.airing && !self.completedairing) {
        // User attempting to update title that haven't been aired.
        return ScrobblerInvalidScrobble;
    }
    else if ((self.DetectedEpisode).intValue == self.TotalEpisodes && self.airing && !self.completedairing) {
        // User attempting to complete a title, which haven't finished airing
        return ScrobblerInvalidScrobble;
    }
    NSLog(@"Adding Title");
    //Check Confirm
    if (self.LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && !self.confirmed && !self.correcting && !confirming) {
        // Confirm before updating title
        [self storeLastScrobbled];
        return ScrobblerConfirmNeeded;
    }
    // Add the title
    return [self performupdate:titleid isAdding:YES];
}
- (int)performupdate:(NSString *)titleid isAdding:(bool)isadding {
    //Set Token
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self retrieveCredentials].accessToken] forHTTPHeaderField:@"Authorization"];
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"num_watched_episodes"] = @(self.DetectedEpisode.intValue);
    //parameters[@"num_episodes_watched"] = @(self.DetectedEpisode.intValue);
    /*
    if (([self.WatchStatus isEqualToString:@"plan_to_watch"] && self.DetectedCurrentEpisode == 0) || isadding) {
        // Set the start date if the title's watch status is Plan to Watch and the watched episodes is zero
        [request addFormData:[Utility todaydatestring] forKey:@"start"];
    }*/
    //Set Status
    self.WatchStatus = (self.DetectedEpisode).intValue == self.TotalEpisodes ? @"completed" : @"watching";
    /*
    if ([self.WatchStatus isEqualToString:@"completed"]) {
        parameters[@"end"] = [Utility todaydatestring];
    }
     */
    parameters[@"status"] = self.WatchStatus;
    // Set existing score to prevent the score from being erased.
    parameters[@"score"] = @(self.TitleScore);
    NSLog(@"%@",parameters);
    // Do Update
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject = [self.syncmanager syncPUT:[NSString stringWithFormat:@"https://api.myanimelist.net/v2/anime/%@/my_list_status", titleid] parameters:parameters task:&task error:&error];
    
    switch (((NSHTTPURLResponse *)task.response).statusCode) {
        case 200: {
            // Store Last Scrobbled Title
            self.LastScrobbledTitle = self.DetectedTitle;
            self.LastScrobbledEpisode = self.DetectedEpisode;
            self.DetectedCurrentEpisode = (self.DetectedEpisode).intValue;
            self.LastScrobbledSource = self.DetectedSource;
            if (self.confirmed) {
                self.LastScrobbledActualTitle = (NSString *)self.LastScrobbledInfo[@"title"];
            }
            self.confirmed = true;
            // Set Discord Presence
            [self sendDiscordPresence];
            // Post tweet
            if (isadding) {
                [self postaddanimetweet];
                return ScrobblerAddTitleSuccessful;
            }
            [self postupdateanimetweet];
            // Update Successful
            return ScrobblerUpdateSuccessful;
            }
        default: {
            // Update Unsuccessful
            NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            NSLog(@"%@",ErrorResponse);
            if (isadding) {
                return ScrobblerAddTitleFailed;
            }
            return ScrobblerUpdateFailed;
            }
    }
}
- (bool)removetitle:(NSString *)titleid{
    NSLog(@"Removing %@", titleid);
    //Remove title
    //Set Token
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self retrieveCredentials].accessToken] forHTTPHeaderField:@"Authorization"];
    // Do Update
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject = [self.syncmanager syncDELETE:[NSString stringWithFormat:@"https://api.myanimelist.net/v2/anime/%@/my_list_status", titleid] parameters:nil task:&task error:&error];
    switch (((NSHTTPURLResponse *)task.response).statusCode) {
        case 200:
        case 201:
            return true;
        default:
            // Update Unsuccessful
            return false;
    }
    return false;
}
- (void)updatestatus:(NSString *)titleid
              score:(int)showscore
        watchstatus:(NSString *)showwatchstatus
            episode:(NSString *)episode
          completion:(void (^)(bool success)) completionHandler
{
    NSLog(@"Updating Status for %@", titleid);
    // Check Credentials
    if ([self checkexpired]) {
        [self refreshtoken:^(bool success) {
            if (success) {
                [self updatestatus:titleid score:showscore watchstatus:showwatchstatus episode:episode completion:completionHandler];
            }
            else {
                completionHandler(false);
            }
            }];
        return;
    }
    // Update the title
    //Set Token
    [self.asyncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self retrieveCredentials].accessToken] forHTTPHeaderField:@"Authorization"];
    //NSDictionary *parameters = @{@"num_episodes_watched" : @(episode.intValue), @"status" : [showwatchstatus.lowercaseString stringByReplacingOccurrencesOfString:@" " withString:@"_"], @"score" : @(showscore)};
    NSDictionary *parameters = @{@"num_watched_episodes" : @(episode.intValue), @"status" : [showwatchstatus.lowercaseString stringByReplacingOccurrencesOfString:@" " withString:@"_"], @"score" : @(showscore)};
    // Set up request and do update
    [self.asyncmanager PUT:[NSString stringWithFormat:@"%@/2.1/animelist/anime/%@/my_list_status", self.MALApiUrl, titleid] parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.TitleScore = showscore;
        self.WatchStatus = showwatchstatus;
        self.LastScrobbledEpisode = episode;
        self.DetectedCurrentEpisode = episode.intValue;
        self.confirmed = true;
        // Post tweet
        [self postupdatestatustweet];
        completionHandler(true);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        completionHandler(false);
    }];
}
- (void)storeLastScrobbled{
    self.LastScrobbledTitle = self.DetectedTitle;
    self.LastScrobbledEpisode = self.DetectedEpisode;
    self.LastScrobbledActualTitle = (NSString *)self.LastScrobbledInfo[@"title"];
    self.LastScrobbledSource = self.DetectedSource;
}
@end
