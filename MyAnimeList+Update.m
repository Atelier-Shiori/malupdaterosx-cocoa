//
//  MyAnimeList+Update.m
//  MAL Updater OS X
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList+Update.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>
#import "MyAnimeList+Keychain.h"
#import "Utility.h"

@implementation MyAnimeList (Update)
- (BOOL)checkstatus:(NSString *)titleid {
    NSLog(@"Checking Status");
    //Set Search API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/1/anime/%@?mine=1",self.MALApiUrl, titleid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    request.headers = (NSMutableDictionary *)@{@"Authorization": [NSString stringWithFormat:@"Basic %@", [self getBase64]]};
    //Perform Search
    [request startRequest];
    // Get Status Code
    int statusCode = [request getStatusCode];
    NSError *error = [request getError]; // Error Detection
    if (statusCode == 200 ) {
        if (self.DetectedEpisode.length == 0) { // Check if there is a DetectedEpisode (needed for checking
            // Set detected episode to 1
            self.DetectedEpisode = @"1";
        }
        NSError* jerror;
        NSDictionary *animeinfo = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:nil error:&jerror];
        self.TotalEpisodes = animeinfo[@"episodes"] == [NSNull null] ? 0 : ((NSNumber *)animeinfo[@"episodes"]).intValue;
        // Watch Status
        if (animeinfo[@"watched_status"] == [NSNull null]) {
            NSLog(@"Not on List");
            self.LastScrobbledTitleNew = true;
            self.DetectedCurrentEpisode = 0;
            self.TitleScore = 0;
        }
        else {
            NSLog(@"Title on List");
            self.LastScrobbledTitleNew = false;
            self.WatchStatus = animeinfo[@"watched_status"];
            self.DetectedCurrentEpisode = ((NSNumber *)animeinfo[@"watched_episodes"]).intValue;
            self.TitleScore = animeinfo[@"score"] == [NSNull null] ? 0 : ((NSNumber *)animeinfo[@"score"]).intValue;
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
    NSLog(@"Updating Title");
    
    if ((self.DetectedEpisode).intValue <= self.DetectedCurrentEpisode ) {
        // Already Watched, no need to scrobble
        // Store Scrobbled Title and Episode
        self.confirmed = true;
        [self storeLastScrobbled];
        return ScrobblerUpdateNotNeeded;
    }
    else if (!self.LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !self.confirmed && !self.correcting && !confirming) {
        // Confirm before updating title
        [self storeLastScrobbled];
        return ScrobblerConfirmNeeded;
    }
    else {
        // Update the title
        //Set library/scrobble API
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/2.1/animelist/anime/%@", self.MALApiUrl, titleid]];
        EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
        //Ignore Cookies
        [request setUseCookies:NO];
        //Set Token
        request.headers = (NSMutableDictionary *)@{@"Authorization": [NSString stringWithFormat:@"Basic %@", [self getBase64]]};
        [request setPostMethod:@"PUT"];
        [request addFormData:self.DetectedEpisode forKey:@"episodes"];
        //Set Status
        self.WatchStatus = (self.DetectedEpisode).intValue == self.TotalEpisodes ? @"completed" : @"watching";
        if ([self.WatchStatus isEqualToString:@"completed"]) {
            [request addFormData:[Utility todaydatestring] forKey:@"end"];
        }
        [request addFormData:self.WatchStatus forKey:@"status"];
        // Set existing score to prevent the score from being erased.
        [request addFormData:@(self.TitleScore).stringValue forKey:@"score"];
        // Do Update
        [request startFormRequest];
        
        switch ([request getStatusCode]) {
            case 200:
                // Store Last Scrobbled Title
                self.LastScrobbledTitle = self.DetectedTitle;
                self.LastScrobbledEpisode = self.DetectedEpisode;
                self.DetectedCurrentEpisode = (self.DetectedEpisode).intValue;
                self.LastScrobbledSource = self.DetectedSource;
                if (self.confirmed) {
                    self.LastScrobbledActualTitle = (NSString *)self.LastScrobbledInfo[@"title"];
                }
                self.confirmed = true;
                // Update Successful
                return ScrobblerUpdateSuccessful;
            default:
                // Update Unsuccessful
                return ScrobblerUpdateFailed;
        }
        
    }
}
- (int)addtitle:(NSString *)titleid confirming:(bool)confirming{
    NSLog(@"Adding Title");
    //Check Confirm
    if (self.LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && !self.confirmed && !self.correcting && !confirming) {
        // Confirm before updating title
        [self storeLastScrobbled];
        return ScrobblerConfirmNeeded;
    }
    // Add the title
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/2.1/animelist/anime", self.MALApiUrl]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    request.headers = (NSMutableDictionary *)@{@"Authorization": [NSString stringWithFormat:@"Basic %@", [self getBase64]]};
    [request addFormData:titleid forKey:@"anime_id"];
    [request addFormData:self.DetectedEpisode forKey:@"episodes"];
    // Check if the detected episode is equal to total episodes. If so, set it as complete (mostly for specials and movies)
    //Set Status
    self.WatchStatus = (self.DetectedEpisode).intValue == self.TotalEpisodes ? @"completed" : @"watching";
    [request addFormData:self.WatchStatus forKey:@"status"];
    // Do Update
    [request startFormRequest];
    
    switch ([request getStatusCode]) {
        case 200:
        case 201:
            // Update Successful
            
            //Store last scrobbled information
            self.LastScrobbledTitle = self.DetectedTitle;
            self.LastScrobbledEpisode = self.DetectedEpisode;
            self.DetectedCurrentEpisode = (self.DetectedEpisode).intValue;
            self.LastScrobbledSource = self.DetectedSource;
            if (self.confirmed) {
                self.LastScrobbledActualTitle = (NSString *)self.LastScrobbledInfo[@"title"];
            }
            self.confirmed = true;
            if (![self setStartEndDates:titleid]) {
                NSLog(@"Can't set start/end dates");
            }
            return ScrobblerAddTitleSuccessful;
        default:
            // Update Unsuccessful
            return ScrobblerAddTitleFailed;
    }
}
- (bool)removetitle:(NSString *)titleid{
    NSLog(@"Removing %@", titleid);
    //Set up Delegate
    
    // Update the title
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/2.1/animelist/anime/%@", self.MALApiUrl, titleid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    request.headers = (NSMutableDictionary *)@{@"Authorization": [NSString stringWithFormat:@"Basic %@", [self getBase64]]};
    //Set method to Delete
    [request setPostMethod:@"DELETE"];
    // Do Update
    [request startFormRequest];
    switch ([request getStatusCode]) {
        case 200:
        case 201:
            return true;
        default:
            // Update Unsuccessful
            return false;
    }
    return false;
}
- (BOOL)updatestatus:(NSString *)titleid
              score:(int)showscore
        watchstatus:(NSString*)showwatchstatus
            episode:(NSString*)episode
{
    NSLog(@"Updating Status for %@", titleid);
    // Check Credentials
    if ([self checkMALCredentials] == 0) {
        return false;
    }
    // Update the title
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/2.1/animelist/anime/%@", self.MALApiUrl, titleid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    request.headers = (NSMutableDictionary *)@{@"Authorization": [NSString stringWithFormat:@"Basic %@", [self getBase64]]};
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
            self.TitleScore = showscore;
            self.WatchStatus = showwatchstatus;
            self.LastScrobbledEpisode = episode;
            self.DetectedCurrentEpisode = episode.intValue;
            self.confirmed = true;
            return true;
        default:
            // Update Unsuccessful
            return false;
    }
}
- (bool)setStartEndDates:(NSString *)titleid {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/2.1/animelist/anime/%@", self.MALApiUrl, titleid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    [request setUseCookies:NO];
    request.headers = (NSMutableDictionary *)@{@"Authorization": [NSString stringWithFormat:@"Basic %@", [self getBase64]]};
    [request setPostMethod:@"PUT"];
    // Set Date
    [request addFormData:[Utility todaydatestring] forKey:@"start"];
    if ([self.WatchStatus isEqualToString:@"completed"]) {
        [request addFormData:[Utility todaydatestring] forKey:@"end"];
    }
    [request startFormRequest];
    switch ([request getStatusCode]) {
        case 200:
        case 201:
            return true;
        default:
            return false;
    }
    
}
- (void)storeLastScrobbled{
    self.LastScrobbledTitle = self.DetectedTitle;
    self.LastScrobbledEpisode = self.DetectedEpisode;
    self.LastScrobbledActualTitle = (NSString *)self.LastScrobbledInfo[@"title"];
    self.LastScrobbledSource = self.DetectedSource;
}
@end
