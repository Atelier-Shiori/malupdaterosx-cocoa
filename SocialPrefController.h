//
//  SocialPrefController.h
//  MAL Updater OS X
//
//  Created by 天々座理世 on 2018/01/24.
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>
@class TwitterManager;

@interface SocialPrefController : NSViewController <MASPreferencesViewController>
@property (strong) TwitterManager *tw;
- (id)initWithTwitterManager:(TwitterManager *)tm;
@end
