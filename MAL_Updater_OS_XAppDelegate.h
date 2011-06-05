//
//  MAL_Updater_OS_XAppDelegate.h
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2010 Chikorita157's Anime Blog. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import <CMCrashReporter/CMCrashReporter.h>
#import "MyAnimeList.h"

@class PreferenceController;
@class MyAnimeList;
@interface MAL_Updater_OS_XAppDelegate : NSObject <GrowlApplicationBridgeDelegate> {
	/* Windows */
    NSWindow *window;
	NSWindow *historywindow;
	NSWindow *updatepanel;
	/* General Stuff */
	IBOutlet NSMenu *statusMenu;
	IBOutlet NSTableView *historytable;
    NSStatusItem                *statusItem;
    NSImage                        *statusImage;
    NSImage                        *statusHighlightImage;
	PreferenceController * preferenceController;
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSTimer * timer;
	IBOutlet NSMenuItem * togglescrobbler;
	IBOutlet NSTextField * ScrobblerStatus;
	IBOutlet NSTextField * LastScrobbled;
	int choice;
	/* MAL Scrobbling/Updating Class */
	MyAnimeList * MALEngine;
	/* Update Status Sheet Window IBOutlets */
	IBOutlet NSToolbarItem * updatetoolbaritem;
	IBOutlet NSTextField * showtitle;
	IBOutlet NSTextField * totalepisodes;
	IBOutlet NSTextField * currentepisodes;
	IBOutlet NSPopUpButton * showstatus;
	IBOutlet NSPopUpButton * showscore;
    IBOutlet NSNumberFormatter * episodefmt;
}
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *historywindow;
@property (assign) IBOutlet NSWindow *updatepanel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

-(void)showPreferences:(id)sender;
-(void)showhistory:(id)sender;
-(IBAction)togglescrobblewindow:(id)sender;
-(void)addrecord:(NSString *)title
		 Episode:(NSString *)episode
			Date:(NSDate *)date;
-(IBAction)clearhistory:(id)sender;
-(void)clearhistoryended:(NSAlert *)alert
					code:(int)choice
				  conext:(void *)v;
-(void)setStatusToolTip:(NSString*)toolTip;
-(IBAction)toggletimer:(id)sender;
-(void)autostarttimer;
- (void)firetimer:(NSTimer *)aTimer;
-(void)setStatusText:(NSString*)messagetext;
-(void)setLastScrobbledTitle:(NSString*)messagetext;
-(IBAction)updatestatus:(id)sender;
-(IBAction)closeupdatestatus:(id)sender;
-(IBAction)updatetitlestatus:(id)sender;
@end
