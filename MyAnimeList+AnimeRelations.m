//
//  MyAnimeList+AnimeRelations.m
//  MAL Updater OS X
//
//  Created by 小鳥遊六花 on 5/7/18.
//

#import "MyAnimeList+AnimeRelations.h"
#import "AnimeRelations.h"

@implementation MyAnimeList (AnimeRelations)
- (int)checkAnimeRelations:(int)titleid {
    NSArray *relations = [AnimeRelations retrieveRelationsEntriesForTitleID:titleid];
    for (NSManagedObject *relation in relations) {
        @autoreleasepool {
            NSNumber *sourcefromepisode = [relation valueForKey:@"source_ep_from"];
            NSNumber *sourcetoepisode = [relation valueForKey:@"source_ep_to"];
            NSNumber *targetfromepisode = [relation valueForKey:@"target_ep_from"];
            NSNumber *targettoepisode = [relation valueForKey:@"target_ep_to"];
            NSNumber *iszeroepisode = [relation valueForKey:@"is_zeroepisode"];
            NSNumber *targetid = [relation valueForKey:@"target_malid"];
            if (self.DetectedEpisode.intValue < sourcefromepisode.intValue && self.DetectedEpisode.intValue > sourcetoepisode.intValue) {
                continue;
            }
            int tmpep = self.DetectedEpisode.intValue - (sourcefromepisode.intValue-1);
            if (tmpep > 0 && tmpep <= targettoepisode.intValue) {
                self.DetectedEpisode = @(tmpep).stringValue;
                return targetid.intValue;
            }
            else if (self.DetectedTitleisEpisodeZero && iszeroepisode.boolValue) {
                self.DetectedEpisode = targetfromepisode.stringValue;
                return targetid.intValue;
            }
            else if (self.DetectedTitleisMovie && targetfromepisode.intValue == targettoepisode.intValue) {
                self.DetectedEpisode = targetfromepisode.stringValue;
                return targetid.intValue;
            }
        }
    }
    return -1;
}
@end
