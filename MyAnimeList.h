//
//  MyAnimeList.h
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import "MAL_Updater_OS_XAppDelegate.h"

@interface MyAnimeList : NSObject {
	NSString * MALApiUrl;
    NSString * LastScrobbledTitle;
	NSString * LastScrobbledEpisode;
	NSString * LastScrobbledActualTitle;
    NSString * LastScrobbledSource;
    NSDictionary * LastScrobbledInfo;
	__weak NSString * DetectedTitle;
	__weak NSString * DetectedEpisode;
    __weak NSString * DetectedSource;
    __weak NSString * DetectedGroup;
    NSString * FailedTitle;
    NSString * FailedEpisode;
    NSString * FailedSource;
    BOOL DetectedTitleisMovie;
    int DetectedSeason;
	NSString * DetectedCurrentEpisode;
	NSString * TotalEpisodes;
	NSString * WatchStatus;
	NSString * TitleScore;
    NSString * AniID;
	BOOL LastScrobbledTitleNew;
	BOOL confirmed;
	BOOL Success;
    BOOL online;
	BOOL correcting;
	int choice;
    NSManagedObjectContext *managedObjectContext;
}
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
-(void)setManagedObjectContext:(NSManagedObjectContext *)context;
- (int)startscrobbling;
-(int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode correctonce:(BOOL)correctonce;
-(int)scrobble;
-(BOOL)confirmupdate;
-(NSString *)getLastScrobbledTitle;
-(NSString *)getLastScrobbledEpisode;
-(NSString *)getLastScrobbledActualTitle;
-(NSString *)getLastScrobbledSource;
-(NSString *)getAniID;
-(NSString *)getTotalEpisodes;
-(NSString *)getFailedTitle;
-(NSString *)getFailedEpisode;
-(int)getCurrentEpisode;
-(BOOL)getConfirmed;
-(int)getScore;
-(int)getWatchStatus;
-(BOOL)getSuccess;
-(BOOL)getisNewTitle;
-(NSDictionary *)getLastScrobbledInfo;
-(void)clearAnimeInfo;
@end
