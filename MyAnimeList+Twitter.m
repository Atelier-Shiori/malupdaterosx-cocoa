//
//  MyAnimeList+Twitter.m
//  MAL Updater OS X
//
//  Created by 天々座理世 on 2018/01/24.
//

#import "MyAnimeList+Twitter.h"
#import <TwitterManagerKit/TwitterManagerKit.h>

@implementation MyAnimeList (Twitter)
- (void)postaddanimetweet {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"twitteraddanime"] && [NSUserDefaults.standardUserDefaults boolForKey:@"tweetonscrobble"] && !self.testing) {
        [self performtweet:[NSUserDefaults.standardUserDefaults objectForKey:@"twitteraddanimeformat"]];
    }
}
- (void)postupdateanimetweet {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"twitterupdateanime"] && [NSUserDefaults.standardUserDefaults boolForKey:@"tweetonscrobble"] && !self.testing) {
        [self performtweet:[NSUserDefaults.standardUserDefaults objectForKey:@"twitterupdateanimeformat"]];
    }
}
- (void)postupdatestatustweet {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"twitterupdatestatus"] && [NSUserDefaults.standardUserDefaults boolForKey:@"tweetonscrobble"] && !self.testing) {
        [self performtweet:[NSUserDefaults.standardUserDefaults objectForKey:@"twitterupdatestatusformat"]];
    }
}

- (void)performtweet:(NSString *)format {
    if ([self.twittermanager accountexists]) {
        [self.twittermanager postTweet:[self generateTweetStringWithFormat:format] completion:^(bool success) {
            if (success) {
                NSLog(@"Tweet successful.");
            }
        } error:^(NSError *error) {
            NSLog(@"Error posting tweet: %@", error.localizedDescription);
        }];
    }
}

- (NSString *)generateTweetStringWithFormat:(NSString *)formatstring {
    NSString *tmpstr = formatstring;
    // Replace $title% with actual title
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%title%" withString:self.LastScrobbledActualTitle];
    // Replace %status% with actual status
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%status%" withString:self.WatchStatus];
    // Replace %episode% with actual episode number
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%episode%" withString:self.LastScrobbledEpisode];
    // Replace %malurl% with actual MAL URL
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%malurl%" withString:[NSString stringWithFormat:@"https://myanimelist.net/anime/%@", self.AniID]];
    // Replace %score$ with the actual score
        tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%score%" withString:[NSString stringWithFormat:@"%i/10", self.TitleScore]];
    return tmpstr;
}
@end
