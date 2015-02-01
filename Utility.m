//
//  Utility.m
//  MAL Updater OS X
//
//  Created by Tail Red on 1/31/15.
//
//

#import "Utility.h"

@implementation Utility
+(bool)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OGRegularExpression *)regex
           option:(int)i{
    //Checks for matches
    if ([regex matchInString:title] != nil || ([regex matchInString:atitle] != nil && [atitle length] >0 && i==0)) {
        return true;
    }
    return false;
}
+(NSString *)desensitizeSeason:(NSString *)title {
    // Get rid of season references
    OGRegularExpression* regex = [OGRegularExpression regularExpressionWithString: @"((first|second|third|fourth|fifth|sixth|seventh|eighth|nineth|(st|nd|rd|th)) season)" options:OgreIgnoreCaseOption];
    title = [regex replaceAllMatchesInString:title withString:@""];
    regex = [OGRegularExpression regularExpressionWithString: @"(s)\\d" options:OgreIgnoreCaseOption];
    title = [regex replaceAllMatchesInString:title withString:@""];
    // Remove any Whitespace
    title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return title;
}
+(NSString *)seasonInWords:(int)season{
    // Translate integer season to word (use for Regex)
    switch (season) {
        case 1:
            return @"first";
            break;
        case 2:
            return @"second";
            break;
        case 3:
            return @"third";
            break;
        case 4:
            return @"fourth";
            break;
        case 5:
            return @"fifth";
            break;
        case 6:
            return @"sixth";
            break;
        case 7:
            return @"seventh";
            break;
        case 8:
            return @"eighth";
            break;
        case 9:
            return @"ninth";
            break;
        default:
            return @"";
            break;
    }
}
+(BOOL)checktoken{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults objectForKey:@"Base64Token"] length] == 0) {
        return false;
    }
    else
        return true;
}
+(BOOL)checkoldAPI{
    if ([[NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"MALAPIURL"]] isEqualToString:@"https://malapi.shioridiary.me"]||[[NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"MALAPIURL"]] isEqualToString:@"http://mal-api.com"]) {
        return true;
    }
    return false;
}
+(void)showsheetmessage:(NSString *)message
            explaination:(NSString *)explaination
                 window:(NSWindow *)w {
    // Set Up Prompt Message Window
    NSAlert * alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:message];
    [alert setInformativeText:explaination];
    // Set Message type to Warning
    [alert setAlertStyle:1];
    // Show as Sheet on Preference Window
    [alert beginSheetModalForWindow:w
                      modalDelegate:self
                     didEndSelector:nil
                        contextInfo:NULL];
}
+(NSString *)urlEncodeString:(NSString *)string{
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (CFStringRef)string,
                                                                                                  NULL,
                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                  kCFStringEncodingUTF8 ));
}

@end
