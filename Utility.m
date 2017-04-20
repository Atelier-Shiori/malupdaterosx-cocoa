//
//  Utility.m
//  MAL Updater OS X
//
//  Created by Tail Red on 1/31/15.
//
//

#import "Utility.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>

@implementation Utility
+(bool)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OnigRegexp *)regex
           option:(int)i{
    //Checks for matches
    if ([regex match:title] || ([regex match:atitle] && [atitle length] >0 && i==0)) {
        return true;
    }
    return false;
}
+(NSString *)desensitizeSeason:(NSString *)title {
    // Get rid of season references
    OnigRegexp * regex = [OnigRegexp compile:@"(s)\\d" options:OnigOptionIgnorecase];
    title = [title replaceByRegexp:regex with:@""];
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
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
}
+(void)donateCheck:(MAL_Updater_OS_XAppDelegate*)delegate{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"donatereminderdate"]) {
        [Utility setReminderDate];
    }
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"donatereminderdate"] timeIntervalSinceNow] < 0) {
        if ([(NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"donated"] boolValue]) {
            int validkey = [Utility checkDonationKey:[[NSUserDefaults standardUserDefaults] objectForKey:@"donatekey"] name:[[NSUserDefaults standardUserDefaults] objectForKey:@"donor"]];
            if (validkey == 1) {
                //Reset check
                [Utility setReminderDate];
            }
            else if (validkey == 2) {
                //Try again when there is internet access
            }
            else {
                //Invalid Key
                [Utility showsheetmessage:@"Donation Key Error" explaination:@"This key has been revoked. Please contact the author of this program or enter a valid key." window:nil];
                [Utility showDonateReminder:delegate];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"donated"];
            }
        }
        else {
            [Utility showDonateReminder:delegate];
        }
    }
}
+(void)showDonateReminder:(MAL_Updater_OS_XAppDelegate*)delegate{
    // Shows Donation Reminder
    NSAlert * alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:@"Donate"];
    [alert addButtonWithTitle:@"Enter Key"];
    [alert addButtonWithTitle:@"Remind Me Later"];
    [alert setMessageText:@"Please Support MAL Updater OS X"];
    [alert setInformativeText:@"We noticed that you have been using MAL Updater OS X for a while. Although MAL Updater OS X is free and open source software, it cost us money and time to develop this program. \r\rIf you find this program helpful, please consider making a donation. You will recieve a key to remove this message and enable weekly builds update channel."];
    [alert setShowsSuppressionButton:NO];
    // Set Message type to Warning
    [alert setAlertStyle:NSInformationalAlertStyle];
    long choice = [alert runModal];
    if (choice == NSAlertFirstButtonReturn) {
        // Open Donation Page
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://malupdaterosx.ateliershiori.moe/donate/"]];
        [Utility setReminderDate];
    }
    else if (choice == NSAlertSecondButtonReturn) {
        // Show Add Donation Key dialog.
        [delegate enterDonationKey:nil];
        [Utility setReminderDate];
    }
    else {
        // Surpress message for 2 weeks.
        [Utility setReminderDate];
    }
}

+(void)setReminderDate{
    //Sets Reminder Date
    NSDate *now = [NSDate date];
    NSDate * reminderdate = [now dateByAddingTimeInterval:60*60*24*14];
    [[NSUserDefaults standardUserDefaults] setObject:reminderdate forKey:@"donatereminderdate"];
}
+(int)checkDonationKey:(NSString *)key name:(NSString *)name{
        //Set Search API
        NSURL *url = [NSURL URLWithString:@"https://updates.ateliershiori.moe/keycheck/check.php"];
        EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
        [request addFormData:name forKey:@"name"];
        [request addFormData:key forKey:@"key"];
        //Ignore Cookies
        [request setUseCookies:NO];
        //Perform Search
        [request startJSONFormRequest:EasyNSURLConnectionJsonType];
        // Get Status Code
        long statusCode = [request getStatusCode];
    if (statusCode == 200) {
        NSError* jerror;
        NSDictionary * d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:nil error:&jerror];
        int valid = [(NSNumber *)d[@"valid"] intValue];
        if (valid == 1) {
            // Valid Key
            return 1;
        }
        else {
            // Invalid Key
            return 0;
        }
    }
    else {
        // No Internet
        return 2;
    }
}

@end
