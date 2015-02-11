//
//  MyAnimeList+Search.m
//  MAL Updater OS X
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList+Search.h"
#import "EasyNSURLConnection.h"
#import "Utility.h"
#import "ExceptionsCache.h"

@implementation MyAnimeList (Search)
-(NSString *)searchanime{
    // Searches for ID of associated title
    NSString * searchtitle = DetectedTitle;
    if (DetectedSeason > 1) {
        // Specifically search for season
        for (int i = 0; i < 2; i++) {
            NSString * tmpid;
            switch (i) {
                case 0:
                    tmpid = [self performSearch:[NSString stringWithFormat:@"%@ %i", [Utility desensitizeSeason:searchtitle], DetectedSeason]];
                    break;
                case 1:
                    tmpid = [self performSearch:[NSString stringWithFormat:@"%@ %i season", [Utility desensitizeSeason:searchtitle], DetectedSeason]];
                default:
                    break;
            }
            if (tmpid.length > 0) {
                return tmpid;
            }
        }
    }
    else{
        return [self performSearch:searchtitle]; //Perform Regular Search
    }
    return [self performSearch:searchtitle];
}
-(NSString *)performSearch:(NSString *)searchtitle{
    NSLog(@"Searching For Title");
    //Escape Search Term
    NSString * searchterm = [Utility urlEncodeString:searchtitle];
    
    //Set Search API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/anime/search?q=%@",MALApiUrl, searchterm]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Perform Search
    [request startRequest];
    
    // Get Status Code
    int statusCode = [request getStatusCode];
    switch (statusCode) {
        case 0:
            online = false;
            Success = NO;
            return @"";
            break;
        case 200:
            online = true;
            return [self findaniid:[request getResponseData] searchterm:searchtitle];
            break;
            
        default:
            online = true;
            Success = NO;
            return @"";
            break;
    }
    
}
-(NSString *)findaniid:(NSData *)ResponseData searchterm:(NSString *)term{
    // Initalize JSON parser and parse data
    NSError* error;
    NSArray *searchdata = [NSJSONSerialization JSONObjectWithData:ResponseData options:kNilOptions error:&error];
    //Initalize NSString to dump the title temporarily
    NSString *theshowtitle = @"";
    NSString *alttitle = @"";
    //Create Regular Expressions
    OGRegularExpression    *regex;
    // For Sanity (TV shows and OVAs usually have more than one episode)
    if(DetectedEpisode.length == 0){
        // Title is a movie
        NSLog(@"Title is a movie");
        DetectedTitleisMovie = true;
    }
    else{
        // Is TV Show
        NSLog(@"Title is not a movie.");
        DetectedTitleisMovie = false;
    }
    // Create a filtered Arrays
    NSArray * sortedArray = [self filterArray:searchdata];
    searchdata = nil;
    // Search
    for (int i = 0; i < 2; i++) {
        switch (i) {
            case 0:
                regex = [OGRegularExpression regularExpressionWithString:[NSString stringWithFormat:@"(%@)",term] options:OgreIgnoreCaseOption];
                break;
            case 1:
                regex = [OGRegularExpression regularExpressionWithString:[[NSString stringWithFormat:@"(%@)",term] stringByReplacingOccurrencesOfString:@" " withString:@"|"] options:OgreIgnoreCaseOption];
                break;
            default:
                break;
        }
        if (DetectedTitleisMovie) {
            //Check movies, specials and OVA
            for (NSDictionary *searchentry in sortedArray) {
                theshowtitle = (NSString *)[searchentry objectForKey:@"title"];
                //Populate Synonyms if any.
                if ([(NSDictionary *)[searchentry objectForKey:@"other_titles"] count] > 0) {
                    if ([(NSDictionary *)[searchentry objectForKey:@"other_titles"] objectForKey:@"synonyms"] != nil) {
                        NSArray * a = [(NSDictionary *)[searchentry objectForKey:@"other_titles"] objectForKey:@"synonyms"];
                        for (NSString * synonym in a ) {
                            alttitle = [NSString stringWithFormat:@"- %@  %@", synonym, alttitle];
                        }
                    }
                }
                else{alttitle = @"";}
                
                if ([Utility checkMatch:theshowtitle alttitle:alttitle regex:regex option:i]) {
                }
                DetectedEpisode = @"1"; // Usually, there is one episode in a movie.
                if ([[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"type"]] isEqualToString:@"Special"]||[[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"type"]] isEqualToString:@"OVA"]) {
                    DetectedTitleisMovie = false;
                }
                //Return titleid
                return [self foundtitle:[NSString stringWithFormat:@"%@",[searchentry objectForKey:@"id"]] info:searchentry];
            }
        }
        // Check TV, ONA, Special, OVA, Other
        for (NSDictionary *searchentry in sortedArray) {
            theshowtitle = (NSString *)[searchentry objectForKey:@"title"];
            //Populate Synonyms if any.
            if ([(NSDictionary *)[searchentry objectForKey:@"other_titles"] count] > 0) {
                if ([(NSDictionary *)[searchentry objectForKey:@"other_titles"] objectForKey:@"synonyms"] != nil) {
                    NSArray * a = [(NSDictionary *)[searchentry objectForKey:@"other_titles"] objectForKey:@"synonyms"];
                    for (NSString * synonym in a ) {
                        alttitle = [NSString stringWithFormat:@"- %@  %@", synonym, alttitle];
                    }
                }
            }
            else{alttitle = @"";}
            if ([Utility checkMatch:theshowtitle alttitle:alttitle regex:regex option:i]) {
                if ([[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"type"]] isEqualToString:@"TV"]) { // Check Seasons if the title is a TV show type
                    // Used for Season Checking
                    OGRegularExpression    *regex2 = [OGRegularExpression regularExpressionWithString:[NSString stringWithFormat:@"((%i(st|nd|rd|th)|%@) season|\\W%i)", DetectedSeason, [Utility seasonInWords:DetectedSeason],DetectedSeason] options:OgreIgnoreCaseOption];
                    OGRegularExpressionMatch * smatch = [regex2 matchInString:[NSString stringWithFormat:@"%@ - %@",theshowtitle, alttitle]];
                    // Description check
                    OGRegularExpressionMatch * smatch2 = [regex2 matchInString:(NSString *)[searchentry objectForKey:@"synopsis"]];
                    if (DetectedSeason >= 2) { // Season detected, check to see if there is a match. If not, continue.
                        if (smatch == nil && smatch2 == nil && [[sortedArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"TV"]] count] > 1) { // If there is a second season match, in most cases, it would be the only entry
                            continue;
                        }
                    }
                    else{
                        if (smatch != nil && smatch2 != nil && DetectedSeason >= 2) { // No Season, check to see if there is a season or not. If so, continue.
                            continue;
                        }
                    }
                }
                //Return titleid if episode is valid
                if ( [[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"episodes"]] intValue] == 0 || ([[NSString stringWithFormat:@"%@",[searchentry objectForKey:@"episodes"]] intValue] >= [DetectedEpisode intValue])) {
                    NSLog(@"Valid Episode Count");
                    return [self foundtitle:[NSString stringWithFormat:@"%@",[searchentry objectForKey:@"id"]] info:searchentry];
                }
                else{
                    // Detected episodes exceed total episodes
                    continue;
                }
                
            }
        }
    }
    // Nothing found, return empty string
    return @"";
}
-(NSArray *)filterArray:(NSArray *)searchdata{
    NSMutableArray * sortedArray;
    if (DetectedTitleisMovie) {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)" , @"Movie"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Special"]]];
    }
    else{
        // Check if there is any type keywords. If so, only focus on that show type
        OGRegularExpression * check = [OGRegularExpression regularExpressionWithString:@"(Special|OVA|ONA)" options:OgreIgnoreCaseOption];
        if ([check matchInString:DetectedTitle]) {
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type LIKE %@)", [[check matchInString:DetectedTitle] matchedString]]]];
        }
        else{
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"TV"]]];
            [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"ONA"]]];
            if (DetectedSeason == 1 | DetectedSeason == 0) {
                [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Special"]]];
                [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"OVA"]]];
            }
        }
    }
    return sortedArray;
}
-(NSString *)foundtitle:(NSString *)titleid info:(NSDictionary *)found{
    //Check to see if Seach Cache is enabled. If so, add it to the cache.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"] && titleid.length > 0) {
        //Save AniID
        [ExceptionsCache addtoCache:DetectedTitle showid:titleid actualtitle:(NSString *)[found objectForKey:@"title"] totalepisodes:[(NSNumber *)[found objectForKey:@"episodes"] intValue] ];
    }
    //Return the AniID
    return titleid;
}

@end
