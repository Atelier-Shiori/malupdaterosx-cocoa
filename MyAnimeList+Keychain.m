//
//  MyAnimeList+Keychain.m
//  MAL Updater OS X
//
//  Created by アナスタシア on 2015/11/26.
//  Copyright 2009-2016 MAL Updater OS X Group. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList+Keychain.h"
#import "ClientConstants.h"
#import "Utility.h"

@implementation MyAnimeList (Keychain)
+ (NSString *)getKeychainServiceName {
    #ifdef DEBUG
    return @"MAL Updater OS X - DEBUG";
    #else
    return @"MAL Updater OS X";
    #endif
}
+ (BOOL)checkaccount {
    bool exists = [MyAnimeList retrieveCredentials];
    return exists;
}
+ (AFOAuthCredential *)retrieveCredentials {
    return [AFOAuthCredential retrieveCredentialWithIdentifier:[self getKeychainServiceName]];
}
- (NSString *)getusername {
    self.username = [NSUserDefaults.standardUserDefaults valueForKey:@"mal-username"];
    return self.username;
}
+ (NSString *)retrieveUsername {
    return [NSUserDefaults.standardUserDefaults valueForKey:@"mal-username"];
}
+ (BOOL)storeaccount:(AFOAuthCredential *)cred {
    return [AFOAuthCredential storeCredential:cred withIdentifier:[self getKeychainServiceName]];
}
- (BOOL)removeaccount{
    bool success = [AFOAuthCredential deleteCredentialWithIdentifier:[MyAnimeList getKeychainServiceName]];
    // Set Username to blank
     [NSUserDefaults.standardUserDefaults setObject:@"" forKey:@"mal-username"];
    self.username = @"";
    return success;
}

+ (bool)checkexpired {
    AFOAuthCredential * cred = [MyAnimeList retrieveCredentials];
    return cred.expired;
}

+ (void)refreshtoken:(void (^)(bool success)) completionHandler {
    AFOAuthCredential *cred =
    [AFOAuthCredential retrieveCredentialWithIdentifier:[MyAnimeList getKeychainServiceName]];
    NSURL *baseURL = [NSURL URLWithString:@"https://myanimelist.net/"];
    AFOAuth2Manager *OAuth2Manager = [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
                                                                     clientID:kMALClientID
                                                                       secret:kMALClientSecret];
    [OAuth2Manager setUseHTTPBasicAuthentication:NO];
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"/v1/oauth2/token"
                                            parameters:@{@"grant_type":@"refresh_token", @"refresh_token":cred.refreshToken} success:^(AFOAuthCredential *credential) {
                                                NSLog(@"Token refreshed");
                                                [self storeaccount:credential];
                                                completionHandler(true);
                                            }
                                               failure:^(NSError *error) {
                                                   NSLog(@"Token cannot be refreshed: %@", error);
                                                   completionHandler(false);
                                               }];
}

- (void)retrieveusername:(void (^)(bool success)) completionHandler {
    [self.asyncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [MyAnimeList retrieveCredentials].accessToken] forHTTPHeaderField:@"Authorization"];
    [self.asyncmanager GET:@"https://api.myanimelist.net/v0.20/users/@me?fields=name" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject[@"name"]) {
            [NSUserDefaults.standardUserDefaults setObject:responseObject[@"name"] forKey:@"mal-username"];
            completionHandler(true);
        }
        else {
            completionHandler(false);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        completionHandler(false);
    }];
}

@end
