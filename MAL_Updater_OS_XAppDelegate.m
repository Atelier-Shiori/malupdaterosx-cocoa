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
#import "DonationWindowController.h"
#import "OfflineViewQueue.h"
#import "MSWeakTimer.h"
#import "streamlinkopen.h"
#import <streamlinkdetect/streamlinkdetect.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <MALLibraryAppMigrate/MALLibraryAppMigrate.h>

@implementation MAL_Updater_OS_XAppDelegate

@synthesize window;
@synthesize updatepanel;
@synthesize fsdialog;
@synthesize historywindowcontroller;
@synthesize managedObjectContext;
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
    NSString *basePath = ([paths count] > 0) ? paths[0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"MAL Updater OS X"];
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
	
    NSManagedObjectModel *mom = [self managedObjectModel];
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
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
	
    return managedObjectContext;
}
+ (void)initialize
{
	//Create a Dictionary
	NSMutableDictionary * defaultValues = [NSMutableDictionary dictionary];
	
	// Defaults
	defaultValues[@"Base64Token"] = @"";
	defaultValues[@"MALAPIURL"] = @"https://malapi.ateliershiori.moe";
	defaultValues[@"ScrobbleatStartup"] = @NO;
    defaultValues[@"useSearchCache"] = @YES;
    defaultValues[@"exceptions"] = [[NSMutableArray alloc] init];
    defaultValues[@"ignoredirectories"] = [[NSMutableArray alloc] init];
    defaultValues[@"IgnoreTitleRules"] = [[NSMutableArray alloc] init];
    defaultValues[@"ConfirmNewTitle"] = @YES;
    defaultValues[@"ConfirmUpdates"] = @NO;
	defaultValues[@"UseAutoExceptions"] = @YES;
    defaultValues[@"enablekodiapi"] = @NO;
    defaultValues[@"kodiaddress"] = @"";
    defaultValues[@"kodiport"] = @"3005";
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9) {
        //Yosemite Specific Advanced Options
        defaultValues[@"DisableYosemiteTitleBar"] = @NO;
        defaultValues[@"DisableYosemiteVibrance"] = @NO;
    }
    defaultValues[@"timerinterval"] = @(300);
    defaultValues[@"showcorrection"] = @YES;
    defaultValues[@"NSApplicationCrashOnExceptions"] = @YES;
    defaultValues[@"donated"] = @NO;
    defaultValues[@"MacAppStoreMigrated"] = @NO;
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
    [statusItem setImage:statusImage];

    //Tells the NSStatusItem what menu to load
    [statusItem setMenu:statusMenu];
    
    //Sets the tooptip for our item
    [statusItem setToolTip:@"MAL Updater OS X"];
    
    //Enables highlighting
    [statusItem setHighlightMode:YES];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Initialize MALEngine
	MALEngine = [[MyAnimeList alloc] init];
    [MALEngine setManagedObjectContext:managedObjectContext];
    #ifdef DEBUG
    #else
        // Check if build is prerelease. Notify user if user is not registered
        [MALLibraryAppStoreMigrate checkPreRelease];
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
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
	
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
            NSRect frame = [window frame];
            frame.size = CGSizeMake(440, 291);
            [window setFrame:frame display:YES];
        }
        if ([defaults boolForKey:@"DisableYosemiteVibrance"] != 1) {
            //Add NSVisualEffectView to Window
            [windowcontent setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
            [windowcontent setMaterial:NSVisualEffectMaterialLight];
            [windowcontent setState:NSVisualEffectStateFollowsWindowActiveState];
            [windowcontent setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantLight]];
            //Make Animeinfo textview transparrent
            [animeinfooutside setDrawsBackground:NO];
            [animeinfo setBackgroundColor:[NSColor clearColor]];
        }
        else {
            [windowcontent setState:NSVisualEffectStateInactive];
            [animeinfooutside setDrawsBackground:NO];
            [animeinfo setBackgroundColor:[NSColor clearColor]];
        }
        
    }
    // Fix template images
    // There is a bug where template images are not made even if they are set in XCAssets
    NSArray *images = @[@"update", @"history", @"correct", @"Info", @"clear"];
    NSImage * image;
    for (NSString *imagename in images) {
        image = [NSImage imageNamed:imagename];
        [image setTemplate:YES];
    }
	
	// Notify User if there is no Account Info
	if (![MALEngine checkaccount]) {
        // First time prompt
        NSAlert * alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:@"Welcome to MAL Updater OS X"];
        [alert setInformativeText:@"Before using this program, you need to login. Do you want to open Preferences to log in now?\r\rPlease note that MAL Updater OS X now stores user information in the Keychain and therefore, you must login again."];
        // Set Message type to Warning
        [alert setAlertStyle:NSInformationalAlertStyle];
        if ([alert runModal]== NSAlertFirstButtonReturn) {
            // Show Preference Window and go to Login Preference Pane
            [NSApp activateIgnoringOtherApps:YES];
            [self.preferencesWindowController showWindow:nil];
            [(MASPreferencesWindowController *)self.preferencesWindowController selectControllerAtIndex:1];
        }
	}
    if ([Utility checkoldAPI]) {
        [self showNotification:@"MAL Updater OS X" message:@"The API URL has been automatically updated."];
        [[NSUserDefaults standardUserDefaults] setObject:@"https://malapi.ateliershiori.moe" forKey:@"MALAPIURL"];
    }
	// Autostart Scrobble at Startup
	if ([defaults boolForKey:@"ScrobbleatStartup"] == 1) {
		[self autostarttimer];
	}
    // Import existing Exceptions Data
    [AutoExceptions importToCoreData];
    // Show Donation Message
    [Utility donateCheck:self];
    // Fabric
    [Fabric with:@[[Crashlytics class]]];
}
#pragma mark General UI Functions
- (NSWindowController *)preferencesWindowController
{
    if (!_preferencesWindowController)
    {
        NSViewController *generalViewController = [[GeneralPrefController alloc] init];
        NSViewController *loginViewController = [[LoginPref alloc] initwithAppDelegate:self];
		NSViewController *suViewController = [[SoftwareUpdatesPref alloc] init];
        NSViewController *exceptionsViewController = [[ExceptionsPref alloc] init];
        NSViewController *hotkeyViewController = [[HotkeysPrefs alloc] init];
        NSViewController *advancedViewController = [[AdvancedPrefController alloc] initwithAppDelegate:self];
        NSArray *controllers = @[generalViewController, loginViewController, hotkeyViewController, exceptionsViewController, suViewController, advancedViewController];
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
	
    if (![managedObjectContext hasChanges]) return NSTerminateNow;
	
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
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
		
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
		
    }
	
    return NSTerminateNow;
}
- (IBAction)togglescrobblewindow:(id)sender
{
	if ([window isVisible]) {
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
    if (!_dwindow) {
        _dwindow = [[DonationWindowController alloc] init];
    }
    [[_dwindow window] makeKeyAndOrderFront:nil];
    
}
- (IBAction)showOfflineQueue:(id)sender{
    //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
    [NSApp activateIgnoringOtherApps:YES];
    if (!_owindow) {
        _owindow = [[OfflineViewQueue alloc] init];
    }
    [[_owindow window] makeKeyAndOrderFront:nil];
    
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
    if (!confirmupdate.hidden && ![MALEngine getisNewTitle]) {
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
	    [statusMenu setAutoenablesItems:enable];
	    [updatenow setEnabled:enable];
	    [togglescrobbler setEnabled:enable];
	    [confirmupdate setEnabled:enable];
	    [findtitle setEnabled:enable];
	    [openstream setEnabled:enable];
	    if (!enable) {
	        [updatenow setTitle:@"Updating..."];
	        [self setStatusText:@"Scrobble Status: Scrobbling..."];
	    }
	    else {
	        [updatenow setTitle:@"Update Now"];
	    }
	});
}
- (void)EnableStatusUpdating:(BOOL)enable{
    [updatecorrect setAutoenablesItems:enable];
    [updatetoolbaritem setEnabled:enable];
    [updatedupdatestatus setEnabled:enable];
}
- (void)performsendupdatenotification:(int)status{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (status) { 
            case ScrobblerNothingPlaying:
                [self setStatusText:@"Scrobble Status: Idle..."];
                break;
            case ScrobblerSameEpisodePlaying:
                [self setStatusText:@"Scrobble Status: Same Episode Playing, Scrobble not needed."];
                break;
            case ScrobblerUpdateNotNeeded:
                [self setStatusText:@"Scrobble Status: No update needed."];
                break;
            case ScrobblerConfirmNeeded: {
                [self setStatusText:@"Scrobble Status: Please confirm update."];
                NSDictionary * userinfo = @{@"title": [MALEngine getLastScrobbledTitle],  @"episode": [MALEngine getLastScrobbledEpisode]};
                [self showConfirmationNotification:@"Confirm Update" message:[NSString stringWithFormat:@"Click here to confirm update for %@ Episode %@.",[MALEngine getLastScrobbledActualTitle],[MALEngine getLastScrobbledEpisode]] updateData:userinfo];
                break;
            }
            case ScrobblerAddTitleSuccessful:
            case ScrobblerUpdateSuccessful:
                [self setStatusText:@"Scrobble Status: Scrobble Successful..."];
                [self showNotification:@"Scrobble Successful."message:[NSString stringWithFormat:@"%@ - %@",[MALEngine getLastScrobbledActualTitle],[MALEngine getLastScrobbledEpisode]]];
                //Add History Record
                [HistoryWindow addrecord:[MALEngine getLastScrobbledActualTitle] Episode:[MALEngine getLastScrobbledEpisode] Date:[NSDate date]];
                break;
            case ScrobblerOfflineQueued:
                [self setStatusText:@"Scrobble Status: Scrobble Queued..."];
                [self showNotification:@"Scrobble Queued." message:[NSString stringWithFormat:@"%@ - %@",[MALEngine getLastScrobbledActualTitle],[MALEngine getLastScrobbledEpisode]]];
                break;
            case ScrobblerTitleNotFound:
                if (![(NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"showcorrection"] boolValue]) {
                    [self setStatusText:@"Scrobble Status: Couldn't find title."];
                    [self showNotification:@"Couldn't find title." message:[NSString stringWithFormat:@"Click here to find %@ manually.", [MALEngine getFailedTitle]]];
                }
                break;
            case ScrobblerAddTitleFailed:
            case ScrobblerUpdateFailed:
                [self showNotification:@"Scrobble Unsuccessful." message:@"Retrying in 5 mins..."];
                [self setStatusText:@"Scrobble Status: Scrobble Failed. Retrying in 5 mins..."];
                break;
            case ScrobblerFailed:
                [self showNotification:@"Scrobble Unsuccessful." message:@"Check user credentials in Preferences. You may need to login again."];
                [self setStatusText:@"Scrobble Status: Scrobble Failed. User credentials might have expired or MAL Updater OS X needs to be updated."];
                break;
            default:
                break;
        }
    });
}

- (void)performRefreshUI:(int)status{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([MALEngine getSuccess] == 1) {
            [findtitle setHidden:true];
            if ([MALEngine getOnlineStatus]) {
                [self setStatusMenuTitleEpisode:[MALEngine getLastScrobbledActualTitle] episode:[MALEngine getLastScrobbledEpisode]];
                if (status != 3 && [MALEngine getConfirmed]) {
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
                    if ([MALEngine getisNewTitle]) {
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
                NSDictionary * ainfo = [MALEngine getLastScrobbledInfo];
                if (ainfo !=nil) { // Checks if MAL Updater OS X already populated info about the just updated title.
                    [self showAnimeInfo:ainfo];
                    [self generateShareMenu];
                    [shareMenuItem setHidden:NO];
                }
            }
            else {
                [self updateLastScrobbledTitleStatus:false];
                [self setStatusMenuTitleEpisode:[MALEngine getLastScrobbledTitle] episode:[MALEngine getLastScrobbledEpisode]];
                [self EnableStatusUpdating:NO];
                [animeinfo setString:@"No information available."];
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
            if ([(NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"showcorrection"] boolValue]) {
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
    [shareMenu removeAllItems];
    // Workaround for Share Toolbar Item
    NSMenuItem *shareIcon = [[NSMenuItem alloc] init];
    shareIcon.image = [NSImage imageNamed:NSImageNameShareTemplate];
    [shareIcon setHidden:YES];
    shareIcon.title = @"";
    [shareMenu addItem:shareIcon];
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


#pragma mark Timer Functions

- (IBAction)toggletimer:(id)sender {
	//Check to see if there is an API Key stored
	if (![MALEngine checkaccount]) {
        [self showNotification:@"MAL Updater OS X" message:@"Add a login before you start scrobbling."];
	}
	else {
		if (scrobbling == FALSE) {
			[self starttimer];
			[togglescrobbler setTitle:@"Stop Scrobbling"];
            [self showNotification:@"MAL Updater OS X" message:@"Auto Scrobble is now turned on."];
			[ScrobblerStatus setObjectValue:@"Scrobble Status: Started"];
			//Set Scrobbling State to true
			scrobbling = TRUE;
		}
		else {
			[self stoptimer];
			[togglescrobbler setTitle:@"Start Scrobbling"];
			[ScrobblerStatus setObjectValue:@"Scrobble Status: Stopped"];
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
		[togglescrobbler setTitle:@"Stop Scrobbling"];
		[ScrobblerStatus setObjectValue:@"Scrobble Status: Started"];
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
                if ([MALEngine getQueueCount] > 0 && [MALEngine getOnlineStatus]) {
                    NSDictionary * status = [MALEngine scrobblefromqueue];
                    int success = [status[@"success"] intValue];
                    int fail = [status[@"fail"] intValue];
                    bool confirmneeded = [status[@"confirmneeded"] boolValue];
                    if (confirmneeded) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                        [self setStatusText:@"Scrobble Status: Please confirm update."];
                        NSDictionary * userinfo = @{@"title": [MALEngine getLastScrobbledTitle],  @"episode": [MALEngine getLastScrobbledEpisode]};
                        [self showConfirmationNotification:@"Confirm Update" message:[NSString stringWithFormat:@"Click here to confirm update for %@ Episode %@.",[MALEngine getLastScrobbledActualTitle],[MALEngine getLastScrobbledEpisode]] updateData:userinfo];
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
    timer = [MSWeakTimer scheduledTimerWithTimeInterval:[[(NSNumber *)[NSUserDefaults standardUserDefaults] valueForKey:@"timerinterval"] intValue]
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
    bool isVisible = [window isVisible];
    // Stop Timer temporarily if scrobbling is turned on
    if (scrobbling == TRUE) {
        [self stoptimer];
    }
    fsdialog = [FixSearchDialog new];
    // Check if Confirm is on for new title. If so, then disable ability to delete title.
    if ((!confirmupdate.hidden && [MALEngine getisNewTitle]) || !findtitle.hidden) {
        [fsdialog setCorrection:YES];
        [fsdialog setAllowDelete:NO];
    }
    else {
        [fsdialog setCorrection:YES];
    }
    if (!findtitle.hidden) {
        //Use failed title
         [fsdialog setSearchField:[MALEngine getFailedTitle]];
    }
    else {
        //Get last scrobbled title
        [fsdialog setSearchField:[MALEngine getLastScrobbledTitle]];
    }
   
    if (isVisible) {
        [NSApp beginSheet:[fsdialog window]
           modalForWindow:window modalDelegate:self
           didEndSelector:@selector(correctionDidEnd:returnCode:contextInfo:)
              contextInfo:(void *)nil];
        [self disableUpdateItems];
    }
    else {
        [NSApp beginSheet:[fsdialog window]
           modalForWindow:nil modalDelegate:self
           didEndSelector:@selector(correctionDidEnd:returnCode:contextInfo:)
              contextInfo:(void *)nil];
    }
    
}
- (void)correctionDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1) {
        if ([[fsdialog getSelectedAniID] isEqualToString:[MALEngine getAniID]]) {
            NSLog(@"ID matches, correction not needed.");
        }
        else {
            BOOL correctonce = [fsdialog getcorrectonce];
            if (!findtitle.hidden) {
                [self addtoExceptions:[MALEngine getFailedTitle] newtitle:[fsdialog getSelectedTitle] showid:[fsdialog getSelectedAniID] threshold:[fsdialog getSelectedTotalEpisodes]];
            }
            else if ([[MALEngine getLastScrobbledEpisode] intValue] == [fsdialog getSelectedTotalEpisodes]) {
                // Detected episode equals the total episodes, do not add a rule and only do a correction just once.
                correctonce = true;
            }
            else if (!correctonce) {
                //Add to Exceptions
                [self addtoExceptions:[MALEngine getLastScrobbledTitle] newtitle:[fsdialog getSelectedTitle] showid:[fsdialog getSelectedAniID] threshold:[fsdialog getSelectedTotalEpisodes]];
            }
            if([fsdialog getdeleteTitleonCorrection]) {
                if([MALEngine removetitle:[MALEngine getAniID]]) {
                    NSLog(@"Removal Successful");
                }
            }
            NSLog(@"Updating corrected title...");
            int status;
            if (!findtitle.hidden) {
                status = [MALEngine scrobbleagain:[MALEngine getFailedTitle] Episode:[MALEngine getFailedEpisode] correctonce:false];
            }
            else if (correctonce) {
                status = [MALEngine scrobbleagain:[fsdialog getSelectedTitle] Episode:[MALEngine getLastScrobbledEpisode] correctonce:true];
            }
            else {
                status = [MALEngine scrobbleagain:[MALEngine getLastScrobbledTitle] Episode:[MALEngine getLastScrobbledEpisode] correctonce:false];
            }
            switch (status) {
                case ScrobblerSameEpisodePlaying:
                case ScrobblerUpdateNotNeeded:
                case ScrobblerAddTitleSuccessful:
                case ScrobblerUpdateSuccessful: {
                    [self setStatusText:@"Scrobble Status: Correction Successful..."];
                    [self showNotification:@"MAL Updater OS X" message:@"Correction was successful"];
                    [self setStatusMenuTitleEpisode:[MALEngine getLastScrobbledActualTitle] episode:[MALEngine getLastScrobbledEpisode]];
                    [self updateLastScrobbledTitleStatus:false];
                    if (!findtitle.hidden) {
                        //Unhide menus and enable functions on the toolbar
                        [self unhideMenus];
                        [sharetoolbaritem setEnabled:YES];
                        [correcttoolbaritem setEnabled:YES];
                        [openAnimePage setEnabled:YES];
                    }
                    //Show Anime Correct Information
                    NSDictionary * ainfo = [MALEngine getLastScrobbledInfo];
                    [self showAnimeInfo:ainfo];
					[confirmupdate setHidden:true];
                    [findtitle setHidden:true];
					//Regenerate Share Items
					[self generateShareMenu];
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
- (void)addtoExceptions:(NSString *)detectedtitle newtitle:(NSString *)title showid:(NSString *)showid threshold:(int)threshold{
    NSManagedObjectContext * moc = managedObjectContext;
    NSFetchRequest * allExceptions = [[NSFetchRequest alloc] init];
    [allExceptions setEntity:[NSEntityDescription entityForName:@"Exceptions" inManagedObjectContext:moc]];
    NSError * error = nil;
    NSArray * exceptions = [moc executeFetchRequest:allExceptions error:&error];
    BOOL exists = false;
    for (NSManagedObject * entry in exceptions) {
        int offset = [(NSNumber *)[entry valueForKey:@"episodeOffset"] intValue];
        if ([detectedtitle isEqualToString:(NSString *)[entry valueForKey:@"detectedTitle"]] && offset == 0) {
            exists = true;
            break;
        }
    }
    if (!exists) {
        // Add exceptions to Exceptions Entity
        [ExceptionsCache addtoExceptions:detectedtitle correcttitle:title aniid:showid threshold:threshold offset:0];
    }
    //Check if title exists in cache and then remove it
    [ExceptionsCache checkandRemovefromCache:detectedtitle];
    
}
#pragma mark History Window functions

- (IBAction)showhistory:(id)sender {
		//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
		[NSApp activateIgnoringOtherApps:YES];
    if (!historywindowcontroller) {
        historywindowcontroller = [[HistoryWindow alloc] init];
    }
		[[historywindowcontroller window] makeKeyAndOrderFront:nil];

}
#pragma mark StatusIconTooltip, Status Text, Last Scrobbled Title Setters

- (void)setStatusToolTip:(NSString*)toolTip
{
    [statusItem setToolTip:toolTip];
}
- (void)setStatusText:(NSString*)messagetext
{
	[ScrobblerStatus setObjectValue:messagetext];
}
- (void)setLastScrobbledTitle:(NSString*)messagetext
{
	[LastScrobbled setObjectValue:messagetext];
}
- (void)setStatusMenuTitleEpisode:(NSString *)title episode:(NSString *) episode{
    //Set New Title and Episode
    [updatedtitle setTitle:title];
    [updatedepisode setTitle:[NSString stringWithFormat:@"Episode %@", episode]];
}
- (void)updateLastScrobbledTitleStatus:(BOOL)pending{
    if (pending) {
        [updatecorrect setAutoenablesItems:NO];
        [lastupdateheader setTitle:@"Pending:"];
        [self setLastScrobbledTitle:[NSString stringWithFormat:@"Pending: %@ - Episode %@ playing from %@",[MALEngine getLastScrobbledTitle],[MALEngine getLastScrobbledEpisode], [MALEngine getLastScrobbledSource]]];
        [self setStatusToolTip:[NSString stringWithFormat:@"MAL Updater OS X - %@ - %@ (Pending)",[MALEngine getLastScrobbledActualTitle],[MALEngine getLastScrobbledEpisode]]];
    }
    else if (![MALEngine getOnlineStatus]) {
        [updatecorrect setAutoenablesItems:NO];
        [lastupdateheader setTitle:@"Queued:"];
        [self setLastScrobbledTitle:[NSString stringWithFormat:@"Queued: %@ - Episode %@ playing from %@",[MALEngine getLastScrobbledTitle],[MALEngine getLastScrobbledEpisode], [MALEngine getLastScrobbledSource]]];
        [self setStatusToolTip:[NSString stringWithFormat:@"MAL Updater OS X - %@ - %@ (Queued)",[MALEngine getLastScrobbledActualTitle],[MALEngine getLastScrobbledEpisode]]];
    }
    else {
        [updatecorrect setAutoenablesItems:YES];
        [lastupdateheader setTitle:@"Last Scrobbled:"];
        [self setLastScrobbledTitle:[NSString stringWithFormat:@"Last Scrobbled: %@ - Episode %@ playing from %@",[MALEngine getLastScrobbledTitle],[MALEngine getLastScrobbledEpisode], [MALEngine getLastScrobbledSource]]];
        [self setStatusToolTip:[NSString stringWithFormat:@"MAL Updater OS X - %@ - %@",[MALEngine getLastScrobbledActualTitle],[MALEngine getLastScrobbledEpisode]]];
    }
}

#pragma mark Getters
- (bool)getisScrobbling{
    return scrobbling;
}
- (bool)getisScrobblingActive{
    return scrobbleractive;
}
- (NSManagedObjectContext *)getObjectContext{
    return managedObjectContext;
}
- (MyAnimeList *)getMALEngineInstance{
    return MALEngine;
}
#pragma mark Update Status functions
- (IBAction)updatestatus:(id)sender {
    [self showUpdateDialog:[self window]];
    [self disableUpdateItems];
}
- (IBAction)updatestatusmenu:(id)sender{
    [self showUpdateDialog:nil];
}
- (void)showUpdateDialog:(NSWindow *) w{
	// Show Sheet
	[NSApp beginSheet:updatepanel
	   modalForWindow:w modalDelegate:self
	   didEndSelector:@selector(updateDidEnd:returnCode:contextInfo:)
		   contextInfo:(void *)nil];
	// Set up UI
	[showtitle setObjectValue:[MALEngine getLastScrobbledTitle]];
	[showscore selectItemWithTag:[MALEngine getScore]];
	[showstatus selectItemAtIndex:[MALEngine getWatchStatus]];
    [episodefield setStringValue:[NSString stringWithFormat:@"%i", [MALEngine getCurrentEpisode]]];
    if ([MALEngine getTotalEpisodes] !=0) {
        [epiformatter setMaximum:@([MALEngine getTotalEpisodes])];
    }
	// Stop Timer temporarily if scrobbling is turned on
	if (scrobbling == TRUE) {
		[self stoptimer];
	}
	
}
- (void)updateDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
    // Check if Episode field is empty. If so, set it to last scrobbled episode
    NSString * tmpepisode = [episodefield stringValue];
    bool episodechanged = false;
    if (tmpepisode.length == 0) {
        tmpepisode = [NSString stringWithFormat:@"%i", [MALEngine getCurrentEpisode]];
    }
    if ([tmpepisode intValue] != [MALEngine getCurrentEpisode]) {
        episodechanged = true; // Used to update the status window
    }

    if (returnCode == 1) {
         dispatch_async(dispatch_get_main_queue(), ^{
        BOOL result = [MALEngine updatestatus:[MALEngine getAniID] score:(int) [showscore selectedTag] watchstatus:[showstatus titleOfSelectedItem] episode:tmpepisode];
        if (result)
            [self setStatusText:@"Scrobble Status: Updating of Watch Status/Score Successful."];
        if (episodechanged) {
            // Update the tooltip, menu and last scrobbled title
            [self setStatusMenuTitleEpisode:[MALEngine getLastScrobbledActualTitle] episode:[MALEngine getLastScrobbledEpisode]];
            [self updateLastScrobbledTitleStatus:false];
            [confirmupdate setHidden:true];
        }
        else
            [self setStatusText:@"Scrobble Status: Unable to update Watch Status/Score."];
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

- (IBAction)closeupdatestatus:(id)sender {
	[updatepanel orderOut:self];
	[NSApp endSheet:updatepanel returnCode:0];
}
- (IBAction)updatetitlestatus:(id)sender {
	[updatepanel orderOut:self];
	[NSApp endSheet:updatepanel returnCode:1];
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
        NSString * title = (notification.userInfo)[@"title"];
        NSString * episode = (notification.userInfo)[@"episode"];
        // Only confirm update if the title and episode is the same with the last scrobbled.
        if ([[MALEngine getLastScrobbledTitle] isEqualToString:title] && [episode intValue] == [[MALEngine getLastScrobbledEpisode] intValue]) {
            //Confirm Update
            [self confirmupdate];
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
    [self confirmupdate];
}
- (void)confirmupdate{
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
    BOOL success = [MALEngine confirmupdate];
    if (success) {
         dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLastScrobbledTitleStatus:false];
        [HistoryWindow addrecord:[MALEngine getLastScrobbledActualTitle] Episode:[MALEngine getLastScrobbledEpisode] Date:[NSDate date]];
        [confirmupdate setHidden:YES];
        [self setStatusText:@"Scrobble Status: Update was successful."];
        [self showNotification:@"MAL Updater OS X" message:[NSString stringWithFormat:@"%@ Episode %@ has been updated.",[MALEngine getLastScrobbledActualTitle],[MALEngine getLastScrobbledEpisode]]];
        if ([MALEngine getisNewTitle]) {
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
            [self confirmupdate];
        }
    }];
}
#pragma mark Misc

- (void)showAnimeInfo:(NSDictionary *)d{
    //Empty
    [animeinfo setString:@""];
    // Show Actual Title
    [self appendToAnimeInfo:[MALEngine getLastScrobbledActualTitle]];
    [self appendToAnimeInfo:@""];
    //Description
    NSString * anidescription = d[@"synopsis"];
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
    NSString * epi;
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
    NSImage * dimg = [[NSImage alloc]initByReferencingURL:[NSURL URLWithString: (NSString *)d[@"image_url"]]]; //Downloads Image
    [img setImage:dimg]; //Get the Image for the title
    // Clear Anime Info so that MAL Updater OS X won't attempt to retrieve it if the same episode and title is playing
    [MALEngine clearAnimeInfo];
    // Show now playing view
    _nowplayingview.hidden = NO;
    _nothingplayingview.hidden = YES;
}
- (void)appendToAnimeInfo:(NSString*)text
{
    NSAttributedString* attr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ \n", text]];
        
    [[animeinfo textStorage] appendAttributedString:attr];
}
- (NSDictionary *)getNowPlaying{
    // Outputs Currently Playing information into JSON
    NSMutableDictionary * output = [NSMutableDictionary new];
    if ([MALEngine.getLastScrobbledTitle length] > 0) {
        [output setObject:[MALEngine getAniID] forKey:@"id"];
        [output setObject:[MALEngine getLastScrobbledTitle] forKey:@"scrobbledtitle"];
        [output setObject:[MALEngine getLastScrobbledActualTitle] forKey:@"scrobbledactualtitle"];
        [output setObject:[MALEngine getLastScrobbledEpisode] forKey:@"scrobbledEpisode"];
        [output setObject:[MALEngine getLastScrobbledSource] forKey:@"source"];
    }
    return output;
}
#pragma mark Share Services
- (void)generateShareMenu{
    //Clear Share Menu
    [shareMenu removeAllItems];
    // Workaround for Share Toolbar Item
    NSMenuItem *shareIcon = [[NSMenuItem alloc] init];
    [shareIcon setImage:[NSImage imageNamed:NSImageNameShareTemplate]];
    [shareIcon setHidden:YES];
    [shareIcon setTitle:@""];
    [shareMenu addItem:shareIcon];
    //Generate Items to Share
    shareItems = @[[NSString stringWithFormat:@"%@ - %@", [MALEngine getLastScrobbledTitle], [MALEngine getLastScrobbledEpisode] ], [NSURL URLWithString:[NSString stringWithFormat:@"http://myanimelist.net/anime/%@", [MALEngine getAniID]]]];
    //Get Share Services for Items
    NSArray *shareServiceforItems = [NSSharingService sharingServicesForItems:shareItems];
    //Generate Share Items and populate Share Menu
    for (NSSharingService * cservice in shareServiceforItems) {
        NSMenuItem * item = [[NSMenuItem alloc] initWithTitle:[cservice title] action:@selector(shareFromService:) keyEquivalent:@""];
        [item setRepresentedObject:cservice];
        [item setImage:[cservice image]];
        [item setTarget:self];
        [shareMenu addItem:item];
    }
}
- (IBAction)shareFromService:(id)sender{
    // Share Item
    [[sender representedObject] performWithItems:shareItems];
}
- (IBAction)showLastScrobbledInformation:(id)sender{
    //Open the anime's page on MyAnimeList in the default web browser
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://myanimelist.net/anime/%@", [MALEngine getAniID]]]];
}
#pragma mark Streamlink
- (IBAction)openstream:(id)sender {
    if ([MALEngine checkaccount]) {
        streamlinkdetector * detector = [streamlinkdetector new];
        if ([detector checkifStreamLinkExists]) {
            // Shows the Open Stream dialog
            [NSApp activateIgnoringOtherApps:YES];
            if ([MALEngine getOnlineStatus]) {
                if (!streamlinkopenw)
                    streamlinkopenw = [streamlinkopen new];
                
                bool isVisible = window.visible;
                if (isVisible) {
                    [self disableUpdateItems]; //Prevent user from opening up another modal window if access from Status Window
                    [NSApp beginSheet:streamlinkopenw.window
                       modalForWindow:window modalDelegate:self
                       didEndSelector:@selector(streamopenDidEnd:returnCode:contextInfo:)
                          contextInfo:(void *)nil];
                }
                else {
                    [NSApp beginSheet:streamlinkopenw.window
                       modalForWindow:nil modalDelegate:self
                       didEndSelector:@selector(streamopenDidEnd:returnCode:contextInfo:)
                          contextInfo:(void *)nil];
                }
            }
            else {
                [self showNotification:NSLocalizedString(@"MAL Updater OS X",nil) message:NSLocalizedString(@"You need to be online to use this feature.",nil)];
            }
        }
        else {
            [detector checkStreamLink:nil];
        }
    }
    else {
        [self showNotification:@"MAL Updater OS X" message:@"Add a login before you use this feature."];
    }
}
- (void)streamopenDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 0) {
        [self enableUpdateItems];
        streamlinkopenw = nil;
    }
    else {
        [self toggleScrobblingUIEnable:false];
        NSString * streamurl = streamlinkopenw.streamurl.stringValue;
        NSString * stream = streamlinkopenw.streams.title;
        dispatch_queue_t queue = dispatch_get_global_queue(
                                                           DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(queue, ^{
            int status = [MALEngine scrobblefromstreamlink:streamurl withStream:stream];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performsendupdatenotification:status];
                [self performRefreshUI:status];
                streamlinkopenw = nil;
            });
        });
    }
}

@end
