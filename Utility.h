//
//  Utility.h
//  MAL Updater OS X
//
//  Created by Tail Red on 1/31/15.
//
//

#import <Foundation/Foundation.h>
#import <OgreKit/OgreKit.h>
#import "NSString_stripHtml.h"
#import "string_score.h"
#import "MAL_Updater_OS_XAppDelegate.h"

@interface Utility : NSObject
+(bool)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OGRegularExpression *)regex
           option:(int)i;
+(NSString *)desensitizeSeason:(NSString *)title;
+(NSString *)seasonInWords:(int)season;
+(BOOL)checkoldAPI;
+(void)showsheetmessage:(NSString *)message
           explaination:(NSString *)explaination
                 window:(NSWindow *)w;
+(NSString *)urlEncodeString:(NSString *)string;
+(void)donateCheck:(MAL_Updater_OS_XAppDelegate*)delegate;
+(void)showDonateReminder:(MAL_Updater_OS_XAppDelegate*)delegate;
+(void)setReminderDate;
+(int)checkDonationKey:(NSString *)key name:(NSString *)name;
@end
