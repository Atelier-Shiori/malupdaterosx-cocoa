//
//  MyAnimeList+HummingbirdSearch.h
//  MAL Updater OS X
//
//  Created by アナスタシア on 2016/04/13.
//
//

#import "MyAnimeList.h"

@interface MyAnimeList (HummingbirdSearch)
- (NSString *)hsearchanime;
- (NSString *)hperformSearch:(NSString *)searchtitle;
- (NSString *)hfindaniid:(NSData *)ResponseData searchterm:(NSString *) term;
- (NSArray *)hfilterArray:(NSArray *)searchdata;
- (NSString *)hfoundtitle:(NSString *)titleid info:(NSDictionary *)found;
- (NSString *)hcomparetitle:(NSString *)title match1:(NSDictionary *)match1 match2:(NSDictionary *)match2 mstatus:(int)a mstatus2:(int)b;
@end
