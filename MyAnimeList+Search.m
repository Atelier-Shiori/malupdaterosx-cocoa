//
//  MyAnimeList+Search.m
//  MAL Updater OS X
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList+Search.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>
#import "Utility.h"
#import "ExceptionsCache.h"
#import "Recognition.h"

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
    else {
        return [self performSearch:searchtitle]; //Perform Regular Search
    }
    return [self performSearch:searchtitle];
}
-(NSString *)performSearch:(NSString *)searchtitle{
    NSLog(@"Searching For Title");
    //Escape Search Term
    NSString * searchterm = [Utility urlEncodeString:searchtitle];
    
    //Set Search API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/2.1/anime/search?q=%@",MALApiUrl, searchterm]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Perform Search
    [request startRequest];
    
    // Get Status Code
    long statusCode = [request getStatusCode];
    switch (statusCode) {
        case 0:
            online = false;
            Success = NO;
            return @"";
        case 200:
            online = true;
            return [self findaniid:[request getResponseData] searchterm:searchtitle];
        default:
            online = true;
            Success = NO;
            return @"";
    }
    
}
-(NSString *)findaniid:(NSData *)ResponseData searchterm:(NSString *)term{
    // Initalize JSON parser and parse data
    NSError* error;
    NSArray *searchdata = [NSJSONSerialization JSONObjectWithData:ResponseData options:nil error:&error];
    //Initalize NSString to dump the title temporarily
    NSString *theshowtitle = @"";
    NSString *alttitle = @"";
    //Create Regular Expressions
    OnigRegexp    *regex;
    // For Sanity (TV shows and OVAs usually have more than one episode)
    if(DetectedEpisode.length == 0) {
        // Title is a movie
        NSLog(@"Title is a movie");
        DetectedTitleisMovie = true;
    }
    else {
        // Is TV Show
        NSLog(@"Title is not a movie.");
        DetectedTitleisMovie = false;
    }
    // Create a filtered Arrays
    NSArray * sortedArray = [self filterArray:searchdata];
    searchdata = nil;
    // Used for String Comparison
    NSDictionary * titlematch1;
    NSDictionary * titlematch2;
    int mstatus = 0;
    // Remove Colons
    term = [term stringByReplacingOccurrencesOfString:@":" withString:@""];
    // Search
    for (int i = 0; i < 2; i++) {
        switch (i) {
            case 0:
                regex = [OnigRegexp compile:[NSString stringWithFormat:@"(%@)",term] options:OnigOptionIgnorecase];
                break;
            case 1:
                regex = [OnigRegexp compile:[[NSString stringWithFormat:@"(%@)",term] stringByReplacingOccurrencesOfString:@" " withString:@"|"] options:OnigOptionIgnorecase];
                //Invalidate Existing Matches
                titlematch1 = nil;
                break;
            default:
                break;
        }
        if (DetectedTitleisMovie) {
            //Check movies, specials and OVA
            for (NSDictionary *searchentry in sortedArray) {
                theshowtitle = (NSString *)searchentry[@"title"];
                //Populate Synonyms if any.
                if ([(NSDictionary *)searchentry[@"other_titles"] count] > 0) {
                    if (((NSDictionary *)searchentry[@"other_titles"])[@"synonyms"]) {
                        NSArray * a = ((NSDictionary *)searchentry[@"other_titles"])[@"synonyms"];
                        for (NSString * synonym in a ) {
                            alttitle = [NSString stringWithFormat:@"- %@  %@", synonym, alttitle];
                        }
                    }
                }
                else {alttitle = @"";}
                
                // Remove colons as they are invalid characters for filenames and to improve accuracy
                theshowtitle = [theshowtitle stringByReplacingOccurrencesOfString:@":" withString:@""];
                alttitle = [alttitle stringByReplacingOccurrencesOfString:@":" withString:@""];
                
                if ([Utility checkMatch:theshowtitle alttitle:alttitle regex:regex option:i]) {
                }
                DetectedEpisode = @"1"; // Usually, there is one episode in a movie.
                if ([[NSString stringWithFormat:@"%@", searchentry[@"type"]] isEqualToString:@"Special"]||[[NSString stringWithFormat:@"%@", searchentry[@"type"]] isEqualToString:@"OVA"]) {
                    DetectedTitleisMovie = false;
                }
                //Return titleid
                return [self foundtitle:[NSString stringWithFormat:@"%@",searchentry[@"id"]] info:searchentry];
            }
        }
        // Check TV, ONA, Special, OVA, Other
        for (NSDictionary *searchentry in sortedArray) {
            theshowtitle = (NSString *)searchentry[@"title"];
            //Populate Synonyms if any.
            if ([(NSDictionary *)searchentry[@"other_titles"] count] > 0) {
                if (((NSDictionary *)searchentry[@"other_titles"])[@"synonyms"]) {
                    NSArray * a = ((NSDictionary *)searchentry[@"other_titles"])[@"synonyms"];
                    for (NSString * synonym in a ) {
                        alttitle = [NSString stringWithFormat:@"- %@  %@", synonym, alttitle];
                    }
                }
            }
            else {alttitle = @"";}
            // Remove colons as they are invalid characters for filenames and to improve accuracy
            theshowtitle = [theshowtitle stringByReplacingOccurrencesOfString:@":" withString:@""];
            alttitle = [alttitle stringByReplacingOccurrencesOfString:@":" withString:@""];
            int matchstatus = [Utility checkMatch:theshowtitle alttitle:alttitle regex:regex option:i];
            if (matchstatus == 1 || matchstatus == 2) {
                if ([[NSString stringWithFormat:@"%@", searchentry[@"type"]] isEqualToString:@"TV"]) { // Check Seasons if the title is a TV show type
                    // Used for Season Checking
                    OnigRegexp    *regex2 = [OnigRegexp compile:[NSString stringWithFormat:@"((%i(st|nd|rd|th)|%@) season|\\W%i)", DetectedSeason, [Utility seasonInWords:DetectedSeason],DetectedSeason] options:OnigOptionIgnorecase];
                    OnigResult * smatch = [regex2 match:[NSString stringWithFormat:@"%@ - %@",theshowtitle, alttitle]];
                    // Description checking
					NSString * description;
					if (searchentry[@"synopsis"]) {
						description = (NSString *)searchentry[@"synopsis"];
					}
					else {
						description = @"";
					}
                    OnigResult * smatch2 = [regex2 match:description];
                    if (DetectedSeason >= 2) { // Season detected, check to see if there is a match. If not, continue.
                        if (!smatch && !smatch2 && [[sortedArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"TV"]] count] > 1) { // If there is a second season match, in most cases, it would be the only entry
                            continue;
                        }
                    }
                    else {
                        if (smatch && smatch2 && DetectedSeason >= 2) { // No Season, check to see if there is a season or not. If so, continue.
                            continue;
                        }
                    }
                }
                //Return titleid if episode is valid
                if ( [[NSString stringWithFormat:@"%@", searchentry[@"episodes"]] intValue] == 0 || ([[NSString stringWithFormat:@"%@",searchentry[@"episodes"]] intValue] >= [DetectedEpisode intValue])) {
                    NSLog(@"Valid Episode Count");
                    if (sortedArray.count == 1 || DetectedSeason >= 2) {
                        return [self foundtitle:[NSString stringWithFormat:@"%@",searchentry[@"id"]] info:searchentry];
                    }
                    else if (!titlematch1 && sortedArray.count > 1 && ((term.length < theshowtitle.length+1)||(term.length< alttitle.length && alttitle.length > 0 && matchstatus == 2))) {
                        mstatus = matchstatus;
                        titlematch1 = searchentry;
                        continue;
                    }
                    else if (titlematch1) {
                        titlematch2 = searchentry;
                        if (titlematch1 != titlematch2) {
                            return [self comparetitle:term match1:titlematch1 match2:titlematch2 mstatus:mstatus mstatus2:matchstatus];
                        }
                        else {
                            // Only Result, return
                            return [self foundtitle:[NSString stringWithFormat:@"%@",searchentry[@"id"]] info:searchentry];
                        }
                    }
                }
                else {
                    // Detected episodes exceed total episodes
                    continue;
                }
                
            }
        }
    }
    // If one match is found and not null, then return the id.
    if (titlematch1) {
        // Only Result, return
        return [self foundtitle:[NSString stringWithFormat:@"%@",titlematch1[@"id"]] info:titlematch1];
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
    else if (DetectedTitleisEpisodeZero) {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(title CONTAINS %@)" , @"Episode 0"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Special"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Movie"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"OVA"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"ONA"]]];
    }
    else {
        // Check if there is any type keywords. If so, only focus on that show type
        if (DetectedType.length > 0) {
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type ==[c] %@)", DetectedType]]];
        }
        else {
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
        NSNumber * episodes;
        if (found[@"episodes"] == [NSNull null]) {
            // Set no total episodes
            episodes = [NSNumber numberWithInt:0];
        }
        else {
            episodes = (NSNumber *)found[@"episodes"];
        }
        //Save AniID
        [ExceptionsCache addtoCache:DetectedTitle showid:titleid actualtitle:(NSString *)found[@"title"] totalepisodes:[episodes intValue]];
    }
    //Return the AniID
    return titleid;
}

-(NSString *)comparetitle:(NSString *)title match1:(NSDictionary *)match1 match2:(NSDictionary *)match2 mstatus:(int)a mstatus2:(int)b{
    // Perform string score between two titles to see if one is the correct match or not
    float score1, score2, ascore1, ascore2;
    double fuzziness = 0.3;
    int season1 = ((NSNumber *)[[Recognition alloc] recognize:match1[@"title"]][@"season"]).intValue;
    int season2 = ((NSNumber *)[[Recognition alloc] recognize:match2[@"title"]][@"season"]).intValue;
    //Score first title
    score1 = string_fuzzy_score(title.UTF8String, [[NSString stringWithFormat:@"%@", match1[@"title"]] UTF8String], fuzziness);
    ascore1 = string_fuzzy_score(title.UTF8String, [[NSString stringWithFormat:@"%@", [self generateAltTitles:match1[@"other_titles"]] ] UTF8String], fuzziness);
    //Score Second Title
    score2 = string_fuzzy_score(title.UTF8String, [[NSString stringWithFormat:@"%@", match2[@"title"]] UTF8String], fuzziness);
    ascore2 = string_fuzzy_score(title.UTF8String, [[NSString stringWithFormat:@"%@", [self generateAltTitles:match2[@"other_titles"]] ] UTF8String], fuzziness);
    NSLog(@"%@ score - %f", match1[@"title"], score1);
    NSLog(@"%@ score - %f", match2[@"title"], score2);
    NSLog(@"%@ ascore - %f", match1[@"title"], ascore1);
    NSLog(@"%@ ascore - %f", match2[@"title"], ascore2);

    //First Season Score Bonus
    if (DetectedSeason == 0 || DetectedSeason == 1) {
        if ([(NSString *)match1[@"title"] rangeOfString:@"First"].location != NSNotFound || [(NSString *)match1[@"title"] rangeOfString:@"1st"].location != NSNotFound) {
            score1 = score1 + .25;
            ascore1 = ascore1 + .25;
        }
        else if ([(NSString *)match2[@"title"] rangeOfString:@"First"].location != NSNotFound || [(NSString *)match2[@"title"] rangeOfString:@"1st"].location != NSNotFound) {
            score2 = score2 + .25;
            ascore2 = ascore2 + .25;
        }
    }
    //Season Scoring Calculation
    if ( season1 != DetectedSeason) {
        ascore1 = ascore1 - .5;
        score1 = score1 - .5;
    }
    if ( season2 != DetectedSeason) {
        ascore2 = ascore2 - .5;
        score2 = score2 - .5;
    }
    
    // Take the highest of both matches scores
    float finalscore1;
    float finalscore2;
    if(score1 > ascore1) {
        finalscore1 = score1;
    }
    else {
        finalscore1 = ascore1;
    }
    if(score2 > ascore2) {
        finalscore2 = score2;
    }
    else {
        finalscore2 = ascore2;
    }
    // Compare Scores
    if (finalscore1 == finalscore2 || finalscore1 == INFINITY) {
        //Scores can't be reliably compared, just return the first match
        return [self foundtitle:[NSString stringWithFormat:@"%@",match1[@"id"]] info:match1];
    }
    else if(finalscore1 > finalscore2)
    {
        //Return first title as it has a higher score
        return [self foundtitle:[NSString stringWithFormat:@"%@",match1[@"id"]] info:match1];
    }
    else {
        // Return second title since it has a higher score
        return [self foundtitle:[NSString stringWithFormat:@"%@",match2[@"id"]] info:match2];
    }
}
-(NSString *)generateAltTitles:(NSDictionary *)otitles{
    NSString * alttitle;
    if ([otitles count] > 0) {
        if (otitles[@"synonyms"]) {
            NSArray * a = otitles[@"synonyms"];
            for (NSString * synonym in a ) {
                alttitle = [NSString stringWithFormat:@"- %@  %@", synonym, alttitle];
            }
        }
    }
    else {alttitle = @"";}
    return alttitle;
}
@end
