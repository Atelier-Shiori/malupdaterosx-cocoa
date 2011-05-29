//
//  MyAnimeList.h
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2011 Chikorita157's Anime Blog. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import <JSON/JSON.h>
#import "MAL_Updater_OS_XAppDelegate.h"
#import "Twitter.h"

@class Twitter;

@interface MyAnimeList : NSObject {
	NSString * Base64Token;
	NSString * MALApiUrl;
	NSString * LastScrobbledTitle;
	NSString * LastScrobbledEpisode;
	NSString * DetectedTitle;
	NSString * DetectedEpisode;
	NSString * DetectedCurrentEpisode;
	NSString * TotalEpisodes;
	NSString * WatchStatus;
	NSString * TitleScore;
	NSString * TitleState;
    NSString * AniID;
	BOOL Success;
	int choice;
    Twitter * twitterobj;
}
-(void)startscrobbling;
-(BOOL)detectmedia;
-(NSString *)searchanime;
-(NSString *)findaniid:(NSString *)ResponseData;
-(BOOL)checkstatus:(NSString *)AniID;
-(BOOL)updatetitle:(NSString *)AniID;
-(BOOL)addtitle:(NSString *)AniID;
-(void)posttwitterupdate:(NSString *)message;
-(NSString *)getLastScrobbledTitle;
-(NSString *)getLastScrobbledEpisode;
-(NSString *)getAniID;
@end
