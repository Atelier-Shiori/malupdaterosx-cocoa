//
//  MyAnimeList.h
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import <JSON/JSON.h>
#import "MAL_Updater_OS_XAppDelegate.h"

@class Twitter;

@interface MyAnimeList : NSObject {
	NSString * Base64Token;
	NSString * MALApiUrl;
	NSString * LastScrobbledTitle;
	NSString * LastScrobbledEpisode;
	NSDictionary * LastScrobbledInfo;
	NSString * DetectedTitle;
	NSString * DetectedEpisode;
	NSString * DetectedCurrentEpisode;
    BOOL* DetectedTitleisMovie;
	NSString * TotalEpisodes;
	NSString * WatchStatus;
	NSString * TitleScore;
	NSString * TitleState;
    NSString * AniID;
	OGRegularExpressionMatch    *match;
	OGRegularExpression    *regex;
	BOOL Success;
	int choice;
    //Twitter * twitterobj;
}
-(void)startscrobbling;
-(BOOL)detectmedia;
-(NSString *)searchanime;
-(NSString *)findaniid:(NSString *)ResponseData;
-(BOOL)checkstatus:(NSString *)titleid;
-(BOOL)updatetitle:(NSString *)titleid;
-(BOOL)addtitle:(NSString *)titleid;
-(void)updatestatus:(NSString *)titleid
			 score:(int)showscore
	   watchstatus:(NSString*)showwatchstatus;
//-(void)posttwitterupdate:(NSString *)message;
-(NSString *)getLastScrobbledTitle;
-(NSString *)getLastScrobbledEpisode;
-(NSString *)getAniID;
-(NSString *)getTotalEpisodes;
-(int)getScore;
-(int)getWatchStatus;
-(BOOL)getSuccess;
-(NSDictionary *)getLastScrobbledInfo;
@end
