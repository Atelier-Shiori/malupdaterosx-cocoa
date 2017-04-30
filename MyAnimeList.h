//
//  MyAnimeList.h
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import "MAL_Updater_OS_XAppDelegate.h"
#import "Reachability.h"
@class streamlinkdetector;

@interface MyAnimeList : NSObject {
	NSString * MALApiUrl;
    NSString * LastScrobbledTitle;
	NSString * LastScrobbledEpisode;
	NSString * LastScrobbledActualTitle;
    NSString * LastScrobbledSource;
    NSDictionary * LastScrobbledInfo;
    NSString * username;
    NSString * DetectedTitle;
    NSString * DetectedEpisode;
    NSString * DetectedSource;
    NSString * DetectedGroup;
    NSString * DetectedType;
    NSString * FailedTitle;
    NSString * FailedEpisode;
    NSString * FailedSource;
    BOOL DetectedTitleisMovie;
    BOOL DetectedTitleisEpisodeZero;
    int DetectedSeason;
	int DetectedCurrentEpisode;
	int TotalEpisodes;
	NSString * WatchStatus;
	int TitleScore;
    NSString * AniID;
	BOOL LastScrobbledTitleNew;
	BOOL confirmed;
	BOOL Success;
    BOOL online;
    BOOL kodionline;
	BOOL correcting;
    Reachability* reach;
    Reachability* kodireach;
    NSManagedObjectContext *managedObjectContext;
    streamlinkdetector * detector;
}
typedef NS_ENUM(unsigned int, ScrobbleStatus) {
    ScrobblerNothingPlaying = 0,
    ScrobblerSameEpisodePlaying = 1,
    ScrobblerUpdateNotNeeded = 2,
    ScrobblerConfirmNeeded = 3,
    ScrobblerDetectedMedia = 4,
    ScrobblerAddTitleSuccessful = 21,
    ScrobblerUpdateSuccessful = 22,
    ScrobblerOfflineQueued = 23,
    ScrobblerTitleNotFound = 51,
    ScrobblerAddTitleFailed = 52,
    ScrobblerUpdateFailed = 53,
    ScrobblerFailed = 54
};
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
-(void)setManagedObjectContext:(NSManagedObjectContext *)context;
- (int)startscrobbling;
-(int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode correctonce:(BOOL)correctonce;
-(int)scrobblefromstreamlink:(NSString *)url withStream:(NSString *)stream;
- (int)performscrobbletest:(NSString *)filename delete:(bool)deletetitle;
-(int)scrobble;
-(NSDictionary *)scrobblefromqueue;
-(BOOL)confirmupdate;
-(NSString *)getLastScrobbledTitle;
-(NSString *)getLastScrobbledEpisode;
-(NSString *)getLastScrobbledActualTitle;
-(NSString *)getLastScrobbledSource;
-(NSString *)getAniID;
-(int)getTotalEpisodes;
-(NSString *)getFailedTitle;
-(NSString *)getFailedEpisode;
-(int)getCurrentEpisode;
-(BOOL)getConfirmed;
-(int)getScore;
-(int)getWatchStatus;
-(BOOL)getSuccess;
-(BOOL)getisNewTitle;
-(BOOL)getOnlineStatus;
-(BOOL)getKodiOnlineStatus;
-(NSDictionary *)getLastScrobbledInfo;
-(int)getQueueCount;
-(streamlinkdetector *)getstreamlinkdetector;
-(void)clearAnimeInfo;
-(NSString *)startSearch;
-(void)setKodiReach:(BOOL)enable;
-(void)setKodiReachAddress:(NSString *)url;
@end
