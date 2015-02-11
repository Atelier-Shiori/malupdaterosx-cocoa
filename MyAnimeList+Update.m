//
//  MyAnimeList+Update.m
//  MAL Updater OS X
//
//  Created by 高町なのは on 2015/02/11.
//
//

#import "MyAnimeList+Update.h"
#import "EasyNSURLConnection.h"

@implementation MyAnimeList (Update)
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

@end
