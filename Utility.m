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
+ (int)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OnigRegexp *)regex
           option:(int)i{
    //Checks for matches
    if ([regex search:title].count > 0) {
        return PrimaryTitleMatch;
    }
    else if (([regex search:atitle] && atitle.length >0 && i==0)) {
        return AlternateTitleMatch;
    }
    return NoMatch;
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
    if (w) {
        [alert beginSheetModalForWindow:w completionHandler:nil];
    }
    else {
        [alert runModal];
    }
}
+ (NSString *)urlEncodeString:(NSString *)string{
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet] ];
}
+ (void)donateCheck:(MAL_Updater_OS_XAppDelegate*)delegate{
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"MacAppStoreMigrated"]) {
        return;
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
    [alert addButtonWithTitle:@"Donate"];
    [alert addButtonWithTitle:@"Enter Key"];
    [alert addButtonWithTitle:@"Remind Me Later"];
    alert.messageText = @"Please Support MAL Updater OS X";
    alert.informativeText = @"We noticed that you have been using MAL Updater OS X for a while. MAL Updater OS X is donationware and we rely on donations to substain the development of our programs. By donating, you can remove this message.";
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
    NSDate *reminderdate = [now dateByAddingTimeInterval:60*60*24*7*2];
    [[NSUserDefaults standardUserDefaults] setObject:reminderdate forKey:@"donatereminderdate"];
}
+ (int)checkDonationKey:(NSString *)key name:(NSString *)name{
        //Set Search API
        NSURL *url = [NSURL URLWithString:@"https://licensing.malupdaterosx.moe/keycheck.php"];
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
        NSDictionary *d = [NSJSONSerialization JSONObjectWithData:request.response.responsedata options:0 error:&jerror];
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
        default:
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
#endif
}
+ (NSString *)getHostName {
    // Gets the host name of an address
    NSString *malapiurl = [NSUserDefaults.standardUserDefaults valueForKey:@"MALAPIURL"];
    OnigRegexp *regex = [OnigRegexp compile:@"(http|https):\\/\\/" options:OnigOptionIgnorecase];
    malapiurl = [malapiurl replaceByRegexp:regex with:@""];
    regex = [OnigRegexp compile:@"\\/.+" options:OnigOptionIgnorecase];
    malapiurl = [malapiurl replaceByRegexp:regex with:@""];
    regex = [OnigRegexp compile:@":\\d+" options:OnigOptionIgnorecase];
    malapiurl = [malapiurl replaceByRegexp:regex with:@""];
    return malapiurl;
}
+ (bool)checkBeta {
    // Check if user is using beta. If so, use the experimental Appcast branch.
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *versionString = bundle.infoDictionary[@"CFBundleShortVersionString"];
    if ([versionString containsString:@"b"] || [versionString containsString:@"a"] || [versionString containsString:@"pre"] || [versionString containsString:@"rc"]) {
        if (![[NSUserDefaults.standardUserDefaults stringForKey:@"SUFeedURL"] isEqualToString:@"https://updates.malupdaterosx.moe/malupdaterosx-beta/profileInfo.php"]) {
                [NSUserDefaults.standardUserDefaults setObject:@"https://updates.malupdaterosx.moe/malupdaterosx-beta/profileInfo.php" forKey:@"SUFeedURL"];
            return true;
        }
    }
    return false;
}
@end
