//
//  MyAnimeList.h
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import "MAL_Updater_OS_XAppDelegate.h"
@class Reachability;
@class Detection;

@interface MyAnimeList : NSObject
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
    ScrobblerFailed = 54,
    ScrobblerInvalidCredentials = 55,
    ScrobblerMALUpdaterOSXNeedsUpdate = 56,
    ScrobblerUnregisteredUpdateLimitReached = 57
};
@property (strong) NSString *MALApiUrl;
@property (strong, getter=getLastScrobbledTitle) NSString *LastScrobbledTitle;
@property (strong, getter=getLastScrobbledEpisode) NSString *LastScrobbledEpisode;
@property (strong, getter=getLastScrobbledActualTitle) NSString *LastScrobbledActualTitle;
@property (strong, getter=getLastScrobbledSource) NSString *LastScrobbledSource;
@property (strong, getter=getLastScrobbledInfo) NSDictionary *LastScrobbledInfo;
@property (strong) NSString *username;
@property (strong) NSString *DetectedTitle;
@property (strong) NSString *DetectedEpisode;
@property (strong) NSString *DetectedSource;
@property (strong) NSString *DetectedGroup;
@property (strong) NSString *DetectedType;
@property (strong, getter=getFailedTitle) NSString *FailedTitle;
@property (strong, getter=getFailedEpisode) NSString *FailedEpisode;
@property (strong, getter=getFailedSource) NSString *FailedSource;
@property (getter=getFailedSeason) int FailedSeason;
@property BOOL DetectedTitleisMovie;
@property BOOL DetectedTitleisEpisodeZero;
@property int DetectedSeason;
@property (getter=getCurrentEpisode) int DetectedCurrentEpisode;
@property (getter=getTotalEpisodes) int TotalEpisodes;
@property (strong) NSString *WatchStatus;
@property (getter=getScore) int TitleScore;
@property (strong, getter=getAniID)NSString *AniID;
@property (getter=getisNewTitle) BOOL LastScrobbledTitleNew;
@property (getter=getConfirmed) BOOL confirmed;
@property (getter=getSuccess) BOOL Success;
@property (getter=getOnlineStatus) BOOL online;
@property BOOL correcting;
@property (strong) Reachability* reach;
@property (strong, getter=getstreamlinkdetector) streamlinkdetector *detector;
@property (strong) Detection *detection;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

- (void)setManagedObjectContext:(NSManagedObjectContext *)context;
- (int)startscrobbling;
- (int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode correctonce:(BOOL)correctonce;
- (int)performscrobbletest:(NSString *)filename delete:(bool)deletetitle;
- (int)scrobble;
- (NSDictionary *)scrobblefromqueue;
- (BOOL)confirmupdate;
- (int)getWatchStatus;
- (int)getQueueCount;
- (void)clearAnimeInfo;
- (NSString *)startSearch;
- (void)resetinfo;
- (void)changenotifierhostname;
@end
