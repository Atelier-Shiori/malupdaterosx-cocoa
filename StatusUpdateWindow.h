//
//  StatusUpdateWindow.h
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/06/04.
//
//

#import <Cocoa/Cocoa.h>
@class MyAnimeList;

@interface StatusUpdateWindow : NSWindowController
@property (strong) IBOutlet NSTextField *showtitle;
@property (strong) IBOutlet NSPopUpButton *showstatus;
@property (strong) IBOutlet NSPopUpButton *showscore;
@property (strong) IBOutlet NSTextField *episodefield;
@property (strong) IBOutlet NSNumberFormatter *epiformatter;
@property (nonatomic, copy) void (^completion)(long returncode);
- (void)showUpdateDialog:(NSWindow *) w withMALEngine:(MyAnimeList *)MALEngine;
@end
