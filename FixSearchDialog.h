//
//  FixSearchDialog.h
//  MAL Updater OS X
//
//  Created by 高町なのは on 2014/11/15.
//  Copyright (c) 2014年 Atelier Shiori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FixSearchDialog : NSWindowController <NSTableViewDelegate>
@property (strong) IBOutlet NSArrayController *arraycontroller;
@property (strong) IBOutlet NSTextField *search;
@property (strong) IBOutlet NSButton *deleteoncorrection;
@property (strong) IBOutlet NSButton *onetimecorrection;
@property (strong) IBOutlet NSTableView *tb;
@property (strong) IBOutlet NSTextView *selectedsynopsis;
@property (strong) NSString *selectedtitle;
@property (strong) NSString *selectedaniid;
@property int selectedtotalepisodes;
@property (strong) NSString *searchquery;
@property (setter=setCorrection:) bool correction;
@property (setter=setAllowDelete:) bool allowdelete;
- (id)init;
- (NSString *)getSelectedTitle;
- (NSString *)getSelectedAniID;
- (int)getSelectedTotalEpisodes;
- (bool)getdeleteTitleonCorrection;
- (bool)getcorrectonce;
- (void)setSearchField:(NSString *)term;
@end
