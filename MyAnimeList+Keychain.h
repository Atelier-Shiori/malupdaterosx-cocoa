//
//  MyAnimeList+Keychain.h
//  MAL Updater OS X
//
//  Created by アナスタシア on 2015/11/26.
//  Copyright 2009-2016 Atelier Shiori. All rights reserved. Code licensed under New BSD License
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
