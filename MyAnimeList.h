//
//  MyAnimeList.h
//  MAL Updater OS X
//
//  Created by Tohno Minagi on 8/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import <JSON/JSON.h>

@interface MyAnimeList : NSObject {
	NSString * Base64Token;
	NSString * LastScrobbledTitle;
	NSString * LastScrobbledEpisode;
	NSString * DetectedTitle;
	NSString * DetectedEpisode;
	NSString * DetectedCurrentEpisode;
	NSString * TotalEpisodes;
	BOOL Success;
	NSTimer * timer;
	IBOutlet NSMenuItem * togglescrobbler;
	IBOutlet NSTextField * ScrobblerStatus;
	IBOutlet NSTextField * LastScrobbled;
	int * choice;
}
-(IBAction)toggletimer:(id)sender;
-(void)firetimer:(NSTimer *)aTimer;
-(BOOL)detectmedia;
-(NSString *)searchanime;
-(NSString *)getaniid:(NSString *)ResponseData;
-(BOOL)checkstatus:(NSString *)AniID;
-(BOOL)updatetitle:(NSString *)AniID;
-(BOOL)addtitle:(NSString *)AniID;
@end
