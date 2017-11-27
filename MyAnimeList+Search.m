//
//  MyAnimeList+Search.m
//  MAL Updater OS X
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList+Search.h"
#import "MyAnimeList+Keychain.h"
#import <EasyNSURLConnection/EasyNSURLConnection.h>
#import "Utility.h"
#import "ExceptionsCache.h"
#import "Recognition.h"
#import <XMLReader/XMLReader.h>

@implementation MyAnimeList (Search)
- (NSString *)searchanime{
    // Searches for ID of associated title
    NSString *searchtitle = self.DetectedTitle;
    if (self.DetectedSeason > 1) {
        // Specifically search for season
        for (int i = 0; i < 2; i++) {
            NSString *tmpid;
            switch (i) {
                case 0:
                    tmpid = [self performSearch:[NSString stringWithFormat:@"%@ %i", [Utility desensitizeSeason:searchtitle], self.DetectedSeason]];
                    break;
                case 1:
                    tmpid = [self performSearch:[NSString stringWithFormat:@"%@ %@ Season", [Utility desensitizeSeason:searchtitle], [Utility numbertoordinal:self.DetectedSeason]]];
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
- (NSString *)performSearch:(NSString *)searchtitle{
    NSLog(@"Searching For Title");
    //Escape Search Term
    NSString *searchterm = [Utility urlEncodeString:searchtitle];
    
    //Set Search API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://myanimelist.net/api/anime/search.xml?q=%@", searchterm]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    [Utility setUserAgent:request];
    //Set Token
    request.headers = (NSMutableDictionary *)@{@"Authorization": [NSString stringWithFormat:@"Basic %@", [self getBase64]]};
    //Ignore Cookies
    [request setUseCookies:NO];
    //Perform Search
    [request startRequest];
    
    // Get Status Code
    long statusCode = [request getStatusCode];
    switch (statusCode) {
        case 0:
            self.Success = NO;
            return @"";
        case 200:
            return [self findaniid:[request getResponseDataString] searchterm:searchtitle];
        default:
            self.Success = NO;
            return @"";
    }
    
}
- (NSString *)findaniid:(NSString *)ResponseData searchterm:(NSString *)term {
    // Parse XML
    NSArray *searchdata = [self MALSearchXMLToAtarashiiDataFormat:ResponseData];
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSSortDescriptor *descriptor2 = [[NSSortDescriptor alloc] initWithKey:@"english_title" ascending:YES];
    searchdata = [searchdata sortedArrayUsingDescriptors:@[descriptor, descriptor2]];
    //Initalize NSString to dump the title temporarily
    NSString *theshowtitle = @"";
    NSString *alttitle = @"";
    //Create Regular Expressions
    OnigRegexp    *regex;
    // Check if title is a movie or not.
    self.DetectedTitleisMovie = [self.DetectedType isEqualToString:@"Movie"] || [self.DetectedType isEqualToString:@"movie"] ? true : false;
    NSLog(@"%@", [self.DetectedType isEqualToString:@"Movie"] || [self.DetectedType isEqualToString:@"movie"] ? @"Title is a movie" : @"Title is not a movie.");
    // Create a filtered Arrays
    NSArray *sortedArray = [self filterArray:searchdata];
    searchdata = nil;
    // Used for String Comparison
    NSDictionary *titlematch1;
    NSDictionary *titlematch2;
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
                break;
            default:
                break;
        }
        for (NSDictionary *searchentry in sortedArray) {
            theshowtitle = (NSString *)searchentry[@"title"];
            NSArray *a = @[];
            //Populate Synonyms if any.
            if (((NSArray *)searchentry[@"synonyms"]).count > 0) {
                a = searchentry[@"synonyms"];
            }
            else {alttitle = @"";}
            // Remove colons as they are invalid characters for filenames and to improve accuracy
            theshowtitle = [theshowtitle stringByReplacingOccurrencesOfString:@":" withString:@""];
            int matchstatus;
            if (((NSArray *)searchentry[@"synonyms"]).count > 0) {
                for (NSString *syn in a) {
                    alttitle = syn;
                    alttitle = [alttitle stringByReplacingOccurrencesOfString:@":" withString:@""];
                    matchstatus = [Utility checkMatch:theshowtitle alttitle:alttitle regex:regex option:i];
                    if (matchstatus == 1 || matchstatus == 2) {
                        break;
                    }
                }
            }
            else {
                matchstatus = [Utility checkMatch:theshowtitle alttitle:alttitle regex:regex option:i];
            }
            if (matchstatus == 1 || matchstatus == 2) {
                if ([[NSString stringWithFormat:@"%@", searchentry[@"type"]] isEqualToString:@"TV"]) { // Check Seasons if the title is a TV show type
                    // Used for Season Checking
                    OnigRegexp    *regex2 = [OnigRegexp compile:[NSString stringWithFormat:@"((%i(st|nd|rd|th)|%@) season|\\W%i)", self.DetectedSeason, [Utility seasonInWords:self.DetectedSeason],self.DetectedSeason] options:OnigOptionIgnorecase];
                    OnigResult *smatch = [regex2 search:[NSString stringWithFormat:@"%@ - %@",theshowtitle, alttitle]];
                    // Description checking
                    NSString *description = searchentry[@"synopsis"] ? (NSString *)searchentry[@"synopsis"] : @"";
                    OnigResult *smatch2 = [regex2 search:description];
                    if (self.DetectedSeason >= 2) { // Season detected, check to see if there is a match. If not, continue.
                        if (smatch.count == 0 && smatch2.count == 0 && [sortedArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"TV"]].count > 1) { // If there is a second season match, in most cases, it would be the only entry
                            continue;
                        }
                    }
                    else {
                        if (smatch.count > 0 && smatch2.count > 0 && self.DetectedSeason >= 2) { // No Season, check to see if there is a season or not. If so, continue.
                            continue;
                        }
                    }
                }
                if (self.DetectedTitleisMovie) {
                    self.DetectedEpisode = @"1"; // Usually, there is one episode in a movie.
                    if ([[NSString stringWithFormat:@"%@", searchentry[@"type"]] isEqualToString:@"Special"]||[[NSString stringWithFormat:@"%@", searchentry[@"type"]] isEqualToString:@"OVA"]) {
                        self.DetectedTitleisMovie = false;
                    }
                }
                //Return titleid if episode is valid
                if ( ([NSString stringWithFormat:@"%@", searchentry[@"episodes"]].intValue == 0 || ([NSString stringWithFormat:@"%@",searchentry[@"episodes"]].intValue >= (self.DetectedEpisode).intValue))) {
                    NSLog(@"Valid Episode Count");
                    if (sortedArray.count == 1 || self.DetectedSeason >= 2) {
                        return [self foundtitle:[NSString stringWithFormat:@"%@",searchentry[@"id"]] info:searchentry];
                    }
                    else if (!titlematch1 && sortedArray.count > 1 && ((term.length < theshowtitle.length+1)||(term.length< alttitle.length && alttitle.length > 0 && matchstatus == 2))) {
                        mstatus = matchstatus;
                        titlematch1 = searchentry;
                        continue;
                    }
                    else if (titlematch1) {
                        titlematch2 = searchentry;
                        return titlematch1 != titlematch2 ? [self comparetitle:term match1:titlematch1 match2:titlematch2 mstatus:mstatus mstatus2:matchstatus] : [self foundtitle:[NSString stringWithFormat:@"%@",searchentry[@"id"]] info:searchentry];
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
- (NSArray *)filterArray:(NSArray *)searchdata{
    NSMutableArray *sortedArray;
    if (self.DetectedTitleisMovie) {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)" , @"Movie"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Special"]]];
    }
    else if (self.DetectedTitleisEpisodeZero) {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(title CONTAINS %@)" , @"Episode 0"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Special"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Movie"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"OVA"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"ONA"]]];
    }
    else {
        // Check if there is any type keywords. If so, only focus on that show type
        if (self.DetectedType.length > 0) {
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type ==[c] %@)", self.DetectedType]]];
        }
        else {
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"TV"]]];
            [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"ONA"]]];
            if (self.DetectedSeason == 1 | self.DetectedSeason == 0) {
                [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Special"]]];
                [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"OVA"]]];
            }
        }
    }
    return sortedArray;
}
- (NSString *)foundtitle:(NSString *)titleid info:(NSDictionary *)found{
    //Check to see if Seach Cache is enabled. If so, add it to the cache.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"] && titleid.length > 0) {
        NSNumber *episodes = found[@"episodes"] == [NSNull null] ? @(0) : (NSNumber *)found[@"episodes"];
        //Save AniID
        [ExceptionsCache addtoCache:self.DetectedTitle showid:titleid actualtitle:(NSString *)found[@"title"] totalepisodes:episodes.intValue detectedSeason:self.DetectedSeason];
    }
    //Return the AniID
    return titleid;
}

- (NSString *)comparetitle:(NSString *)title match1:(NSDictionary *)match1 match2:(NSDictionary *)match2 mstatus:(int)a mstatus2:(int)b{
    // Perform string score between two titles to see if one is the correct match or not
    float score1, score2, ascore1, ascore2;
    double fuzziness = 0.3;
    int season1 = ((NSNumber *)[[Recognition alloc] recognize:match1[@"title"]][@"season"]).intValue;
    int season2 = ((NSNumber *)[[Recognition alloc] recognize:match2[@"title"]][@"season"]).intValue;
    //Score first title
    score1 = string_fuzzy_score(title.UTF8String, [NSString stringWithFormat:@"%@", match1[@"title"]].UTF8String, fuzziness);
    ascore1 = [self gethighestsynonymscore:match1[@"synonyms"] withTitle:title];
    //Score Second Title
    score2 = string_fuzzy_score(title.UTF8String, [NSString stringWithFormat:@"%@", match2[@"title"]].UTF8String, fuzziness);
    ascore2 = [self gethighestsynonymscore:match1[@"synonyms"] withTitle:title];
    NSLog(@"%@ score - %f", match1[@"title"], score1);
    NSLog(@"%@ score - %f", match2[@"title"], score2);
    NSLog(@"%@ ascore - %f", match1[@"title"], ascore1);
    NSLog(@"%@ ascore - %f", match2[@"title"], ascore2);

    //First Season Score Bonus
    if (self.DetectedSeason == 0 || self.DetectedSeason == 1) {
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
    if ( season1 != self.DetectedSeason) {
        ascore1 = ascore1 - .5;
        score1 = score1 - .5;
    }
    if ( season2 != self.DetectedSeason) {
        ascore2 = ascore2 - .5;
        score2 = score2 - .5;
    }
    
    // Take the highest of both matches scores
    float finalscore1 = score1 > ascore1 ? score1 : ascore1;
    float finalscore2 = score2 > ascore2 ? score2 : ascore2;
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
- (NSArray *)MALSearchXMLToAtarashiiDataFormat:(NSString *)xml {
    NSError *error = nil;
    NSDictionary *d = [XMLReader dictionaryForXMLString:xml options:XMLReaderOptionsProcessNamespaces error:&error];
    NSArray *searchresults;
    if (d[@"anime"]) {
        searchresults = d[@"anime"][@"entry"];
        if (![searchresults isKindOfClass:[NSArray class]]) {
            // Import only contains one object, put it in an array.
            searchresults = @[searchresults];
        }
    }
    else {
        return @[];
    }
    NSMutableArray *output = [NSMutableArray new];
    for (NSDictionary *d in searchresults) {
        NSMutableArray *synonyms = [NSMutableArray new];
        NSString *englishtitle = @"";
        if (d[@"english"][@"text"]) {
            [synonyms addObject:d[@"english"][@"text"]];
            englishtitle = d[@"english"][@"text"];
        }
        if (d[@"synonyms"][@"text"]) {
            [synonyms addObjectsFromArray:[((NSString *)d[@"synonyms"][@"text"]) componentsSeparatedByString:@";"]];
        }
        [output addObject:@{@"id":@(((NSString *)d[@"id"][@"text"]).intValue), @"episodes":@(((NSString *)d[@"episodes"][@"text"]).intValue), @"score":@(((NSString *)d[@"score"][@"text"]).floatValue), @"status":d[@"status"][@"text"], @"start_date":[NSString stringWithFormat:@"%@",d[@"start_date"][@"text"]], @"end_date":[NSString stringWithFormat:@"%@",d[@"end_date"][@"text"]], @"synonyms": synonyms, @"synopsis":[NSString stringWithFormat:@"%@",d[@"synopsis"][@"text"]], @"type":d[@"type"][@"text"], @"title":d[@"title"][@"text"], @"english_title":englishtitle}];
    }
    return output;
}
- (float)gethighestsynonymscore:(NSArray *)synonyms withTitle:(NSString *)title {
    float score = 0;
    for (NSString *synonym in synonyms ) {
        float tmpscore = string_fuzzy_score(title.UTF8String, synonym.UTF8String, 0.3);
        if (tmpscore > score) {
            score = tmpscore;
        }
    }
    return score;
}
@end
