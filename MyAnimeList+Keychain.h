//
//  MyAnimeList+Keychain.h
//  MAL Updater OS X
//
//  Created by アナスタシア on 2015/11/26.
//  Copyright 2009-2016 MAL Updater OS X Group. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList.h"
#import <AFNetworking/AFOAuthCredential.h>

@interface MyAnimeList (Keychain)
- (BOOL)checkaccount;
- (AFOAuthCredential *)retrieveCredentials;
- (BOOL)storeaccount:(AFOAuthCredential *)cred;
- (BOOL)removeaccount;
- (NSString *)getusername;
- (bool)checkexpired;
- (void)refreshtoken:(void (^)(bool success)) completionHandler;
- (void)retrieveusername:(void (^)(bool success)) completionHandler;
@end
