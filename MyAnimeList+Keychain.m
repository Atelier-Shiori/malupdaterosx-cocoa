//
//  MyAnimeList+Keychain.m
//  MAL Updater OS X
//
//  Created by アナスタシア on 2015/11/26.
//  Copyright 2009-2016 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList+Keychain.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>
#import "Base64Category.h"

@implementation MyAnimeList (Keychain)
-(BOOL)checkaccount{
    // This method checks for any accounts that Hachidori can use
    NSArray * accounts = [SSKeychain accountsForService:@"MAL Updater OS X"];
    if (accounts > 0) {
        //retrieve first valid account
        for (NSDictionary * account in accounts) {
                username = (NSString *)account[@"acct"];
                return true;
        }
        
        
    }
    username = @"";
    return false;
}
-(NSString *)getusername{
    return username;
}
-(BOOL)storeaccount:(NSString *)uname password:(NSString *)password{
    //Clear Account Information in the plist file if it hasn't been done already
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"" forKey:@"Base64Token"];
    [defaults setObject:@"" forKey:@"Username"];
    return [SSKeychain setPassword:password forService:@"MAL Updater OS X" account:uname];
}
-(BOOL)removeaccount{
    bool success = [SSKeychain deletePasswordForService:@"MAL Updater OS X" account:username];
    // Set Username to blank
    username = @"";
    return success;
}
-(NSString *)getBase64{
    return [[NSString stringWithFormat:@"%@:%@", [self getusername], [SSKeychain passwordForService:@"MAL Updater OS X" account:username]] base64Encoding];
}

@end
