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
	BOOL Success;
	NSTimer * timer;
	IBOutlet NSMenuItem * togglescrobbler;
	IBOutlet NSTextField * ScrobblerStatus;
	IBOutlet NSTextField * LastScrobbled;
	int choice;
}
-(IBAction)toggletimer:(id)sender;
-(void)firetimer:(NSTimer *)aTimer;
-(BOOL)detectmedia;
-(NSString *)searchanime;
-(NSString *)getaniid:(NSString *)ResponseData;
-(BOOL)checkstatus:(NSString *)AniID;
-(BOOL)updatetitle:(NSString *)AniID;
-(BOOL)addtitle:(NSString *)AniID;
-(void)posttwitterupdate:(NSString *)message;
@end
