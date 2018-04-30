//
//  Utility.h
//  MAL Updater OS X
//
//  Created by Tail Red on 1/31/15.
//
//

#import <Foundation/Foundation.h>
#import "NSString_stripHtml.h"
#import "string_score.h"
#import "MAL_Updater_OS_XAppDelegate.h"

@class OnigRegexp;

@interface Utility : NSObject
typedef NS_ENUM(unsigned int, matchtype) {
    NoMatch = 0,
    PrimaryTitleMatch = 1,
    AlternateTitleMatch = 2
};
+ (int)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OnigRegexp *)regex
           option:(int)i;
+ (NSString *)desensitizeSeason:(NSString *)title;
+ (NSString *)seasonInWords:(int)season;
+ (BOOL)checkoldAPI;
+ (void)showsheetmessage:(NSString *)message
           explaination:(NSString *)explaination
                 window:(NSWindow *)w;
+ (NSString *)urlEncodeString:(NSString *)string;
+ (void)donateCheck:(MAL_Updater_OS_XAppDelegate*)delegate;
+ (void)showDonateReminder:(MAL_Updater_OS_XAppDelegate*)delegate;
+ (void)setReminderDate;
+ (void)checkDonationKey:(NSString *)key name:(NSString *)name completion:(void (^)(int success)) completionHandler;
+ (NSString *)numbertoordinal:(int)number;
+ (NSString *)todaydatestring;
+ (bool)checkBeta;
+ (NSArray *)convertSearchArray:(NSArray *)a;
@end
