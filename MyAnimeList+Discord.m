//
//  MyAnimeList+Discord.m
//  MAL Updater OS X
//
//  Created by 小鳥遊六花 on 1/31/18.
//

#import "MyAnimeList+Discord.h"

@implementation MyAnimeList (Discord)
- (void)sendDiscordPresence {
    if (self.discordmanager.discordrpcrunning) {
        [self.discordmanager UpdatePresence:[NSString stringWithFormat:@"Episode %@ in %@", self.LastScrobbledEpisode, self.LastScrobbledSource] withDetails:[NSString stringWithFormat:@"%@ %@", self.WatchStatus, self.LastScrobbledActualTitle ]];
    }
}
@end
