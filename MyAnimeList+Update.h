//
//  MyAnimeList+Update.h
//  MAL Updater OS X
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2015 MAL Updater OS X Group. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList.h"

@interface MyAnimeList (Update)
- (BOOL)checkstatus:(NSString *)titleid;
- (BOOL)updatestatus:(NSString *)titleid
              score:(int)showscore
        watchstatus:(NSString*)showwatchstatus
            episode:(NSString*)episode;
- (bool)removetitle:(NSString *)titleid;
- (int)updatetitle:(NSString *)titleid confirming:(bool) confirming;
- (int)addtitle:(NSString *)titleid confirming:(bool) confirming;
@end
