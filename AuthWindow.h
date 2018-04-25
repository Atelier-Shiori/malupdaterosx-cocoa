//
//  AuthWindow.h
//  Shukofukurou
//
//  Created by 小鳥遊六花 on 4/3/18.
// Copyright © 2017-2018 MAL Updater OS X Group and Moy IT Solutions. All rights reserved. Licensed under 3-clause BSD License
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface AuthWindow : NSWindowController <WKUIDelegate,WKNavigationDelegate>
@property (strong) NSString *pin;
@property (strong) NSString *challenge;
- (void)loadAuthorization;
@end
