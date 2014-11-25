//
//  MyAnimeList.h
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import "MAL_Updater_OS_XAppDelegate.h"
#import <ASIHTTPRequest/ASIHTTPRequest.h>
#import <ASIHTTPRequest/ASIHTTPRequest.h>
#import <ASIHTTPRequest/ASIFormDataRequest.h>

@interface MyAnimeList : NSObject {
	NSString * Base64Token;
	NSString * MALApiUrl;
	NSString * LastScrobbledTitle;
	NSString * LastScrobbledEpisode;
	NSDictionary * LastScrobbledInfo;
	NSString * DetectedTitle;
	NSString * DetectedEpisode;
	NSString * DetectedCurrentEpisode;
    BOOL DetectedTitleisMovie;
    int DetectedSeason;
	NSString * TotalEpisodes;
	NSString * WatchStatus;
	NSString * TitleScore;
	NSString * TitleState;
    NSString * AniID;
	BOOL Success;
    BOOL online;
	int choice;
}
- (int)startscrobbling;
-(int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode;
-(int)scrobble;
-(BOOL)updatestatus:(NSString *)titleid
              score:(int)showscore
        watchstatus:(NSString*)showwatchstatus;
-(bool)removetitle:(NSString *)titleid;
-(NSString *)getLastScrobbledTitle;
-(NSString *)getLastScrobbledEpisode;
-(NSString *)getAniID;
-(NSString *)getTotalEpisodes;
-(int)getScore;
-(int)getWatchStatus;
-(BOOL)getSuccess;
-(NSDictionary *)getLastScrobbledInfo;
-(void)clearAnimeInfo;
@end
