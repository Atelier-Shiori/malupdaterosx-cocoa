//
//  AnimeRelations.m
//  MAL Updater OS X
//
//  Created by 小鳥遊六花 on 5/7/18.
//

#import "AnimeRelations.h"
#import <AFNetworking/AFNetworking.h>
#import "MAL_Updater_OS_XAppDelegate.h"
#import <CocoaOniguruma/OnigRegexp.h>
#import <CocoaOniguruma/OnigRegexpUtility.h>

@implementation AnimeRelations
+ (NSManagedObjectContext *)mangaObjectContext {
    return ((MAL_Updater_OS_XAppDelegate *)NSApplication.sharedApplication.delegate).managedObjectContext;
}

+ (void)updateRelations {
    AFHTTPSessionManager *manager = [self manager];
    NSError *error;
    NSURLSessionDataTask *task;
    id responseObject = [manager syncGET:@"https://github.com/erengy/anime-relations/raw/master/anime-relations.txt" parameters:nil task:&task error:&error];
    // Get Status Code
    switch (((NSHTTPURLResponse *)task.response).statusCode) {
        case 200:{
            NSLog(@"Updating Anime Relations!");
            [self processAnimeRelations:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]];
            // Set the last updated date
            [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"AnimeRelationsLastUpdated"];
            break;
        }
        default:
            NSLog(@"Anime Relations Update Failed!");
            break;
    }
}

+ (void)processAnimeRelations:(NSString *)data {
    NSArray *rules = [self seperaterules:data];
    for (NSString *rulestr in rules) {
        @autoreleasepool {
            //Split Rules
            OnigRegexp *regex = [OnigRegexp compile:@"\\d+\\|(\\d+|\\?)\\|(\\d+|\\?):(\\d+-(\\d+|\\?)|\\d+) "];
            NSArray *strings = [regex search:rulestr].strings;
            NSString *sourcerule = strings[0] ? strings[0] : @"";
            regex = [OnigRegexp compile:@"-> (~\\|~\\|~:(\\d+-(\\d+|\\?)|\\d+)|\\d+\\|(\\d+|\\?)\\|(\\d+|\\?):(\\d+-(\\d+|\\?)|\\d+))(|!|~|\\?)"];
            strings = [regex search:rulestr].strings;
            NSString *targetrule = strings[0] ? strings[0] : @"";
            targetrule = [targetrule stringByReplacingOccurrencesOfString:@"-> " withString:@""];
            // Check rules split
            if (sourcerule.length == 0 && targetrule.length == 0) {
                continue;
            }
            //Parse source rule
            regex = [OnigRegexp compile:@"\\d+\\|(\\d+|\\?)\\|(\\d+|\\?)"];
            strings = [regex search:sourcerule].strings;
            NSString *tmpsourcemalid = strings[0] ? strings[0] : @"";
            tmpsourcemalid = [tmpsourcemalid replaceByRegexp:[OnigRegexp compile:@"\\|(\\d+|\\?)\\|(\\d+|\\?)"] with:@""];
            regex = [OnigRegexp compile:@":(\\d+-(\\d+|\\?)|\\d+)"];
            strings = [regex search:sourcerule].strings;
            NSString *tmpepisodestr = strings[0] ? strings[0] : @"";
            tmpepisodestr = [tmpepisodestr stringByReplacingOccurrencesOfString:@":" withString:@""];
            NSNumber *sourcefromep;
            NSNumber *sourcetoep;
            bool iszeroepisode = false;
            if ([tmpepisodestr rangeOfString:@"-"].location == NSNotFound) {
                sourcefromep = @(tmpepisodestr.intValue);
                sourcetoep = sourcefromep;
            }
            else {
                sourcefromep = @([tmpepisodestr replaceByRegexp:[OnigRegexp compile:@"-\\d+"] with:@""].intValue);
                sourcetoep = @([tmpepisodestr replaceByRegexp:[OnigRegexp compile:@"\\d+-"] with:@""].intValue);
            }
            
            if (sourcefromep.intValue == 0) {
                iszeroepisode = true;
            }
            
            //Parse target rule
            regex =  [OnigRegexp compile:@"(~\\|~\\|~|\\d+\\|(\\d+|\\?)\\|(\\d+|\\?))"];
            strings = [regex search:targetrule].strings;
            NSString *tmptargetmalid = strings[0] ? strings[0] : @"";
            tmptargetmalid =  [tmptargetmalid replaceByRegexp:[OnigRegexp compile:@"(\\|~\\|~|\\|(\\d+|\\?)\\|(\\d+|\\?))"] with:@""];
            if ([tmptargetmalid isEqualToString:@"~"]) {
                tmptargetmalid = tmpsourcemalid.copy;
            }
            regex = [OnigRegexp compile:@":(\\d+-(\\d+|\\?)|\\d+)(|!|~|\\?)"];
            strings = [regex search:targetrule].strings;
            tmpepisodestr = strings[0] ? strings[0] : @"";
            tmpepisodestr = [tmpepisodestr stringByReplacingOccurrencesOfString:@":" withString:@""];
            NSNumber *targetfromep;
            NSNumber *targettoep;
            NSString *targeteptype = [tmpepisodestr replaceByRegexp:[OnigRegexp compile:@":(\\d+-(\\d+|\\?)|\\d+)"] with:@""];
            tmpepisodestr = [tmpepisodestr stringByReplacingOccurrencesOfString:targetrule withString:@""];
            if ([tmpepisodestr rangeOfString:@"-"].location == NSNotFound) {
                targetfromep = @(tmpepisodestr.intValue);
                targettoep = targetfromep;
            }
            else {
                targetfromep = @([tmpepisodestr replaceByRegexp:[OnigRegexp compile:@"-\\d+"] with:@""].intValue);
                targettoep = @([tmpepisodestr replaceByRegexp:[OnigRegexp compile:@"\\d+-"] with:@""].intValue);
            }
            // Save Anime Relation
            [self saveRuleEntry:@{@"is_zeroepisode" : @(iszeroepisode), @"source_ep_from" : sourcefromep, @"source_ep_to" : sourcetoep, @"source_malid" : @(tmpsourcemalid.intValue), @"target_ep_from" : targetfromep, @"target_ep_to" : targettoep, @"target_episode_type" : targeteptype, @"target_malid" : @(tmptargetmalid.intValue)}];
        }
    }
}

+ (NSArray *)seperaterules:(NSString *)data {
    NSArray *tmparray = [data componentsSeparatedByString:@"\n"];
    OnigRegexp *titlematch = [OnigRegexp compile:@"- \\d+\\|(\\d+|\\?)\\|(\\d+|\\?):(\\d+-(\\d+|\\?)|\\d+) -> (~\\|~\\|~:(\\d+-(\\d+|\\?)|\\d+)|\\d+\\|(\\d+|\\?)\\|(\\d+|\\?):(\\d+-(\\d+|\\?)|\\d+))(!|~|\\?|)" options:OnigOptionIgnorecase];
    NSMutableArray *result = [NSMutableArray new];
    for (NSString *line in tmparray) {
        @autoreleasepool {
            if ([titlematch match:line]) {
                [result addObject:line.copy];
            }
        }
    }
    return result;
}

+ (void)saveRuleEntry:(NSDictionary *)rules {
    NSManagedObjectContext *moc = [self mangaObjectContext];
    [moc performBlockAndWait:^{
        NSError *error;
        NSManagedObject *obj = [self retrieveRelationsEntryForSourceTitleID:((NSNumber *)rules[@"source_malid"]).intValue withTargetId:((NSNumber *)rules[@"target_malid"]).intValue];
        if (obj) {
            // Update Entry
            [obj setValue:rules[@"is_zeroepisode"] forKey:@"is_zeroepisode"];
            [obj setValue:rules[@"source_ep_from"] forKey:@"source_ep_from"];
            [obj setValue:rules[@"source_ep_to"] forKey:@"source_ep_to"];
            [obj setValue:rules[@"target_ep_from"] forKey:@"target_ep_from"];
            [obj setValue:rules[@"target_ep_to"] forKey:@"target_ep_to"];
            [obj setValue:rules[@"target_episode_type"] forKey:@"target_episode_type"];
        }
        else {
            // Add Entry to Anime Relations Entity
            obj = [NSEntityDescription
                   insertNewObjectForEntityForName:@"AnimeRelations"
                   inManagedObjectContext: moc];
            // Set values in the new record
            // Update Entry
            [obj setValue:rules[@"source_malid"] forKey:@"source_malid"];
            [obj setValue:rules[@"target_malid"] forKey:@"target_malid"];
            [obj setValue:rules[@"is_zeroepisode"] forKey:@"is_zeroepisode"];
            [obj setValue:rules[@"source_ep_from"] forKey:@"source_ep_from"];
            [obj setValue:rules[@"source_ep_to"] forKey:@"source_ep_to"];
            [obj setValue:rules[@"target_ep_from"] forKey:@"target_ep_from"];
            [obj setValue:rules[@"target_ep_to"] forKey:@"target_ep_to"];
            [obj setValue:rules[@"target_episode_type"] forKey:@"target_episode_type"];
        }
        //Save
        [moc save:&error];
    }];
}

+ (NSManagedObject *)retrieveRelationsEntryForSourceTitleID:(int)sourceid withTargetId:(int)targetid {
    // Return existing Anime Relations rule
    NSError *error;
    NSManagedObjectContext *moc = [self mangaObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(source_malid == %i) AND (target_malid == %i)", sourceid,targetid];
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    fetch.entity = [NSEntityDescription entityForName:@"AnimeRelations" inManagedObjectContext:moc];
    fetch.predicate = predicate;
    NSArray *relations = [moc executeFetchRequest:fetch error:&error];
    if (relations.count > 0) {
        return (NSManagedObject *)relations[0];
    }
    return nil;
}

+ (NSArray *)retrieveRelationsEntriesForTitleID:(int)malid {
    // Return relations for MAL ID
    NSError *error;
    NSManagedObjectContext *moc = [self mangaObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(source_malid == %i)", malid];
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    fetch.entity = [NSEntityDescription entityForName:@"AnimeRelations" inManagedObjectContext:moc];
    fetch.predicate = predicate;
    NSArray *relations = [moc executeFetchRequest:fetch error:&error];
    return relations;
}

+ (void)clearAnimeRelations {
    // Clears Anime Relations data
    NSManagedObjectContext *moc = [self mangaObjectContext];
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    fetch.entity = [NSEntityDescription entityForName:@"AnimeRelations" inManagedObjectContext:moc];
    
    NSError *error = nil;
    NSArray *relations = [moc executeFetchRequest:fetch error:&error];
    for (NSManagedObject *relation in relations) {
        [moc deleteObject:relation];
    }
    error = nil;
    [moc save:&error];
}

+ (AFHTTPSessionManager*)manager {
    static dispatch_once_t ronceToken;
    static AFHTTPSessionManager *rmanager = nil;
    dispatch_once(&ronceToken, ^{
        rmanager = [AFHTTPSessionManager manager];
        rmanager.responseSerializer = [AFHTTPResponseSerializer serializer];
        rmanager.completionQueue = dispatch_queue_create("AFNetworking+Synchronous", NULL);
    });
    
    return rmanager;
}
@end
