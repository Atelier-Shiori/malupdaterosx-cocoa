//
//  MyAnimeList+Search.h
//  MAL Updater OS X
//
//  Created by 高町なのは on 2015/02/11.
//
//

#import "MyAnimeList.h"

@interface MyAnimeList (Search)
-(NSString *)searchanime;
-(NSString *)performSearch:(NSString *)searchtitle;
-(NSString *)findaniid:(NSData *)ResponseData searchterm:(NSString *) term;
-(NSArray *)filterArray:(NSArray *)searchdata;
-(NSString *)foundtitle:(NSString *)titleid info:(NSDictionary *)found;
@end
