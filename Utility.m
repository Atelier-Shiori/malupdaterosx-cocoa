//
//  Utility.m
//  MAL Updater OS X
//
//  Created by Tail Red on 1/31/15.
//
//

#import "Utility.h"
#import "EasyNSURLConnection.h"
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
    OGRegularExpression * regex = [OGRegularExpression regularExpressionWithString: @"(s)\\d" options:OgreIgnoreCaseOption];
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
        case 2:
            return @"second";
        case 3:
            return @"third";
        case 4:
            return @"fourth";
        case 5:
            return @"fifth";
        case 6:
            return @"sixth";
        case 7:
            return @"seventh";
        case 8:
            return @"eighth";
        case 9:
            return @"ninth";
        default:
            return @"";
}
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
    [alert setAlertStyle:NSInformationalAlertStyle];
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
+(void)donateCheck{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"donatereminderdate"] == nil){
        [Utility setReminderDate];
    }
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"donatereminderdate"] timeIntervalSinceNow] < 0) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"donated"]){
            bool validkey = [Utility checkDonationKey:[[NSUserDefaults standardUserDefaults] objectForKey:@"donatekey"] name:[[NSUserDefaults standardUserDefaults] objectForKey:@"donor"]];
            if (validkey){
                [Utility setReminderDate];
            }
            else{
                [Utility showDonateReminder];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"donated"];
            }
        }
        else{
            [Utility setReminderDate];
        }
    }
}
+(void)showDonateReminder{

    
    // Shows Donation Reminder
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"donatereminderdate"] == nil){
        [Utility setReminderDate];
    }
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"donatereminderdate"] timeIntervalSinceNow] < 0) {
        NSAlert * alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"Donate"];
        [alert addButtonWithTitle:@"Remind Me Later"];
        [alert setMessageText:@"Please Support MAL Updater OS X"];
        [alert setInformativeText:@"We noticed that you have been using MAL Updater OS X for a while. Although MAL Updater OS X is free, it cost us money and time to develop this program. \r\rIf you find this program helpful, please consider making a donation. You will recieve a key to remove this message and enable weekly builds update channel."];
        [alert setShowsSuppressionButton:NO];
        // Set Message type to Warning
        [alert setAlertStyle:NSInformationalAlertStyle];
        if ([alert runModal]== NSAlertFirstButtonReturn) {
            // Open Donation Page
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.patreon.com/ateliershiori"]];
            [Utility setReminderDate];
        }
        else{
            [Utility setReminderDate];
        }
    }
}

+(void)setReminderDate{
    //Sets Reminder Date
    NSDate *now = [NSDate date];
    NSDate * reminderdate = [now dateByAddingTimeInterval:60*60*24*30];
    [[NSUserDefaults standardUserDefaults] setObject:reminderdate forKey:@"donatereminderdate"];
}
+(BOOL)checkDonationKey:(NSString *)key name:(NSString *)name{
        //Set Search API
        NSURL *url = [NSURL URLWithString:@"https://updates.ateliershiori.moe/keycheck/check.php"];
        EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
        [request addFormData:name forKey:@"name"];
        [request addFormData:key forKey:@"key"];
        //Ignore Cookies
        [request setUseCookies:NO];
        //Perform Search
        [request startFormRequest];
        // Get Status Code
        long statusCode = [request getStatusCode];
    if (statusCode == 200){
        NSError* jerror;
        NSDictionary * d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:nil error:&jerror];
        int valid = [(NSNumber *)d[@"valid"] intValue];
        NSLog(@"%@",[request getResponseDataString]);
        if (valid == 1) {
            // Valid Key
            return YES;
        }
        else{
            // Invalid Key
            return NO;
        }
    }
    else{
        // No Internet
        return NO;
    }


}

@end
