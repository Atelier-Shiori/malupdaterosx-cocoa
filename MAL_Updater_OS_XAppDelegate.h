//
//  MAL_Updater_OS_XAppDelegate.h
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>

@class MyAnimeList;
@class FixSearchDialog;
@class HistoryWindow;
@class DonationWindowController;
@class OfflineViewQueue;
@class MSWeakTimer;
@class streamlinkopen;
@class StatusUpdateWindow;
@class ShareMenu;

@interface MAL_Updater_OS_XAppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate, NSSharingServiceDelegate> {
	/* Windows */
    __unsafe_unretained NSWindow *window;
	/* General Stuff */
	IBOutlet NSMenu *statusMenu;
    NSStatusItem                *statusItem;
    NSImage                        *statusImage;
    NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
    MSWeakTimer *timer;
    IBOutlet NSMenuItem *openstream;
	IBOutlet NSMenuItem *togglescrobbler;
    IBOutlet NSMenuItem *updatenow;
	IBOutlet NSMenuItem *confirmupdate;
    IBOutlet NSMenuItem *findtitle;
    /* Updated Title Display and Operations */
    IBOutlet NSMenuItem *seperator;
    IBOutlet NSMenuItem *lastupdateheader;
    IBOutlet NSMenuItem *updatecorrectmenu;
    IBOutlet NSMenu *updatecorrect;
    IBOutlet NSMenuItem *updatedtitle;
    IBOutlet NSMenuItem *updatedepisode;
    IBOutlet NSMenuItem *seperator2;
    IBOutlet NSMenuItem *updatedcorrecttitle;
    IBOutlet NSMenuItem *updatedupdatestatus;
    IBOutlet NSMenuItem *shareMenuItem;
    /* Status Window */
	IBOutlet NSTextField *ScrobblerStatus;
	IBOutlet NSTextField *LastScrobbled;
    IBOutlet NSTextView *animeinfo;
    IBOutlet NSImageView *img;
    IBOutlet NSVisualEffectView *windowcontent;
    IBOutlet NSScrollView *animeinfooutside;
	int choice;
	BOOL scrobbling;
    BOOL scrobbleractive;
    bool panelactive;
	/* MAL Scrobbling/Updating Class */
	MyAnimeList *MALEngine;
	/* Update Status Sheet Window IBOutlets */
	IBOutlet NSToolbarItem *updatetoolbaritem;
    IBOutlet NSToolbarItem *correcttoolbaritem;
    IBOutlet NSToolbarItem *sharetoolbaritem;
    IBOutlet NSToolbarItem *openAnimePage;
	NSWindowController *_preferencesWindowController;
    streamlinkopen *streamlinkopenw;
}
@property (strong, nonatomic) dispatch_queue_t privateQueue;
@property (nonatomic, readonly) NSWindowController *preferencesWindowController;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *updatepanel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property(strong) FixSearchDialog *fsdialog;
@property (strong) HistoryWindow *historywindowcontroller;
@property (strong) DonationWindowController *dwindow;
@property (strong) OfflineViewQueue *owindow;
@property (strong) IBOutlet NSView *nowplayingview;
@property (strong) IBOutlet NSView *nothingplayingview;
@property (strong) StatusUpdateWindow *updatewindow;
@property (strong) IBOutlet ShareMenu *shareMenu;

- (void)showhistory:(id)sender;
- (IBAction)togglescrobblewindow:(id)sender;
- (void)setStatusToolTip:(NSString*)toolTip;
- (IBAction)toggletimer:(id)sender;
- (void)autostarttimer;
- (void)firetimer;
- (void)starttimer;
- (void)stoptimer;
- (void)setStatusText:(NSString*)messagetext;
- (void)setLastScrobbledTitle:(NSString*)messagetext;
- (void)setStatusMenuTitleEpisode:(NSString *)title episode:(NSString *) episode;
- (IBAction)updatestatus:(id)sender;
- (IBAction)updatestatusmenu:(id)sender;
- (void)showUpdateDialog:(NSWindow *) w;
- (IBAction)updatenow:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)getHelp:(id)sender;
- (void)appendToAnimeInfo:(NSString*)text;
- (void)showNotification:(NSString *)title message:(NSString *) message;
- (IBAction)showAboutWindow:(id)sender;
- (IBAction)enterDonationKey:(id)sender;
- (bool)getisScrobbling;
- (bool)getisScrobblingActive;
- (NSDictionary *)getNowPlaying;
- (NSManagedObjectContext *)getObjectContext;
- (MyAnimeList *)getMALEngineInstance;
- (void)resetUI;
@end
