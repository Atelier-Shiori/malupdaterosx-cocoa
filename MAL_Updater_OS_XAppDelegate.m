//
//  MAL_Updater_OS_XAppDelegate.m
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "MAL_Updater_OS_XAppDelegate.h"
#import "MyAnimeList.h"
#import "MyAnimeList+Update.h"
#import "MyAnimeList+Keychain.h"
#import "PFMoveApplication.h"
#import "Preferences.h"
#import "FixSearchDialog.h"
#import "Hotkeys.h"
#import "AutoExceptions.h"
#import "Utility.h"
#import "ExceptionsCache.h"
#import "HistoryWindow.h"
#import "OfflineViewQueue.h"
#import "StatusUpdateWindow.h"
#import <MSWeakTimer_macOS/MSWeakTimer.h>
#ifdef oss
#else
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "DonationWindowController.h"
#import <TorrentBrowser/TorrentBrowser.h>
#endif
#import "ShareMenu.h"
#import "PFAboutWindowController.h"

@implementation MAL_Updater_OS_XAppDelegate

@synthesize window;
@synthesize fsdialog;
@synthesize historywindowcontroller;
@synthesize managedObjectContext;
@synthesize statusMenu;
@synthesize statusItem;
@synthesize statusImage;
@synthesize timer;
@synthesize openstream;
@synthesize togglescrobbler;
@synthesize updatenow;
@synthesize confirmupdate;
@synthesize findtitle;
@synthesize seperator;
@synthesize lastupdateheader;
@synthesize updatecorrectmenu;
@synthesize updatecorrect;
@synthesize updatedtitle;
@synthesize updatedepisode;
@synthesize seperator2;
@synthesize updatedcorrecttitle;
@synthesize updatedupdatestatus;
@synthesize shareMenuItem;
@synthesize ScrobblerStatus;
@synthesize LastScrobbled;
@synthesize animeinfo;
@synthesize img;
@synthesize windowcontent;
@synthesize animeinfooutside;
@synthesize choice;
@synthesize scrobbling;
@synthesize scrobbleractive;
@synthesize panelactive;
@synthesize MALEngine;
@synthesize updatetoolbaritem;
@synthesize correcttoolbaritem;
@synthesize sharetoolbaritem;
@synthesize openAnimePage;
@synthesize _preferencesWindowController;

#pragma mark -
#pragma mark Initalization
/**
 Returns the support directory for the application, used to store the Core Data
 store file.  This code uses a directory named "MAL Updater OS X" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportDirectory {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = (paths.count > 0) ? paths[0] : NSTemporaryDirectory();
#ifdef DEBUG
    return [basePath stringByAppendingPathComponent:@"MAL Updater OS X - DEBUG"];
#else
    return [basePath stringByAppendingPathComponent:@"MAL Updater OS X"];
#endif
}


/**
 Creates, retains, and returns the managed object model for the application
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel) return managedObjectModel;
    
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This
 implementation will create and return a coordinator, having added the
 store for the application to it.  (The directory for the store is created,
 if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    
    if (persistentStoreCoordinator) return persistentStoreCoordinator;
    
    NSManagedObjectModel *mom = self.managedObjectModel;
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
        if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
        }
    }
    
    NSURL *url = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"Update History.sqlite"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES
                              };
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:url
                                                        options:options
                                                          error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        persistentStoreCoordinator = nil;
        return nil;
    }
    
    return persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.)
 */

- (NSManagedObjectContext *) managedObjectContext {
    
    if (managedObjectContext) return managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    managedObjectContext.persistentStoreCoordinator = coordinator;
    
    return managedObjectContext;
}
+ (void)initialize
{
    //Create a Dictionary
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    
    // Defaults
    defaultValues[@"Base64Token"] = @"";
    // API Settings
#ifdef oss
    defaultValues[@"MALAPIURL"] = @"http://localhost:8000";
#else
    defaultValues[@"MALAPIURL"] = @"https://malapi.malupdaterosx.moe";
#endif
    // General Settings
    defaultValues[@"ScrobbleatStartup"] = @NO;
    defaultValues[@"useSearchCache"] = @YES;
    defaultValues[@"exceptions"] = [[NSMutableArray alloc] init];
    defaultValues[@"ignoredirectories"] = [[NSMutableArray alloc] init];
    defaultValues[@"IgnoreTitleRules"] = [[NSMutableArray alloc] init];
    defaultValues[@"ConfirmNewTitle"] = @YES;
    defaultValues[@"ConfirmUpdates"] = @NO;
    defaultValues[@"UseAutoExceptions"] = @YES;
    defaultValues[@"timerinterval"] = @(300);
    defaultValues[@"showcorrection"] = @YES;
    defaultValues[@"NSApplicationCrashOnExceptions"] = @YES;
    //Yosemite Specific Advanced Options
    defaultValues[@"DisableYosemiteTitleBar"] = @NO;
    defaultValues[@"DisableYosemiteVibrance"] = @NO;
    // Kodi JSON RPC Detection
    defaultValues[@"enablekodiapi"] = @NO;
    defaultValues[@"kodiaddress"] = @"";
    defaultValues[@"kodiport"] = @"3005";
    // Donation Settings
#ifdef oss
    defaultValues[@"donated"] = @YES;
    defaultValues[@"oss"] = @YES;
#else
    defaultValues[@"donated"] = @NO;
    defaultValues[@"oss"] = @NO;
    defaultValues[@"autodownloadtorrents"] = @YES;
    defaultValues[@"autodownloadinterval"] = @(3600);
#endif
    defaultValues[@"MacAppStoreMigrated"] = @NO;
    // Plex Media Server
    defaultValues[@"enableplexapi"] = @NO;
    defaultValues[@"plexaddress"] = @"localhost";
    defaultValues[@"plexport"] = @"32400";
    defaultValues[@"plexidentifier"] = @"MAL_Updater_OS_X_Plex_Client";
    // Social
    defaultValues[@"tweetonscrobble"] = @NO;
    defaultValues[@"twitteraddanime"] = @YES;
    defaultValues[@"twitterupdateanime"] = @YES;
    defaultValues[@"twitterupdatestatus"] = @NO;
    defaultValues[@"twitteraddanimeformat"] = @"Started watching %title% Episode %episode% - %malurl% #malupdaterosx";
    defaultValues[@"twitterupdateanimeformat"] = @"%status% %title% Episode %episode% - %malurl% #malupdaterosx";
    defaultValues[@"twitterupdatestatusformat"] =  @"Updated %title% Episode %episode% (%status%) - %malurl% #malupdaterosx";
    defaultValues[@"usediscordrichpresence"] = @NO;
                                                    
    //Register Dictionary
    [[NSUserDefaults standardUserDefaults]
     registerDefaults:defaultValues];
}
- (void) awakeFromNib{
    // Register queue
    _privateQueue = dispatch_queue_create("com.chikorita157.malupdaterosx", DISPATCH_QUEUE_CONCURRENT);
    
    //Create the NSStatusBar and set its length
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    statusImage = [NSImage imageNamed:@"StatusIcon"];
    
    //Yosemite Dark Menu Support
    [statusImage setTemplate:YES];
    
    //Sets the images in our NSStatusItem
    statusItem.image = statusImage;
    
    //Tells the NSStatusItem what menu to load
    statusItem.menu = statusMenu;
    
    //Sets the tooptip for our item
    statusItem.toolTip = @"MAL Updater OS X";
    
    //Enables highlighting
    [statusItem setHighlightMode:YES];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Initialize MALEngine
    MALEngine = [[MyAnimeList alloc] init];
    [MALEngine setManagedObjectContext:managedObjectContext];
#ifdef DEBUG
#else
    // Check if Application is in the /Applications Folder
    // Only Activate in OS X/macOS is 10.11 or earlier due to Gatekeeper changes in macOS Sierra
    // Note: Sierra Appkit Version is 1485
    PFMoveToApplicationsFolderIfNecessary();
#endif
    //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
    [NSApp activateIgnoringOtherApps:YES];
    
    //Load Defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    //Set Notification Center Delegate
    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    
    // Disable Update and Share Buttons
    [updatetoolbaritem setEnabled:NO];
    [sharetoolbaritem setEnabled:NO];
    [correcttoolbaritem setEnabled:NO];
    [openAnimePage setEnabled:NO];
    
    //Register Global Hotkey
    [self registerHotkey];
    // Hide Window
    [window close];
    
    //Set up Yosemite UI Enhancements
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9)
    {
        if ([defaults boolForKey:@"DisableYosemiteTitleBar"] != 1) {
            // OS X 10.10 code here.
            //Hide Title Bar
            self.window.titleVisibility = NSWindowTitleHidden;
            // Fix Window Size
            NSRect frame = window.frame;
            frame.size = CGSizeMake(440, 291);
            [window setFrame:frame display:YES];
        }
        if ([defaults boolForKey:@"DisableYosemiteVibrance"] != 1) {
            //Add NSVisualEffectView to Window
            windowcontent.blendingMode = NSVisualEffectBlendingModeBehindWindow;
            windowcontent.material = NSVisualEffectMaterialLight;
            windowcontent.state = NSVisualEffectStateFollowsWindowActiveState;
            windowcontent.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
            //Make Animeinfo textview transparrent
            [animeinfooutside setDrawsBackground:NO];
            animeinfo.backgroundColor = [NSColor clearColor];
        }
        else {
            windowcontent.state = NSVisualEffectStateInactive;
            [animeinfooutside setDrawsBackground:NO];
            animeinfo.backgroundColor = [NSColor clearColor];
        }
        
    }
    // Fix template images
    // There is a bug where template images are not made even if they are set in XCAssets
    NSArray *images = @[@"update", @"history", @"correct", @"Info", @"clear"];
    NSImage *image;
    for (NSString *imagename in images) {
        image = [NSImage imageNamed:imagename];
        [image setTemplate:YES];
    }
    
    // Notify User if there is no Account Info
    if (![MALEngine checkaccount]) {
        // First time prompt
        NSAlert *alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        alert.messageText = @"Welcome to MAL Updater OS X";
        alert.informativeText = @"Before using this program, you need to login. Do you want to open Preferences to log in now?\r\rPlease note that MAL Updater OS X now stores user information in the Keychain and therefore, you must login again.";
        // Set Message type to Warning
        alert.alertStyle = NSInformationalAlertStyle;
        if ([alert runModal]== NSAlertFirstButtonReturn) {
            // Show Preference Window and go to Login Preference Pane
            [NSApp activateIgnoringOtherApps:YES];
            [self.preferencesWindowController showWindow:nil];
            [(MASPreferencesWindowController *)self.preferencesWindowController selectControllerAtIndex:1];
        }
    }
    else {
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"credentialscheckdate"]){
            // Check credentials now if user has an account and these values are not set
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate new] forKey:@"credentialscheckdate"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"credentialsvalid"];
        }
    }
#ifdef oss
#else
    if ([Utility checkoldAPI]) {
        [self showNotification:@"MAL Updater OS X" message:@"The API URL has been automatically updated."];
        [[NSUserDefaults standardUserDefaults] setObject:@"https://malapi.malupdaterosx.moe" forKey:@"MALAPIURL"];
    }
    // Set up Torrent Browser (closed source)
    _tbc = [[TorrentBrowserController alloc] initwithManagedObjectContext:managedObjectContext];
    // Start Timer for Auto Downloading of Torrents if enabled
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"autodownloadtorrents"]) {
        if ([_tbc.tmanager startAutoDownloadTimer]) {
            NSLog(@"Timer started");
        }
        else {
            NSLog(@"Failed to start timer.");
        }
    }
#endif
    // Autostart Scrobble at Startup
    if ([defaults boolForKey:@"ScrobbleatStartup"] == 1) {
        [self autostarttimer];
    }
    // Import existing Exceptions Data
    [AutoExceptions importToCoreData];
#ifdef oss
#else
    // Show Donation Message
    [Utility donateCheck:self];
    // Fabric
    [Fabric with:@[[Crashlytics class]]];
#endif
}
#pragma mark General UI Functions
- (NSWindowController *)preferencesWindowController
{
    if (!_preferencesWindowController)
    {
        NSViewController *generalViewController = [[GeneralPrefController alloc] init];
        NSViewController *loginViewController = [[LoginPref alloc] initwithAppDelegate:self];
        NSViewController *socialViewController = [[SocialPrefController alloc] initWithTwitterManager:MALEngine.twittermanager withDiscordManager:MALEngine.discordmanager];
        NSViewController *suViewController = [[SoftwareUpdatesPref alloc] init];
        NSViewController *exceptionsViewController = [[ExceptionsPref alloc] init];
        NSViewController *hotkeyViewController = [[HotkeysPrefs alloc] init];
        NSViewController *plexviewcontroller = [PlexPrefs new];
        NSViewController *advancedViewController = [[AdvancedPrefController alloc] initwithAppDelegate:self];
#ifdef oss
        NSArray *controllers = @[generalViewController, loginViewController, socialViewController, hotkeyViewController, plexviewcontroller, exceptionsViewController, suViewController, advancedViewController];
#else
        NSArray *controllers = @[generalViewController, loginViewController, socialViewController, hotkeyViewController, plexviewcontroller, [_tbc getBittorrentPreferences], exceptionsViewController, suViewController, advancedViewController];
#endif
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers];
    }
    return _preferencesWindowController;
}

- (IBAction)showPreferences:(id)sender {
    //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
    [NSApp activateIgnoringOtherApps:YES];
    [self.preferencesWindowController showWindow:nil];
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    
    if (!managedObjectContext) return NSTerminateNow;
    
    if (![managedObjectContext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (!managedObjectContext.hasChanges) return NSTerminateNow;
    
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        
        // This error handling simply presents error information in a panel with an
        // "Ok" button, which does not include any attempt at error recovery (meaning,
        // attempting to fix the error.)  As a result, this implementation will
        // present the information to the user and then follow up with a panel asking
        // if the user wishes to "Quit Anyway", without saving the changes.
        
        // Typically, this process should be altered to include application-specific
        // recovery steps.
        
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = question;
        alert.informativeText = info;
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertSecondButtonReturn) return NSTerminateCancel;
        
    }
    
    return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    // Shutdown Discord RPC
    [MALEngine.discordmanager shutdownDiscordRPC];
}

- (IBAction)togglescrobblewindow:(id)sender
{
    if (window.visible) {
        [window close];
    } else {
        //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
        [NSApp activateIgnoringOtherApps:YES];
        [window makeKeyAndOrderFront:self];
    }
}

- (IBAction)enterDonationKey:(id)sender{
    //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
    [NSApp activateIgnoringOtherApps:YES];
#ifdef oss
#else
    if (!_dwindow) {
        _dwindow = [[DonationWindowController alloc] init];
    }
    [_dwindow.window makeKeyAndOrderFront:nil];
#endif
    
}
- (IBAction)showOfflineQueue:(id)sender{
    //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
    [NSApp activateIgnoringOtherApps:YES];
    if (!_owindow) {
        _owindow = [[OfflineViewQueue alloc] init];
    }
    [_owindow.window makeKeyAndOrderFront:nil];
    
}
- (IBAction)getHelp:(id)sender{
    //Show Help
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/malupdaterosx-cocoa/wiki/Getting-Started"]];
}
- (IBAction)showAboutWindow:(id)sender{
    // Properly show the about window in a menu item application
    [NSApp activateIgnoringOtherApps:YES];
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:self];
}
- (void)disableUpdateItems{
    // Disables update options to prevent erorrs
    panelactive = true;
    [statusMenu setAutoenablesItems:NO];
    [updatecorrect setAutoenablesItems:NO];
    [updatenow setEnabled:NO];
    [togglescrobbler setEnabled:NO];
    [updatedcorrecttitle setEnabled:NO];
    [updatedupdatestatus setEnabled:NO];
    [confirmupdate setEnabled:NO];
    [findtitle setEnabled:NO];
    [openstream setEnabled:NO];
}
- (void)enableUpdateItems{
    // Reenables update options
    panelactive = false;
    [updatenow setEnabled:YES];
    [togglescrobbler setEnabled:YES];
    [updatedcorrecttitle setEnabled:YES];
    if (confirmupdate.hidden) {
        [updatedupdatestatus setEnabled:YES];
    }
    if (!confirmupdate.hidden && !MALEngine.LastScrobbledTitleNew) {
        [updatedupdatestatus setEnabled:YES];
        [updatecorrect setAutoenablesItems:YES];
    }
    [statusMenu setAutoenablesItems:YES];
    [confirmupdate setEnabled:YES];
    [findtitle setEnabled:YES];
    [openstream setEnabled:YES];
}
- (void)unhideMenus{
    //Show Last Scrobbled Title and operations */
    [seperator setHidden:NO];
    [lastupdateheader setHidden:NO];
    [updatedtitle setHidden:NO];
    [updatedepisode setHidden:NO];
    [seperator2 setHidden:NO];
    [updatecorrectmenu setHidden:NO];
    [updatedcorrecttitle setHidden:NO];
    //[shareMenuItem setHidden:NO];
}
- (void)toggleScrobblingUIEnable:(BOOL)enable{
    dispatch_async(dispatch_get_main_queue(), ^{
        statusMenu.autoenablesItems = enable;
        updatenow.enabled = enable;
        togglescrobbler.enabled = enable;
        confirmupdate.enabled = enable;
        findtitle.enabled = enable;
        openstream.enabled = enable;
        if (!enable) {
            updatenow.title = @"Updating...";
            [self setStatusText:@"Scrobble Status: Scrobbling..."];
        }
        else {
            updatenow.title = @"Update Now";
        }
    });
}
- (void)EnableStatusUpdating:(BOOL)enable{
    updatecorrect.autoenablesItems = enable;
    updatetoolbaritem.enabled = enable;
    updatedupdatestatus.enabled = enable;
}
- (void)performsendupdatenotification:(int)status{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (status) {
            case ScrobblerNothingPlaying:
                [self setStatusText:@"Scrobble Status: Idle..."];
                // Remove Discord Presence
                if (MALEngine.discordmanager.discordrpcrunning) {
                    [MALEngine.discordmanager removePresence];
                }
                break;
            case ScrobblerSameEpisodePlaying:
                [self setStatusText:@"Scrobble Status: Same Episode Playing, Scrobble not needed."];
                break;
            case ScrobblerUpdateNotNeeded:
                [self setStatusText:@"Scrobble Status: No update needed."];
                break;
            case ScrobblerConfirmNeeded: {
                [self setStatusText:@"Scrobble Status: Please confirm update."];
                NSDictionary *userinfo = @{@"title": MALEngine.LastScrobbledTitle,  @"episode": MALEngine.LastScrobbledEpisode};
                [self showConfirmationNotification:@"Confirm Update" message:[NSString stringWithFormat:@"Click here to confirm update for %@ Episode %@.",MALEngine.LastScrobbledActualTitle,MALEngine.LastScrobbledEpisode] updateData:userinfo];
                break;
            }
            case ScrobblerAddTitleSuccessful:
            case ScrobblerUpdateSuccessful:
                [self setStatusText:@"Scrobble Status: Scrobble Successful..."];
                [self showNotification:@"Scrobble Successful."message:[NSString stringWithFormat:@"%@ - %@",MALEngine.LastScrobbledActualTitle,MALEngine.LastScrobbledEpisode]];
                //Add History Record
                [HistoryWindow addrecord:MALEngine.LastScrobbledActualTitle Episode:MALEngine.LastScrobbledEpisode Date:[NSDate date]];
                break;
            case ScrobblerOfflineQueued:
                [self setStatusText:@"Scrobble Status: Scrobble Queued..."];
                [self showNotification:@"Scrobble Queued." message:[NSString stringWithFormat:@"%@ - %@",MALEngine.LastScrobbledActualTitle,MALEngine.LastScrobbledEpisode]];
                break;
            case ScrobblerTitleNotFound:
                if (!((NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"showcorrection"]).boolValue) {
                    [self setStatusText:@"Scrobble Status: Couldn't find title."];
                    [self showNotification:@"Couldn't find title." message:[NSString stringWithFormat:@"Click here to find %@ manually.", MALEngine.FailedTitle]];
                }
                break;
            case ScrobblerAddTitleFailed:
            case ScrobblerUpdateFailed:
                [self showNotification:@"Scrobble Unsuccessful." message:@"Retrying in 5 mins..."];
                [self setStatusText:@"Scrobble Status: Scrobble Failed. Retrying in 5 mins..."];
                break;
            case ScrobblerMALUpdaterOSXNeedsUpdate:
                [self showNotification:@"Update Required." message:@"An update is required to use MAL Updater OS X."];
                [self setStatusText:@"Scrobble Status: Update required."];
                break;
            case ScrobblerInvalidCredentials:
                [self showNotification:@"Invalid Credentials" message:@"Your credentials may be incorrect. Please log in again."];
                [self setStatusText:@"Scrobble Status: Invalid credentials."];
                break;
            case ScrobblerInvalidScrobble:
                [self showNotification:@"Invalid Scrobble" message:@"You are trying to scrobble a title that haven't been aired or finished airing yet, which is not allowed."];
                [self setStatusText:@"Scrobble Status: Invalid Scrobble."];
                break;
            default:
                break;
        }
    });
}

- (void)performRefreshUI:(int)status{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (MALEngine.Success == 1) {
            [findtitle setHidden:true];
            if (MALEngine.online) {
                if (MALEngine.LastScrobbledActualTitle) {
                    [self setStatusMenuTitleEpisode:MALEngine.LastScrobbledActualTitle episode:MALEngine.LastScrobbledEpisode];
                }
                else {
                    [self setStatusMenuTitleEpisode:MALEngine.LastScrobbledTitle episode:MALEngine.LastScrobbledEpisode];
                }
                if (status != 3 && MALEngine.confirmed) {
                    // Show normal info
                    [self updateLastScrobbledTitleStatus:false];
                    //Enable Update Status functions
                    [self EnableStatusUpdating:YES];
                    [confirmupdate setHidden:YES];
                }
                else {
                    // Show that user needs to confirm update
                    [self updateLastScrobbledTitleStatus:true];
                    [confirmupdate setHidden:NO];
                    if (MALEngine.LastScrobbledTitleNew) {
                        // Disable Update Status functions for new and unconfirmed titles.
                        [self EnableStatusUpdating:NO];
                    }
                    else {
                        [self EnableStatusUpdating:YES];
                    }
                }
                [sharetoolbaritem setEnabled:YES];
                [correcttoolbaritem setEnabled:YES];
                [openAnimePage setEnabled:YES];
                NSDictionary *ainfo = MALEngine.LastScrobbledInfo;
                if (ainfo !=nil) { // Checks if MAL Updater OS X already populated info about the just updated title.
                    [self showAnimeInfo:ainfo];
                    [_shareMenu generateShareMenu:@[[NSString stringWithFormat:@"%@ - %@", MALEngine.LastScrobbledTitle, MALEngine.LastScrobbledEpisode ], [NSURL URLWithString:[NSString stringWithFormat:@"http://myanimelist.net/anime/%@", MALEngine.AniID]]]];
                    [shareMenuItem setHidden:NO];
                }
            }
            else {
                [self updateLastScrobbledTitleStatus:false];
                [self setStatusMenuTitleEpisode:MALEngine.LastScrobbledTitle episode:MALEngine.LastScrobbledEpisode];
                [self EnableStatusUpdating:NO];
                animeinfo.string = @"No information available.";
                [confirmupdate setHidden:YES];
                [sharetoolbaritem setEnabled:NO];
                [correcttoolbaritem setEnabled:NO];
                [shareMenuItem setHidden:YES];
            }
            
            // Show hidden menus
            [self unhideMenus];
            
        }
        if (status == 51) {
            //Show option to find title
            [findtitle setHidden:false];
            if (((NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"showcorrection"]).boolValue) {
                [self showCorrectionSearchWindow:self];
            }
        }
        // Enable Menu Items
        scrobbleractive = false;
        [self toggleScrobblingUIEnable:true];
    });
}

- (void)resetUI {
    // Resets the UI when the user logs out
    [_shareMenu resetShareMenu];
    [updatecorrect setAutoenablesItems:NO];
    [self EnableStatusUpdating:NO];
    [sharetoolbaritem setEnabled:NO];
    [correcttoolbaritem setEnabled:NO];
    [openAnimePage setEnabled:NO];
    [findtitle setHidden:YES];
    [confirmupdate setHidden:YES];
    lastupdateheader.hidden = YES;
    updatedtitle.hidden = YES;
    updatedepisode.hidden = YES;
    seperator2.hidden = YES;
    updatecorrectmenu.hidden = YES;
    shareMenuItem.hidden = YES;
    [MALEngine resetinfo];
    _nowplayingview.hidden = YES;
    _nothingplayingview.hidden = NO;
    [self setStatusToolTip:@"Hachidori"];
}

- (IBAction)showaboutwindow:(id)sender{
    if (!_aboutWindowController) {
        _aboutWindowController = [PFAboutWindowController new];
    }
    (self.aboutWindowController).appURL = [[NSURL alloc] initWithString:@"https://malupdaterosx.moe/"];
    NSMutableString *copyrightstr = [NSMutableString new];
    NSDictionary *bundleDict = [NSBundle mainBundle].infoDictionary;
    [copyrightstr appendFormat:@"%@ \r\r",bundleDict[@"NSHumanReadableCopyright"]];
#ifdef oss
#else
    if (((NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"donated"]).boolValue) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MacAppStoreMigrated"]){
            [copyrightstr appendFormat:@"This copy is registered to: MAL Library User"];
        }
        else {
            [copyrightstr appendFormat:@"This copy is registered to: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"donor"]];
        }
        (self.aboutWindowController).appName = @"MAL Updater OS X Pro";
    }
    else {
        [copyrightstr appendString:@"UNREGISTERED COPY"];
        (self.aboutWindowController).appName = @"MAL Updater OS X";
    }
#endif
    (self.aboutWindowController).appCopyright = [[NSAttributedString alloc] initWithString:copyrightstr
                                                                                attributes:@{
                                                                                             NSForegroundColorAttributeName:[NSColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f],
                                                                                             NSFontAttributeName:[NSFont fontWithName:[NSFont systemFontOfSize:12.0f].familyName size:11]}];
    
    [self.aboutWindowController showWindow:nil];
    
}

#pragma mark Timer Functions

- (IBAction)toggletimer:(id)sender {
    //Check to see if there is an API Key stored
    if (![MALEngine checkaccount]) {
        [self showNotification:@"MAL Updater OS X" message:@"Add a login before you start scrobbling."];
    }
    else {
        if (scrobbling == FALSE) {
            [self starttimer];
            togglescrobbler.title = @"Stop Scrobbling";
            [self showNotification:@"MAL Updater OS X" message:@"Auto Scrobble is now turned on."];
            ScrobblerStatus.objectValue = @"Scrobble Status: Started";
            //Set Scrobbling State to true
            scrobbling = TRUE;
        }
        else {
            [self stoptimer];
            togglescrobbler.title = @"Start Scrobbling";
            ScrobblerStatus.objectValue = @"Scrobble Status: Stopped";
            [self showNotification:@"MAL Updater OS X" message:@"Auto Scrobble is now turned off."];
            //Set Scrobbling State to false
            scrobbling = FALSE;
        }
    }
    
}
- (void)autostarttimer {
    //Check to see if there is an API Key stored
    if (![MALEngine checkaccount]) {
        [self showNotification:@"MAL Updater OS X" message:@"Add a login before you start scrobbling."];
    }
    else {
        [self starttimer];
        togglescrobbler.title = @"Stop Scrobbling";
        ScrobblerStatus.objectValue = @"Scrobble Status: Started";
        //Set Scrobbling State to true
        scrobbling = TRUE;
    }
}
- (void)firetimer {
    //Tell MALEngine to detect and scrobble if necessary.
    NSLog(@"Starting...");
    if (!scrobbleractive) {
        scrobbleractive = true;
        // Disable toggle scrobbler and update now menu items
        [self toggleScrobblingUIEnable:false];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseAutoExceptions"]) {
            // Check for latest list of Auto Exceptions automatically each week
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ExceptionsLastUpdated"]) {
                if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"ExceptionsLastUpdated"] timeIntervalSinceNow] < -604800) {
                    // Has been 1 Week, update Auto Exceptions
                    [AutoExceptions updateAutoExceptions];
                }
            }
            else {
                // First time, populate
                [AutoExceptions updateAutoExceptions];
            }
        }
        int status = 0;
        for (int i = 0; i < 2; i++) {
            if (i == 0) {
                if ([MALEngine getQueueCount] > 0 && MALEngine.online) {
                    NSDictionary *ostatus = [MALEngine scrobblefromqueue];
                    int success = [ostatus[@"success"] intValue];
                    int fail = [ostatus[@"fail"] intValue];
                    bool confirmneeded = [ostatus[@"confirmneeded"] boolValue];
                    if (confirmneeded) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self setStatusText:@"Scrobble Status: Please confirm update."];
                            NSDictionary *userinfo = @{@"title": MALEngine.LastScrobbledTitle,  @"episode": MALEngine.LastScrobbledEpisode};
                            [self showConfirmationNotification:@"Confirm Update" message:[NSString stringWithFormat:@"Click here to confirm update for %@ Episode %@.",MALEngine.LastScrobbledActualTitle,MALEngine.LastScrobbledEpisode] updateData:userinfo];
                        });
                        break;
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self showNotification:@"Updated Queued Items" message:[NSString stringWithFormat:@"%i scrobbled successfully and %i failed",success, fail]];
                        });
                    }
                }
            }
            else {
                status = [MALEngine startscrobbling];
                //Enable the Update button if a title is detected
                [self performsendupdatenotification:status];
            }
            
        }
        [self performRefreshUI:status];
    }
}
- (void)starttimer {
    NSLog(@"Auto Scrobble Started.");
    timer = [MSWeakTimer scheduledTimerWithTimeInterval:[(NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"timerinterval"] intValue]
                                                 target:self
                                               selector:@selector(firetimer)
                                               userInfo:nil
                                                repeats:YES
                                          dispatchQueue:_privateQueue];
}
- (void)stoptimer {
    NSLog(@"Stopping Auto Scrobble.");
    //Stop Timer
    [timer invalidate];
}

- (IBAction)updatenow:(id)sender{
    if (![MALEngine checkaccount])
        [self showNotification:@"MAL Updater OS X" message:@"Add a login before you start scrobbling."];
    else {
        dispatch_queue_t queue = dispatch_get_global_queue(
                                                           DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            [self firetimer];
        });
    }
}
#pragma mark Correction
- (IBAction)showCorrectionSearchWindow:(id)sender{
    bool isVisible = window.visible;
    // Stop Timer temporarily if scrobbling is turned on
    if (scrobbling == TRUE) {
        [self stoptimer];
    }
    fsdialog = [FixSearchDialog new];
    // Check if Confirm is on for new title. If so, then disable ability to delete title.
    if ((!confirmupdate.hidden && MALEngine.LastScrobbledTitleNew) || !findtitle.hidden) {
        [fsdialog setCorrection:YES];
        [fsdialog setAllowDelete:NO];
    }
    else {
        [fsdialog setCorrection:YES];
    }
    if (!findtitle.hidden) {
        //Use failed title
        fsdialog.searchquery = MALEngine.FailedTitle;
    }
    else {
        //Get last scrobbled title
        fsdialog.searchquery = MALEngine.LastScrobbledTitle;
    }
    
    if (isVisible) {
        [self.window beginSheet:fsdialog.window completionHandler:^(NSModalResponse returnCode) {
            [self correctionDidEnd:returnCode];
        }];
        [self disableUpdateItems];
    }
    else {
        [self disableUpdateItems];
        [self correctionDidEnd:[NSApp runModalForWindow:fsdialog.window]];
    }
    
}
- (void)correctionDidEnd:(long)returnCode{
    if (returnCode == NSModalResponseOK) {
        if ([fsdialog.selectedaniid isEqualToString:MALEngine.AniID]) {
            NSLog(@"ID matches, correction not needed.");
        }
        else {
            BOOL correctonce = [fsdialog getcorrectonce];
            if (!findtitle.hidden) {
                [self addtoExceptions:MALEngine.FailedTitle newtitle:fsdialog.selectedtitle showid:fsdialog.selectedaniid threshold:fsdialog.selectedtotalepisodes season:MALEngine.FailedSeason];
            }
            else if (MALEngine.LastScrobbledEpisode.intValue == fsdialog.selectedtotalepisodes) {
                // Detected episode equals the total episodes, do not add a rule and only do a correction just once.
                correctonce = true;
            }
            else if (!correctonce) {
                //Add to Exceptions
                [self addtoExceptions:MALEngine.LastScrobbledTitle newtitle:fsdialog.selectedtitle showid:fsdialog.selectedaniid threshold:fsdialog.selectedtotalepisodes season:MALEngine.DetectedSeason];
            }
            if([fsdialog getdeleteTitleonCorrection]) {
                if([MALEngine removetitle:MALEngine.AniID]) {
                    NSLog(@"Removal Successful");
                }
            }
            NSLog(@"Updating corrected title...");
            int status;
            if (!findtitle.hidden) {
                status = [MALEngine scrobbleagain:MALEngine.FailedTitle Episode:MALEngine.FailedEpisode correctonce:false];
            }
            else if (correctonce) {
                status = [MALEngine scrobbleagain:fsdialog.selectedtitle Episode:MALEngine.LastScrobbledEpisode correctonce:true];
            }
            else {
                status = [MALEngine scrobbleagain:MALEngine.LastScrobbledTitle Episode:MALEngine.LastScrobbledEpisode correctonce:false];
            }
            switch (status) {
                case ScrobblerSameEpisodePlaying:
                case ScrobblerUpdateNotNeeded:
                case ScrobblerAddTitleSuccessful:
                case ScrobblerUpdateSuccessful: {
                    [self setStatusText:@"Scrobble Status: Correction Successful..."];
                    [self showNotification:@"MAL Updater OS X" message:@"Correction was successful"];
                    [self setStatusMenuTitleEpisode:MALEngine.LastScrobbledActualTitle episode:MALEngine.LastScrobbledEpisode];
                    [self updateLastScrobbledTitleStatus:false];
                    if (!findtitle.hidden) {
                        //Unhide menus and enable functions on the toolbar
                        [self unhideMenus];
                        [sharetoolbaritem setEnabled:YES];
                        [correcttoolbaritem setEnabled:YES];
                        [openAnimePage setEnabled:YES];
                        shareMenuItem.hidden = NO;
                    }
                    //Show Anime Correct Information
                    NSDictionary *ainfo = MALEngine.LastScrobbledInfo;
                    [self showAnimeInfo:ainfo];
                    [confirmupdate setHidden:true];
                    [findtitle setHidden:true];
                    //Regenerate Share Items
                    [_shareMenu generateShareMenu:@[[NSString stringWithFormat:@"%@ - %@", MALEngine.LastScrobbledTitle, MALEngine.LastScrobbledEpisode ], [NSURL URLWithString:[NSString stringWithFormat:@"http://myanimelist.net/anime/%@", MALEngine.AniID]]]];
                    break;
                }
                default:
                    [self setStatusText:@"Scrobble Status: Correction unsuccessful..."];
                    [self showNotification:@"MAL Updater OS X" message:@"Correction was not successful."];
                    break;
            }
        }
    }
    fsdialog = nil;
    [self enableUpdateItems];
    //Restart Timer
    if (scrobbling == TRUE) {
        [self starttimer];
    }
}
- (void)addtoExceptions:(NSString *)detectedtitle newtitle:(NSString *)title showid:(NSString *)showid threshold:(int)threshold season:(int)season {
    NSManagedObjectContext *moc = managedObjectContext;
    NSFetchRequest *allExceptions = [[NSFetchRequest alloc] init];
    allExceptions.entity = [NSEntityDescription entityForName:@"Exceptions" inManagedObjectContext:moc];
    NSError *error = nil;
    NSArray *exceptions = [moc executeFetchRequest:allExceptions error:&error];
    BOOL exists = false;
    for (NSManagedObject *entry in exceptions) {
        int offset = ((NSNumber *)[entry valueForKey:@"episodeOffset"]).intValue;
        if ([detectedtitle isEqualToString:(NSString *)[entry valueForKey:@"detectedTitle"]] && offset == 0) {
            exists = true;
            break;
        }
    }
    if (!exists) {
        // Add exceptions to Exceptions Entity
        [ExceptionsCache addtoExceptions:detectedtitle correcttitle:title aniid:showid threshold:threshold offset:0 detectedSeason:season];
    }
    //Check if title exists in cache and then remove it
    [ExceptionsCache checkandRemovefromCache:detectedtitle detectedSeason:season];
    
}
#pragma mark History Window functions

- (IBAction)showhistory:(id)sender {
    //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
    [NSApp activateIgnoringOtherApps:YES];
    if (!historywindowcontroller) {
        historywindowcontroller = [[HistoryWindow alloc] init];
    }
    [historywindowcontroller.window makeKeyAndOrderFront:nil];
    
}
#pragma mark StatusIconTooltip, Status Text, Last Scrobbled Title Setters

- (void)setStatusToolTip:(NSString*)toolTip
{
    statusItem.toolTip = toolTip;
}
- (void)setStatusText:(NSString*)messagetext
{
    ScrobblerStatus.objectValue = messagetext;
}
- (void)setLastScrobbledTitle:(NSString*)messagetext
{
    LastScrobbled.objectValue = messagetext;
}
- (void)setStatusMenuTitleEpisode:(NSString *)title episode:(NSString *) episode{
    //Set New Title and Episode
    updatedtitle.title = title;
    updatedepisode.title = [NSString stringWithFormat:@"Episode %@", episode];
}
- (void)updateLastScrobbledTitleStatus:(BOOL)pending{
    if (pending) {
        [updatecorrect setAutoenablesItems:NO];
        lastupdateheader.title = @"Pending:";
        [self setLastScrobbledTitle:[NSString stringWithFormat:@"Pending: %@ - Episode %@ playing from %@",MALEngine.LastScrobbledTitle,MALEngine.LastScrobbledEpisode, MALEngine.LastScrobbledSource]];
        [self setStatusToolTip:[NSString stringWithFormat:@"MAL Updater OS X - %@ - %@ (Pending)",MALEngine.LastScrobbledActualTitle,MALEngine.LastScrobbledEpisode]];
    }
    else if (!MALEngine.online) {
        [updatecorrect setAutoenablesItems:NO];
        lastupdateheader.title = @"Queued:";
        [self setLastScrobbledTitle:[NSString stringWithFormat:@"Queued: %@ - Episode %@ playing from %@",MALEngine.LastScrobbledTitle,MALEngine.LastScrobbledEpisode, MALEngine.LastScrobbledSource]];
        [self setStatusToolTip:[NSString stringWithFormat:@"MAL Updater OS X - %@ - %@ (Queued)",MALEngine.LastScrobbledActualTitle,MALEngine.LastScrobbledEpisode]];
    }
    else {
        [updatecorrect setAutoenablesItems:YES];
        lastupdateheader.title = @"Last Scrobbled:";
        [self setLastScrobbledTitle:[NSString stringWithFormat:@"Last Scrobbled: %@ - Episode %@ playing from %@",MALEngine.LastScrobbledTitle,MALEngine.LastScrobbledEpisode, MALEngine.LastScrobbledSource]];
        [self setStatusToolTip:[NSString stringWithFormat:@"MAL Updater OS X - %@ - %@",MALEngine.LastScrobbledActualTitle,MALEngine.LastScrobbledEpisode]];
    }
}

#pragma mark Update Status functions
- (IBAction)updatestatus:(id)sender {
    [self showUpdateDialog:self.window];
    [self disableUpdateItems];
}
- (IBAction)updatestatusmenu:(id)sender{
    [self showUpdateDialog:nil];
}
- (void)showUpdateDialog:(NSWindow *) w {
    if (!_updatewindow) {
        _updatewindow = [StatusUpdateWindow new];
    }
    // Set completion handler
    __weak MAL_Updater_OS_XAppDelegate *weakself = self;
    _updatewindow.completion = ^void(long returnCode){
        [weakself updateDidEnd:returnCode];
    };
    // Show Dialog
    [_updatewindow showUpdateDialog:w withMALEngine:MALEngine];
}
- (void)updateDidEnd:(long)returnCode {
    __block NSString *tmpepisode = _updatewindow.episodefield.stringValue;
    __block bool episodechanged = false;
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // Check if Episode field is empty. If so, set it to last scrobbled episode
        if (tmpepisode.length == 0) {
            tmpepisode = [NSString stringWithFormat:@"%i", MALEngine.DetectedCurrentEpisode];
        }
        if (tmpepisode.intValue != MALEngine.DetectedCurrentEpisode) {
            episodechanged = true; // Used to update the status window
        }
        
        if (returnCode == NSModalResponseOK) {
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL result = [MALEngine updatestatus:MALEngine.AniID score:(int)_updatewindow.showscore.selectedTag watchstatus:_updatewindow.showstatus.titleOfSelectedItem episode:tmpepisode];
                if (result) {
                    [self setStatusText:@"Scrobble Status: Updating of Watch Status/Score Successful."];
                }
                else{
                    [self setStatusText:@"Scrobble Status: Unable to update Watch Status/Score."];
                }
                
                if (episodechanged) {
                    // Update the tooltip, menu and last scrobbled title
                    [self setStatusMenuTitleEpisode:MALEngine.LastScrobbledActualTitle episode:MALEngine.LastScrobbledEpisode];
                    [self updateLastScrobbledTitleStatus:false];
                    [confirmupdate setHidden:true];
                }
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //If scrobbling is on, restart timer
            if (scrobbling == TRUE) {
                [self starttimer];
            }
            [self enableUpdateItems];
        });
    });
}

#pragma mark Notification Center and Title/Update Confirmation

- (void)showNotification:(NSString *)title message:(NSString *) message{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    notification.soundName = nil;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}
- (void)showConfirmationNotification:(NSString *)title message:(NSString *) message updateData:(NSDictionary *)d{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    notification.soundName = NSUserNotificationDefaultSoundName;
    notification.userInfo = d;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}
- (void) userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if ([notification.title isEqualToString:@"Confirm Update"] && !confirmupdate.hidden) {
        NSString *title = (notification.userInfo)[@"title"];
        NSString *episode = (notification.userInfo)[@"episode"];
        // Only confirm update if the title and episode is the same with the last scrobbled.
        if ([MALEngine.LastScrobbledTitle isEqualToString:title] && episode.intValue == MALEngine.LastScrobbledEpisode.intValue) {
            //Confirm Update
            [self performconfirmupdate];
        }
        else {
            return;
        }
    }
    else if ([notification.title isEqualToString:@"Couldn't find title."] && !findtitle.hidden) {
        //Find title
        [self showCorrectionSearchWindow:nil];
    }
}
- (IBAction)confirmupdate:(id)sender{
    [self performconfirmupdate];
}
- (void)performconfirmupdate{
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        BOOL success = [MALEngine confirmupdate];
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLastScrobbledTitleStatus:false];
                [HistoryWindow addrecord:MALEngine.LastScrobbledActualTitle Episode:MALEngine.LastScrobbledEpisode Date:[NSDate date]];
                [confirmupdate setHidden:YES];
                [self setStatusText:@"Scrobble Status: Update was successful."];
                [self showNotification:@"MAL Updater OS X" message:[NSString stringWithFormat:@"%@ Episode %@ has been updated.",MALEngine.LastScrobbledActualTitle,MALEngine.LastScrobbledEpisode]];
                if (MALEngine.LastScrobbledTitleNew) {
                    // Enable Update Status functions for new and unconfirmed titles.
                    [self EnableStatusUpdating:YES];
                }
            });
            if ([MALEngine getQueueCount] > 0) {
                // Continue to scrobble rest of the queue.
                [self firetimer];
            }
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showNotification:@"MAL Updater OS X" message:@"Failed to confirm update. Please try again later."];
                [self setStatusText:@"Unable to confirm update."];
            });
        }
    });
}
#pragma mark Hotkeys
- (void)registerHotkey{
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kPreferenceScrobbleNowShortcut toAction:^{
         // Scrobble Now Global Hotkey
         dispatch_queue_t queue = dispatch_get_global_queue(
                                                            DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
         
         dispatch_async(queue, ^{
             if ([MALEngine checkaccount] && !panelactive) {
                 [self firetimer];
             }
         });
     }];
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kPreferenceShowStatusMenuShortcut toAction:^{
         // Status Window Toggle Global Hotkey
         [self togglescrobblewindow:nil];
     }];
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kPreferenceToggleScrobblingShortcut toAction:^{
         // Auto Scrobble Toggle Global Hotkey
         [self toggletimer:nil];
     }];
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kPreferenceConfirmUpdateShortcut toAction:^{
         // Confirm Update Hotkey
         if (!confirmupdate.hidden) {
             [self performconfirmupdate];
         }
     }];
}
#pragma mark Misc

- (void)showAnimeInfo:(NSDictionary *)d{
    //Empty
    animeinfo.string = @"";
    // Show Actual Title
    [self appendToAnimeInfo:MALEngine.LastScrobbledActualTitle];
    [self appendToAnimeInfo:@""];
    //Description
    NSString *anidescription = d[@"synopsis"];
    if (d[@"synopsis"] != [NSNull null]) {
        anidescription = [anidescription stripHtml]; //Removes HTML tags
        [self appendToAnimeInfo:@"Description"];
        
    }
    else {
        anidescription = @"No description available.";
    }
    [self appendToAnimeInfo:anidescription];
    //Meta Information
    [self appendToAnimeInfo:@""];
    [self appendToAnimeInfo:@"Other Information"];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Classification: %@", d[@"classification"]]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Start Date: %@", d[@"start_date"]]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Airing Status: %@", d[@"status"]]];
    NSString *epi;
    if (d[@"episodes"] == [NSNull null]) {
        epi = @"Unknown";
    }
    else {
        epi = d[@"episodes"];
    }
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Episodes: %@", epi]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Popularity: %@", d[@"popularity_rank"]]];
    if (d[@"favorited_count"]) {
        [self appendToAnimeInfo:[NSString stringWithFormat:@"Favorited: %@", d[@"favorited_count"]]];
    }
    //Image
    NSImage *dimg = (d[@"image_url"] != [NSNull null]) ? [[NSImage alloc]initByReferencingURL:[NSURL URLWithString: (NSString *)d[@"image_url"]]] : [NSImage imageNamed:@"missing"]; //Downloads Image
    img.image = dimg; //Get the Image for the title
    // Clear Anime Info so that MAL Updater OS X won't attempt to retrieve it if the same episode and title is playing
    [MALEngine clearAnimeInfo];
    // Show now playing view
    _nowplayingview.hidden = NO;
    _nothingplayingview.hidden = YES;
}
- (void)appendToAnimeInfo:(NSString*)text
{
    NSAttributedString* attr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ \n", text]];
    
    [animeinfo.textStorage appendAttributedString:attr];
}
- (NSDictionary *)getNowPlaying{
    // Outputs Currently Playing information into JSON
    NSMutableDictionary *output = [NSMutableDictionary new];
    if ((MALEngine.getLastScrobbledTitle).length > 0) {
        output[@"id"] = MALEngine.AniID;
        output[@"scrobbledtitle"] = MALEngine.LastScrobbledTitle;
        output[@"scrobbledactualtitle"] = MALEngine.LastScrobbledActualTitle;
        output[@"scrobbledEpisode"] = MALEngine.LastScrobbledEpisode;
        output[@"source"] = MALEngine.LastScrobbledSource;
    }
    return output;
}

- (IBAction)showLastScrobbledInformation:(id)sender{
    //Open the anime's page on MyAnimeList in the default web browser
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://myanimelist.net/anime/%@", MALEngine.AniID]]];
}

#pragma mark Torrent Browser
- (IBAction)openTorrentBrowser:(id)sender {
#ifdef oss
#else
    //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
    [NSApp activateIgnoringOtherApps:YES];
    [_tbc.window makeKeyAndOrderFront:self];
#endif
}
@end
