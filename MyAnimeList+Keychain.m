//
//  MyAnimeList+Keychain.m
//  MAL Updater OS X
//
//  Created by アナスタシア on 2015/11/26.
//  Copyright 2009-2016 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList+Keychain.h"
#import <EasyNSURLConnection/EasyNSURLConnection.h>
#import <SAMKeychain/SAMKeychain.h>
#import "Base64Category.h"

@implementation MyAnimeList (Keychain)
- (BOOL)checkaccount{
    // This method checks for any accounts that Hachidori can use
    NSArray *accounts = [SAMKeychain accountsForService:@"MAL Updater OS X"];
    if (accounts > 0) {
        //retrieve first valid account
        for (NSDictionary *account in accounts) {
                self.username = (NSString *)account[@"acct"];
                return true;
        }
        
        
    }
    self.username = @"";
    return false;
}
- (NSString *)getusername{
    return self.username;
}
- (BOOL)storeaccount:(NSString *)uname password:(NSString *)password{
    //Clear Account Information in the plist file if it hasn't been done already
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"" forKey:@"Base64Token"];
    [defaults setObject:@"" forKey:@"Username"];
    return [SAMKeychain setPassword:password forService:@"MAL Updater OS X" account:uname];
}
- (BOOL)removeaccount{
    bool success = [SAMKeychain deletePasswordForService:@"MAL Updater OS X" account:self.username];
    // Set Username to blank
    self.username = @"";
    return success;
}
- (NSString *)getBase64{
    return [[NSString stringWithFormat:@"%@:%@", [self getusername], [SAMKeychain passwordForService:@"MAL Updater OS X" account:self.username]] base64Encoding];
}

- (int)checkMALCredentials {
    // Check if the credentialsvalid flag is not set to false/NO
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"credentialsvalid"]) {
        return 0;
    }
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"credentialscheckdate"] timeIntervalSinceNow] < 0) {
        // Check credentials
        //Set Login URL
        NSURL *url = [NSURL URLWithString:@"https://myanimelist.net/api/account/verify_credentials.xml"];
        EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
        //Ignore Cookies
        [request setUseCookies:NO];
        //Set Username and Password
        request.headers = (NSMutableDictionary *)@{@"Authorization": [NSString stringWithFormat:@"Basic %@", [self getBase64]]};
        //Verify Username/Password
        [request startRequest];
        // Check for errors
        NSError *error = [request getError];
        if ([request getStatusCode] == 200 && !error) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSinceNow:60*60*24] forKey:@"credentialscheckdate"];
            NSLog(@"User credentials valid.");
            return 1;
        }
        else if ([request getStatusCode] == 204) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"credentialsvalid"];
            NSLog(@"ERROR: User credentials are invalid. Aborting...");
            return 0;
        }
        else {
            NSLog(@"Unable to check user credentials. Trying again later.");
            return 2;
        }
    }
    return 1;
   
    
}


@end
