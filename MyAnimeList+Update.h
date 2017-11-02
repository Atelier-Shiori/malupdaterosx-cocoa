//
//  MyAnimeList+Update.h
//  MAL Updater OS X
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList.h"

@interface MyAnimeList (Update)
- (BOOL)checkstatus:(NSString *)titleid;
- (void)updatestatus:(NSString *)titleid
               score:(int)showscore
         watchstatus:(NSString*)showwatchstatus
             episode:(NSString*)episode
          completion:(void (^)(bool success))completionhandler;
- (bool)removetitle:(NSString *)titleid;
- (int)updatetitle:(NSString *)titleid confirming:(bool) confirming;
- (int)addtitle:(NSString *)titleid confirming:(bool) confirming;
@end
