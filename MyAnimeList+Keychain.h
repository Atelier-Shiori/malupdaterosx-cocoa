//
//  MyAnimeList+Keychain.h
//  MAL Updater OS X
//
//  Created by アナスタシア on 2015/11/26.
//
//

#import "MyAnimeList.h"
#import "SSKeychain.h"

@interface MyAnimeList (Keychain)
-(BOOL)checkaccount;
-(BOOL)storeaccount:(NSString *)uname password:(NSString *)password;
-(BOOL)removeaccount;
-(NSString *)getusername;
-(NSString *)getBase64;
@end
