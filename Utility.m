//
//  Utility.m
//  MAL Updater OS X
//
//  Created by Tail Red on 1/31/15.
//
//

#import "Utility.h"
#import <EasyNSURLConnection/EasyNSURLConnection.h>
#import <CocoaOniguruma/OnigRegexp.h>
#import <CocoaOniguruma/OnigRegexpUtility.h>

@implementation Utility
+ (bool)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OnigRegexp *)regex
           option:(int)i{
    //Checks for matches
    if ([regex search:title].count > 0 || ([regex search:atitle] && atitle.length >0 && i==0)) {
        return true;
    }
    return false;
}
+ (NSString *)desensitizeSeason:(NSString *)title {
    // Get rid of season references
    OnigRegexp *regex = [OnigRegexp compile:@"(s)\\d" options:OnigOptionIgnorecase];
    title = [title replaceByRegexp:regex with:@""];
    // Remove any Whitespace
    title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return title;
}
+ (NSString *)seasonInWords:(int)season{
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
+ (BOOL)checkoldAPI {
    if ([[NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"MALAPIURL"]] isEqualToString:@"https://malapi.shioridiary.me"]||[[NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"MALAPIURL"]] isEqualToString:@"http://mal-api.com"]||[[NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"MALAPIURL"]] isEqualToString:@"https://malapi.ateliershiori.moe"]) {
        return true;
    }
    return false;
}
+ (void)showsheetmessage:(NSString *)message
            explaination:(NSString *)explaination
                 window:(NSWindow *)w {
    // Set Up Prompt Message Window
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    alert.messageText = message;
    alert.informativeText = explaination;
    // Set Message type to Warning
    alert.alertStyle = NSInformationalAlertStyle;
    // Show as Sheet on Preference Window
    [alert beginSheetModalForWindow:w
                      modalDelegate:self
                     didEndSelector:nil
                        contextInfo:NULL];
}
+ (NSString *)urlEncodeString:(NSString *)string{
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet] ];
}
+ (void)donateCheck:(MAL_Updater_OS_XAppDelegate*)delegate{
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"MacAppStoreMigrated"]) {
        [NSUserDefaults.standardUserDefaults setBool:@NO forKey:@"MacAppStoreMigrated"];
        [NSUserDefaults.standardUserDefaults setBool:@NO forKey:@"donated"];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"donatereminderdate"]) {
        [Utility setReminderDate];
    }
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"donatereminderdate"] timeIntervalSinceNow] < 0) {
        if (((NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"donated"]).boolValue) {
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
                [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:@"donated"];
            }
        }
        else {
            [Utility showDonateReminder:delegate];
        }
    }
}
+ (void)showDonateReminder:(MAL_Updater_OS_XAppDelegate*)delegate{
    // Shows Donation Reminder
    NSAlert *alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:@"Purchase"];
    [alert addButtonWithTitle:@"Enter Key"];
    [alert addButtonWithTitle:@"Remind Me Later"];
    alert.messageText = @"Please Support MAL Updater OS X";
    alert.informativeText = @"We noticed that you have been using MAL Updater OS X for a while. MAL Updater OS X is shareware and you are limited to 7 list updates per week. \r\rTo remove this limit, consider purchasing a donation license.";
    [alert setShowsSuppressionButton:NO];
    // Set Message type to Warning
    alert.alertStyle = NSInformationalAlertStyle;
    long choice = [alert runModal];
    if (choice == NSAlertFirstButtonReturn) {
        // Open Donation Page
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://malupdaterosx.moe/donate/"]];
        [Utility setReminderDate];
    }
    else if (choice == NSAlertSecondButtonReturn) {
        // Show Add Donation Key dialog.
        [delegate enterDonationKey:nil];
        [Utility setReminderDate];
    }
    else {
        // Surpress message for 1 week.
        [Utility setReminderDate];
    }
}

+ (void)setReminderDate{
    //Sets Reminder Date
    NSDate *now = [NSDate date];
    NSDate *reminderdate = [now dateByAddingTimeInterval:60*60*24*7];
    [[NSUserDefaults standardUserDefaults] setObject:reminderdate forKey:@"donatereminderdate"];
}
+ (int)checkDonationKey:(NSString *)key name:(NSString *)name{
        //Set Search API
        NSURL *url = [NSURL URLWithString:@"http://licensing.malupdaterosx.moe/keycheck.php"];
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
        NSDictionary *d = [NSJSONSerialization JSONObjectWithData:request.response.responsedata options:nil error:&jerror];
        int valid = ((NSNumber *)d[@"valid"]).intValue;
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
+ (NSString *)numbertoordinal:(int)number {
    NSString *tmpnum = [NSString stringWithFormat:@"%i", number];
    tmpnum = [tmpnum substringFromIndex:tmpnum.length-1];
    NSString *ordinal = @"";
    switch (tmpnum.intValue) {
        case 1:
            ordinal = @"st";
            break;
        case 2:
            ordinal = @"nd";
            break;
        case 3:
            ordinal = @"rd";
            break;
        case 0:
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
        case 9:
            ordinal = @"th";
            break;
    }
    return [NSString stringWithFormat:@"%i%@", number, ordinal];
}
+ (NSString *)todaydatestring {
    NSDate *today = [NSDate date];
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateFormat = @"yyyy-MM-dd";
    return [df stringFromDate:today];
}
+ (void)setUserAgent:(EasyNSURLConnection *)request {
    #ifdef oss
    #else
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"donated"]) {
        request.useragent = [NSString stringWithFormat:@"%@ %@ (Macintosh; Mac OS X %@; %@)", @"MAL Updater OS X Pro",[NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"], [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"][@"ProductVersion"], [NSLocale currentLocale].localeIdentifier];
    }
    @endif
}
+ (void)incrementupdatecount {
    int current_count = ((NSNumber *)[NSUserDefaults.standardUserDefaults valueForKey:@"unregistered_update_count"]).intValue;
    current_count++;
    [NSUserDefaults.standardUserDefaults setValue:@(current_count)forKey:@"unregistered_update_count"];
}
+ (bool)checkupdatelimit {
    NSString *malapiurl = (NSString *)[NSUserDefaults.standardUserDefaults valueForKey:@"MALAPIURL"];
    if (([malapiurl rangeOfString:@"malupdaterosx.moe"].location == NSNotFound) && ([malapiurl rangeOfString:@"ateliershiori.moe"].location == NSNotFound)) {
        // Do not enforce limit with other MAL API servers
        return false;
    }
    if (![NSUserDefaults.standardUserDefaults integerForKey:@"donated"]) {
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"update_reset_date"]) {
            [self setupdatelimitresetdate];
        }
        if ([NSUserDefaults.standardUserDefaults integerForKey:@"unregistered_update_count"] > 10  && [[[NSUserDefaults standardUserDefaults] objectForKey:@"update_reset_date"] timeIntervalSinceNow] >= 0) {
            return true;
        }
        else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"update_reset_date"] timeIntervalSinceNow] <= 0) {
            [self setupdatelimitresetdate];
            [NSUserDefaults.standardUserDefaults setValue:@(0) forKey:@"unregistered_update_count"];
            return false;
        }
    }
    return false;
}
+ (void)setupdatelimitresetdate {
    NSDate *now = [NSDate date];
    NSDate *reminderdate = [now dateByAddingTimeInterval:60*60*24*7];
    [[NSUserDefaults standardUserDefaults] setObject:reminderdate forKey:@"update_reset_date"];
}
+ (NSString *)getHostName {
    NSString *malapiurl = [NSUserDefaults.standardUserDefaults valueForKey:@"MALAPIURL"];
    OnigRegexp *regex = [OnigRegexp compile:@"(http|https):\\/\\/" options:OnigOptionIgnorecase];
    malapiurl = [malapiurl replaceByRegexp:regex with:@""];
    regex = [OnigRegexp compile:@"\\/.+" options:OnigOptionIgnorecase];
    malapiurl = [malapiurl replaceByRegexp:regex with:@""];
    regex = [OnigRegexp compile:@":\\d+" options:OnigOptionIgnorecase];
    malapiurl = [malapiurl replaceByRegexp:regex with:@""];
    return malapiurl;
}
@end
