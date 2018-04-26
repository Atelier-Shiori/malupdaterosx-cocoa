//
//  MyAnimeList+Keychain.m
//  MAL Updater OS X
//
//  Created by アナスタシア on 2015/11/26.
//  Copyright 2009-2016 MAL Updater OS X Group. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList+Keychain.h"
#import <EasyNSURLConnection/EasyNSURLConnection.h>
#import <AFNetworking/AFOAuth2Manager.h>
#import <SAMKeychain/SAMKeychain.h>
#import "ClientConstants.h"
#import "Utility.h"

@implementation MyAnimeList (Keychain)
- (NSString *)getKeychainServiceName {
    #ifdef DEBUG
    return @"MAL Updater OS X - DEBUG";
    #else
    return @"MAL Updater OS X";
    #endif
}
- (BOOL)checkaccount {
    bool exists = [self retrieveCredentials];
    return exists;
}
- (AFOAuthCredential *)retrieveCredentials {
    return [AFOAuthCredential retrieveCredentialWithIdentifier:[self getKeychainServiceName]];
}
- (NSString *)getusername {
    self.username = [NSUserDefaults.standardUserDefaults valueForKey:@"mal-username"];
    return self.username;
}
- (BOOL)storeaccount:(AFOAuthCredential *)cred {
    return [AFOAuthCredential storeCredential:cred withIdentifier:[self getKeychainServiceName]];
}
- (BOOL)removeaccount{
    bool success = [AFOAuthCredential deleteCredentialWithIdentifier:[self getKeychainServiceName]];
    // Set Username to blank
     [NSUserDefaults.standardUserDefaults setObject:@"" forKey:@"mal-username"];
    self.username = @"";
    return success;
}

- (bool)checkexpired {
    AFOAuthCredential * cred = [self retrieveCredentials];
    return cred.expired;
}

- (void)refreshtoken:(void (^)(bool success)) completionHandler {
    AFOAuthCredential *cred =
    [AFOAuthCredential retrieveCredentialWithIdentifier:[self getKeychainServiceName]];
    NSURL *baseURL = [NSURL URLWithString:@"https://myanimelist.net/"];
    AFOAuth2Manager *OAuth2Manager = [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
                                                                     clientID:kMALClientID
                                                                       secret:kMALClientSecret];
    [OAuth2Manager setUseHTTPBasicAuthentication:NO];
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"/v1/oauth2/token"
                                            parameters:@{@"grant_type":@"refresh_token", @"refresh_token":cred.refreshToken} success:^(AFOAuthCredential *credential) {
                                                NSLog(@"Token refreshed");
                                                completionHandler(true);
                                            }
                                               failure:^(NSError *error) {
                                                   NSLog(@"Token cannot be refreshed: %@", error);
                                                   completionHandler(false);
                                               }];
}

- (void)retrieveusername:(void (^)(bool success)) completionHandler {
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] init];
    [request setUseCookies:NO];
    [request GET:@"https://api.myanimelist.net/v0.20/users/@me?fields=name" headers:@{@"Authorization": [NSString stringWithFormat:@"Bearer %@", [self retrieveCredentials].accessToken]} completion:^(EasyNSURLResponse *response) {
        NSDictionary *responsedata = response.getResponseDataJsonParsed;
        if (responsedata[@"name"]) {
            [NSUserDefaults.standardUserDefaults setObject:responsedata[@"name"] forKey:@"mal-username"];
            completionHandler(true);
        }
        else {
            completionHandler(false);
        }
    } error:^(NSError *error, int statuscode) {
        completionHandler(false);
    }];
}

@end
