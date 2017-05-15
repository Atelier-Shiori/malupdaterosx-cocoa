//
//  MyAnimeList+Search.h
//  MAL Updater OS X
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList.h"

@interface MyAnimeList (Search)
-(NSString *)searchanime;
-(NSString *)performSearch:(NSString *)searchtitle;
-(NSString *)findaniid:(NSString *)ResponseData searchterm:(NSString *)term;
-(NSArray *)filterArray:(NSArray *)searchdata;
-(NSString *)foundtitle:(NSString *)titleid info:(NSDictionary *)found;
-(NSString *)comparetitle:(NSString *)title match1:(NSDictionary *)match1 match2:(NSDictionary *)match2 mstatus:(int)a mstatus2:(int)b;
@end
