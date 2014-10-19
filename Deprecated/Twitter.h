//
//  Twitter.h
//  MAL Updater OS X - Twitter Class
//
//  Created by Nanoha Takamachi on 1/5/11.
//  Copyright 2009-2011 Chikorita157's Anime Blog. All rights reserved. All rights reserved. Code licensed under New BSD License.
//

#import <Cocoa/Cocoa.h>
#import "MGTwitterEngine.h"
#import "MAL_Updater_OS_XAppDelegate.h"

@class OAToken;

@interface Twitter : NSObject <MGTwitterEngineDelegate> {
    MGTwitterEngine *twitterEngine;
	
	OAToken *token;
}
-(void)postupdate:(NSString *)message;
@end
