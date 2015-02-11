//
//  MyAnimeList+Update.h
//  MAL Updater OS X
//
//  Created by 高町なのは on 2015/02/11.
//
//

#import "MyAnimeList.h"

@interface MyAnimeList (Update)
-(BOOL)updatestatus:(NSString *)titleid
              score:(int)showscore
        watchstatus:(NSString*)showwatchstatus
            episode:(NSString*)episode;
-(bool)removetitle:(NSString *)titleid;
-(int)updatetitle:(NSString *)titleid confirming:(bool) confirming;
-(int)addtitle:(NSString *)titleid confirming:(bool) confirming;
@end
