//
//  MAL_Updater_OS_XAppDelegate.m
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "MAL_Updater_OS_XAppDelegate.h"
#import "PFMoveApplication.h"
#import "GeneralPrefController.h"
#import "MASPreferencesWindowController.h"
#import "LoginPref.h"
#import "SoftwareUpdatesPref.h"
#import "NSString_stripHtml.h"
#import "ExceptionsPref.h"
#import "HotkeysPrefs.h"
#import "FixSearchDialog.h"
#import "MASShortcut.h"
#import "MASShortcutView+UserDefaults.h"
#import "MASShortcut+UserDefaults.h"
#import "MASShortcut+Monitoring.h"
#import "HotKeyConstants.h"

@implementation MAL_Updater_OS_XAppDelegate

@synthesize window;
@synthesize historywindow;
@synthesize updatepanel;
@synthesize fsdialog;
/*
 
 Initalization
 
 */
/**
 Returns the support directory for the application, used to store the Core Data
 store file.  This code uses a directory named "MAL Updater OS X" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
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
        NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
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
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
												  configuration:nil 
															URL:url 
														options:nil 
														  error:&error]){
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
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
	
    return managedObjectContext;
}
+ (void)initialize
{
	//Create a Dictionary
	NSMutableDictionary * defaultValues = [NSMutableDictionary dictionary];
	
	// Defaults
	[defaultValues setObject:@"" forKey:@"Base64Token"];
	[defaultValues setObject:@"https://malapi.ateliershiori.moe" forKey:@"MALAPIURL"];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"ScrobbleatStartup"];
    [defaultValues setObject:[[NSMutableArray alloc] init] forKey:@"searchcache"];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"useSearchCache"];
    [defaultValues setObject:[[NSMutableArray alloc] init] forKey:@"exceptions"];
    [defaultValues setObject:[[NSMutableArray alloc] init] forKey:@"ignoredirectories"];
    [defaultValues setObject:[[NSMutableArray alloc] init] forKey:@"IgnoreTitleRules"];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"ConfirmNewTitle"];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"ConfirmUpdates"];
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9){
        //Yosemite Specific Advanced Options
        [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"DisableYosemiteTitleBar"];
        [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"DisableYosemiteVibrance"];
    }
	//Register Dictionary
	[[NSUserDefaults standardUserDefaults]
	 registerDefaults:defaultValues];
	
}
- (void) awakeFromNib{
    
    //Create the NSStatusBar and set its length
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    
    //Used to detect where our files are
    NSBundle *bundle = [NSBundle mainBundle];
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    statusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"StatusIcon" ofType:@"tiff"]];
	
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

	//Sort Date Column by default
	NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc]
										 initWithKey: @"Date" ascending: NO];
	[historytable setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Initialize MALEngine
	MALEngine = [[MyAnimeList alloc] init];
	// Insert code here to initialize your application
	//Check if Application is in the /Applications Folder
	PFMoveToApplicationsFolderIfNecessary();
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
        
    }
    // Fix template images
    // There is a bug where template images are not made even if they are set in XCAssets
    NSArray *images = [NSArray arrayWithObjects:@"update", @"history", @"correct", nil];
    NSImage * image;
    for (NSString *imagename in images){
        image = [NSImage imageNamed:imagename];
        [image setTemplate:YES];
    }
	
	// Notify User if there is no Account Info
	if (![self checktoken]) {
        // First time prompt
        NSAlert * alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:@"Welcome to MAL Updater OS X"];
        [alert setInformativeText:@"Before using this program, you need to login. Do you want to open Preferences to log in now?"];
        // Set Message type to Warning
        [alert setAlertStyle:NSInformationalAlertStyle];
        if ([alert runModal]== NSAlertFirstButtonReturn) {
            [NSApp activateIgnoringOtherApps:YES];
            [self.preferencesWindowController showWindow:nil];
        }
	}
    if ([self checkoldAPI]) {
        [self showNotication:@"MAL Updater OS X" message:@"The API URL has been automatically updated."];
        [[NSUserDefaults standardUserDefaults] setObject:@"https://malapi.ateliershiori.moe" forKey:@"MALAPIURL"];
    }
	// Autostart Scrobble at Startup
	if ([defaults boolForKey:@"ScrobbleatStartup"] == 1) {
		[self autostarttimer];
	}
}
/*
 
 General UI Functions
 
 */
- (NSWindowController *)preferencesWindowController
{
    if (_preferencesWindowController == nil)
    {
		NSLog(@"Load Pref");
        NSViewController *generalViewController = [[GeneralPrefController alloc] init];
        NSViewController *loginViewController = [[LoginPref alloc] initwithAppDelegate:self];
		NSViewController *suViewController = [[SoftwareUpdatesPref alloc] init];
        NSViewController *exceptionsViewController = [[ExceptionsPref alloc] init];
        NSViewController *hotkeyViewController = [[HotkeysPrefs alloc] init];
        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, loginViewController, hotkeyViewController, exceptionsViewController, suViewController, nil];
        
        // To add a flexible space between General and Advanced preference panes insert [NSNull null]:
        //     NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, [NSNull null], advancedViewController, nil];
        
            _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers];
    }
    return _preferencesWindowController;
}

-(void)showPreferences:(id)sender
{
	//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
	[NSApp activateIgnoringOtherApps:YES];
	[self.preferencesWindowController showWindow:nil];
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	
    if (!managedObjectContext) return NSTerminateNow;
	
    if (![managedObjectContext commitEditing]) {
        NSLog(@"%@:%s unable to commit editing to terminate", [self class], _cmd);
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
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
		
    }
	
    return NSTerminateNow;
}
-(IBAction)togglescrobblewindow:(id)sender
{
	if ([window isVisible]) {
		[window close];
	} else { 
		//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
		[NSApp activateIgnoringOtherApps:YES];
		[window makeKeyAndOrderFront:self]; 
	} 
}
/*
 
 Timer Functions
 
 */

- (IBAction)toggletimer:(id)sender {
	//Check to see if there is an API Key stored
	if (![self checktoken]) {
        [self showNotication:@"MAL Updater OS X" message:@"Add a login before you start scrobbling."];
	}
	else {
		if (scrobbling == FALSE) {
			[self starttimer];
			[togglescrobbler setTitle:@"Stop Scrobbling"];
            [self showNotication:@"MAL Updater OS X" message:@"Auto Scrobble is now turned on."];
			[ScrobblerStatus setObjectValue:@"Scrobble Status: Started"];
			//Set Scrobbling State to true
			scrobbling = TRUE;
		}
		else {
			[self stoptimer];
			[togglescrobbler setTitle:@"Start Scrobbling"];
			[ScrobblerStatus setObjectValue:@"Scrobble Status: Stopped"];
            [self showNotication:@"MAL Updater OS X" message:@"Auto Scrobble is now turned off."];
			//Set Scrobbling State to false
			scrobbling = FALSE;
		}
	}
	
}
-(void)autostarttimer {
	//Check to see if there is an API Key stored
	if (![self checktoken]) {
         [self showNotication:@"MAL Updater OS X" message:@"Add a login before you start scrobbling."];
	}
	else {
		[self starttimer];
		[togglescrobbler setTitle:@"Stop Scrobbling"];
		[ScrobblerStatus setObjectValue:@"Scrobble Status: Started"];
        //Set Scrobbling State to true
		scrobbling = TRUE;
	}
}
-(void)firetimer:(NSTimer *)aTimer {
	//Tell MALEngine to detect and scrobble if necessary.
	NSLog(@"Starting...");
    if (!scrobbleractive) {
        scrobbleractive = true;
        // Disable toggle scrobbler and update now menu items
        [statusMenu setAutoenablesItems:NO];
        [updatenow setEnabled:NO];
        [togglescrobbler setEnabled:NO];
		[confirmupdate setEnabled:NO];
        [updatenow setTitle:@"Updating..."];
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        [self setStatusText:@"Scrobble Status: Scrobbling..."];
        int status;
        status = [MALEngine startscrobbling];
	//Enable the Update button if a title is detected
        switch (status) { // 0 - nothing playing; 1 - same episode playing; 21 - Add Title Successful; 22 - Update Title Successful;  51 - Can't find Title; 52 - Add Failed; 53 - Update Failed; 54 - Scrobble Failed; 
            case 0:
                [self setStatusText:@"Scrobble Status: Idle..."];
                break;
            case 1:
                [self setStatusText:@"Scrobble Status: Same Episode Playing, Scrobble not needed."];
                break;
            case 2:
                [self setStatusText:@"Scrobble Status: No update needed."];
                break;
            case 3:{
                [self setStatusText:@"Scrobble Status: Please confirm update."];
                NSDictionary * userinfo = [[NSDictionary alloc] initWithObjectsAndKeys:[MALEngine getLastScrobbledTitle], @"title",  [MALEngine getLastScrobbledEpisode], @"episode", nil];
                [self showConfirmationNotication:@"Confirm Update" message:[NSString stringWithFormat:@"Click here to confirm update for %@ Episode %@.",[MALEngine getLastScrobbledActualTitle],[MALEngine getLastScrobbledEpisode]] updateData:userinfo];
                break;
            }
            case 21:
            case 22:
                [self setStatusText:@"Scrobble Status: Scrobble Successful..."];
                [self showNotication:@"Scrobble Successful."message:[NSString stringWithFormat:@"%@ - %@",[MALEngine getLastScrobbledActualTitle],[MALEngine getLastScrobbledEpisode]]];
                //Add History Record
                [self addrecord:[MALEngine getLastScrobbledActualTitle] Episode:[MALEngine getLastScrobbledEpisode] Date:[NSDate date]];
                break;
            case 51:
                [self setStatusText:@"Scrobble Status: Can't find title. Retrying in 5 mins..."];
                [self showNotication:@"Scrobble Unsuccessful." message:@"Can't find title."];
                break;
            case 52:
            case 53:
                [self showNotication:@"Scrobble Unsuccessful." message:@"Retrying in 5 mins..."];
                [self setStatusText:@"Scrobble Status: Scrobble Failed. Retrying in 5 mins..."];
                break;
            case 54:
                [self showNotication:@"Scrobble Unsuccessful." message:@"Check user credentials in Preferences. You may need to login again."];
                [self setStatusText:@"Scrobble Status: Scrobble Failed. User credentials might have expired."];
                break;
            case 55:
                [self setStatusText:@"Scrobble Status: No internet connection."];
                break;
            default:
                break;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([MALEngine getSuccess] == 1) {

                [self setStatusMenuTitleEpisode:[MALEngine getLastScrobbledActualTitle] episode:[MALEngine getLastScrobbledEpisode]];
                if (status != 3 && [MALEngine getConfirmed]){
                    // Show normal info
                    [self updateLastScrobbledTitleStatus:false];
                    //Enable Update Status functions
                    [updatetoolbaritem setEnabled:YES];
                    [updatedupdatestatus setEnabled:YES];
                    [confirmupdate setHidden:YES];
                }
                else{
                    // Show that user needs to confirm update
                    [self updateLastScrobbledTitleStatus:true];
                        [confirmupdate setHidden:NO];
                    if ([MALEngine getisNewTitle]) {
                        // Disable Update Status functions for new and unconfirmed titles.
                        [updatecorrect setAutoenablesItems:NO];
                        [updatetoolbaritem setEnabled:NO];
                        [updatedupdatestatus setEnabled:NO];
                    }
                }
                [sharetoolbaritem setEnabled:YES];
                [correcttoolbaritem setEnabled:YES];
                //Show Last Scrobbled Title and operations */
                [seperator setHidden:NO];
                [lastupdateheader setHidden:NO];
                [updatedtitle setHidden:NO];
                [updatedepisode setHidden:NO];
                [seperator2 setHidden:NO];
                [updatecorrectmenu setHidden:NO];
                [updatedcorrecttitle setHidden:NO];
                [shareMenuItem setHidden:NO];
                NSDictionary * ainfo = [MALEngine getLastScrobbledInfo];
                if (ainfo !=nil) { // Checks if MAL Updater OS X already populated info about the just updated title.
                    [self showAnimeInfo:ainfo];
                    [self generateShareMenu];
                }
            }
            // Enable Menu Items
            scrobbleractive = false;
            [updatenow setEnabled:YES];
            [togglescrobbler setEnabled:YES];
            [statusMenu setAutoenablesItems:YES];
            [confirmupdate setEnabled:YES];
            [updatenow setTitle:@"Update Now"];
	});
    });
    
    }
}
-(void)starttimer {
    NSLog(@"Timer Started.");
    timer = [NSTimer scheduledTimerWithTimeInterval:300
                                             target:self
                                           selector:@selector(firetimer:)
                                           userInfo:nil
                                            repeats:YES];
    if (previousfiredate != nil) {
        NSLog(@"Resuming Timer");
        float pauseTime = -1*[pausestart timeIntervalSinceNow];
        [timer setFireDate:[previousfiredate initWithTimeInterval:pauseTime sinceDate:previousfiredate]];
        pausestart = nil;
        previousfiredate = nil;
    }
    
}
-(void)stoptimer {
    NSLog(@"Pausing Timer.");
    //Stop Timer
    [timer invalidate];
    //Set Previous Fire and Pause Times
    pausestart = [NSDate date];
    previousfiredate = [timer fireDate];
}

-(IBAction)updatenow:(id)sender{
    if (![self checktoken])
        [self showNotication:@"MAL Updater OS X" message:@"Add a login before you start scrobbling."];
    else
        [self firetimer:nil];
}
-(IBAction)getHelp:(id)sender{
    //Show Help
 	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/malupdaterosx-cocoa/wiki/Getting-Started"]];
}
-(void)showAnimeInfo:(NSDictionary *)d{
    //Empty
    [animeinfo setString:@""];
    //Description
    NSString * anidescription = [d objectForKey:@"synopsis"];
    anidescription = [anidescription stripHtml]; //Removes HTML tags
    [self appendToAnimeInfo:@"Description"];
    [self appendToAnimeInfo:anidescription];
    //Meta Information
    [self appendToAnimeInfo:@""];
    [self appendToAnimeInfo:@"Other Information"];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Classification: %@", [d objectForKey:@"classification"]]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Start Date: %@", [d objectForKey:@"start_date"]]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Airing Status: %@", [d objectForKey:@"status"]]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Episodes: %@", [d objectForKey:@"episodes"]]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Popularity: %@", [d objectForKey:@"popularity_rank"]]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Favorited: %@", [d objectForKey:@"favorited_count"]]];
    //Image
    NSImage * dimg = [[NSImage alloc]initByReferencingURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", [d objectForKey:@"image_url"]]]]; //Downloads Image
    [img setImage:dimg]; //Get the Image for the title
    // Clear Anime Info so that MAL Updater OS X won't attempt to retrieve it if the same episode and title is playing
    [MALEngine clearAnimeInfo];
}
-(BOOL)checktoken{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults objectForKey:@"Base64Token"] length] == 0) {
        return false;
    }
    else
        return true;
}
-(IBAction)showCorrectionSearchWindow:(id)sender{
    bool isVisible = [window isVisible];
    // Stop Timer temporarily if scrobbling is turned on
    if (scrobbling == TRUE) {
        [self stoptimer];
    }
    fsdialog = [FixSearchDialog new];
    // Check if Confirm is on for new title. If so, then disable ability to delete title.
    if (!confirmupdate.hidden && [MALEngine getisNewTitle])
        [fsdialog setCorrection:NO];
    else
        [fsdialog setCorrection:YES];
    [fsdialog setSearchField:[MALEngine getLastScrobbledTitle]];
    if (isVisible) {
        [NSApp beginSheet:[fsdialog window]
           modalForWindow:window modalDelegate:self
           didEndSelector:@selector(correctionDidEnd:returnCode:contextInfo:)
              contextInfo:(void *)nil];
        [self disableUpdateItems];
    }
    else{
        [NSApp beginSheet:[fsdialog window]
           modalForWindow:nil modalDelegate:self
           didEndSelector:@selector(correctionDidEnd:returnCode:contextInfo:)
              contextInfo:(void *)nil];
    }
    
}
-(void)correctionDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1) {
        if ([[fsdialog getSelectedAniID] isEqualToString:[MALEngine getAniID]]) {
            NSLog(@"ID matches, correction not needed.");
        }
        else{
            [self addtoExceptions:[MALEngine getLastScrobbledTitle] newtitle:[fsdialog getSelectedTitle] showid:[fsdialog getSelectedAniID]];
            if([fsdialog getdeleteTitleonCorrection]){
                if([MALEngine removetitle:[MALEngine getAniID]]){
                    NSLog(@"Removal Successful");
                }
            }
            NSLog(@"Updating corrected title...");
            int status = [MALEngine scrobbleagain:[MALEngine getLastScrobbledTitle] Episode:[MALEngine getLastScrobbledEpisode]];
            switch (status) {
                case 1:
                case 21:
                case 22:{
                    [self setStatusText:@"Scrobble Status: Correction Successful..."];
                    [self showNotication:@"MAL Updater OS X" message:@"Correction was successful"];
                    [self setStatusMenuTitleEpisode:[MALEngine getLastScrobbledActualTitle] episode:[MALEngine getLastScrobbledEpisode]];
                    [self updateLastScrobbledTitleStatus:false];
                    //Show Anime Correct Information
                    NSDictionary * ainfo = [MALEngine getLastScrobbledInfo];
                    [self showAnimeInfo:ainfo];
					[confirmupdate setHidden:true];
                    break;
                }
                default:
                    [self setStatusText:@"Scrobble Status: Correction unsuccessful..."];
                    [self showNotication:@"MAL Updater OS X" message:@"Correction was not successful."];
                    break;
            }
        }
    }
    else{
        NSLog(@"Cancel");
    }
    fsdialog = nil;
    [self enableUpdateItems];
    //Restart Timer
    if (scrobbling == TRUE) {
        [self starttimer];
    }
}
-(void)addtoExceptions:(NSString *)detectedtitle newtitle:(NSString *)title showid:(NSString *)showid{
    //Adds correct title and ID to exceptions list
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *exceptions = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"exceptions"]];
    //Prevent duplicate
    BOOL exists = false;
    for (NSDictionary * d in exceptions){
        NSString * dt = [d objectForKey:@"detectedtitle"];
        if ([detectedtitle isEqualToString:dt]) {
            NSLog(@"Title exists on Exceptions List");
            exists = true;
            break;
        }
        else{
            exists = false;
        }
    }
    if (!exists) {
        NSDictionary * entry = [[NSDictionary alloc] initWithObjectsAndKeys:detectedtitle, @"detectedtitle", title ,@"correcttitle", showid, @"showid", nil];
        [exceptions addObject:entry];
        [defaults setObject:exceptions forKey:@"exceptions"];
    }
    //Check if the title exists in the cache. If so, remove it
    NSMutableArray *cache = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"searchcache"]];
    if (cache.count > 0) {
        for (int i=0; i<[cache count]; i++) {
            NSDictionary * d = [cache objectAtIndex:i];
            NSString * title = [d objectForKey:@"detectedtitle"];
            if ([title isEqualToString:detectedtitle]) {
                NSLog(@"%@ found in cache, remove!", title);
                [cache removeObject:d];
                [[NSUserDefaults standardUserDefaults] setObject:cache forKey:@"searchcache"];
                break;
            }
        }
    }
}
/*
 
 Scrobble History Window
 
 */

-(IBAction)showhistory:(id)sender
{
		//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
		[NSApp activateIgnoringOtherApps:YES];
		[historywindow makeKeyAndOrderFront:nil];

}
-(void)addrecord:(NSString *)title
		 Episode:(NSString *)episode
			Date:(NSDate *)date;
{
// Add scrobble history record to the SQLite Database via Core Data
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSManagedObject *obj = [NSEntityDescription 
							insertNewObjectForEntityForName :@"History" 
							inManagedObjectContext: moc];
	// Set values in the new record
	[obj setValue:title forKey:@"Title"];
	[obj setValue:episode forKey:@"Episode"];
	[obj setValue:date forKey:@"Date"];

}
-(IBAction)clearhistory:(id)sender
{
	// Set Up Prompt Message Window
	NSAlert * alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Yes"];
	[alert addButtonWithTitle:@"No"];
	[alert setMessageText:@"Are you sure you want to clear the Scrobble History?"];
	[alert setInformativeText:@"Once done, this action cannot be undone."];
	// Set Message type to Warning
	[alert setAlertStyle:NSWarningAlertStyle];
	// Show as Sheet on historywindow
	[alert beginSheetModalForWindow:historywindow 
					  modalDelegate:self
					 didEndSelector:@selector(clearhistoryended:code:conext:)
						contextInfo:NULL];

}
-(void)clearhistoryended:(NSAlert *)alert
					code:(int)echoice
				  conext:(void *)v
{
	if (echoice == 1000) {
		// Remove All Data
		NSManagedObjectContext *moc = [self managedObjectContext];
		NSFetchRequest * allHistory = [[NSFetchRequest alloc] init];
		[allHistory setEntity:[NSEntityDescription entityForName:@"History" inManagedObjectContext:moc]];
		
		NSError * error = nil;
		NSArray * histories = [moc executeFetchRequest:allHistory error:&error];
		//error handling goes here
		for (NSManagedObject * history in histories) {
			[moc deleteObject:history];
		}
	}
	
}	

/*
 
 StatusIconTooltip, Status Text, Last Scrobbled Title Setters
 
 */

-(void)setStatusToolTip:(NSString*)toolTip
{
    [statusItem setToolTip:toolTip];
}
-(void)setStatusText:(NSString*)messagetext
{
	[ScrobblerStatus setObjectValue:messagetext];
}
-(void)setLastScrobbledTitle:(NSString*)messagetext
{
	[LastScrobbled setObjectValue:messagetext];
}
-(void)setStatusMenuTitleEpisode:(NSString *)title episode:(NSString *) episode{
    //Set New Title and Episode
    [updatedtitle setTitle:title];
    [updatedepisode setTitle:[NSString stringWithFormat:@"Episode %@", episode]];
}
-(void)updateLastScrobbledTitleStatus:(BOOL)pending{
    if (pending) {
        [updatecorrect setAutoenablesItems:NO];
        [lastupdateheader setTitle:@"Pending:"];
        [self setLastScrobbledTitle:[NSString stringWithFormat:@"Pending: %@ - Episode %@",[MALEngine getLastScrobbledTitle],[MALEngine getLastScrobbledEpisode]]];
        [self setStatusToolTip:[NSString stringWithFormat:@"MAL Updater OS X - %@ - %@ (Pending)",[MALEngine getLastScrobbledActualTitle],[MALEngine getLastScrobbledEpisode]]];
    }
    else{
        [updatecorrect setAutoenablesItems:YES];
        [lastupdateheader setTitle:@"Last Scrobbled:"];
        [self setLastScrobbledTitle:[NSString stringWithFormat:@"Last Scrobbled: %@ - Episode %@",[MALEngine getLastScrobbledTitle],[MALEngine getLastScrobbledEpisode]]];
        [self setStatusToolTip:[NSString stringWithFormat:@"MAL Updater OS X - %@ - %@",[MALEngine getLastScrobbledActualTitle],[MALEngine getLastScrobbledEpisode]]];
    }
}

/*
 
Getters
 
 */
-(bool)getisScrobbling{
    return scrobbling;
}
-(bool)getisScrobblingActive{
    return scrobbleractive;
}
/*
 
 Update Status Sheet Window Functions
 
 */
-(IBAction)updatestatus:(id)sender {
    [self showUpdateDialog:[self window]];
    [self disableUpdateItems];
}
-(IBAction)updatestatusmenu:(id)sender{
    [self showUpdateDialog:nil];
}
-(void)showUpdateDialog:(NSWindow *) w{
	// Show Sheet
	[NSApp beginSheet:updatepanel
	   modalForWindow:w modalDelegate:self
	   didEndSelector:@selector(myPanelDidEnd:returnCode:contextInfo:)
		  contextInfo:(void *)[NSNumber numberWithFloat:choice]];
	// Set up UI
	[showtitle setObjectValue:[MALEngine getLastScrobbledTitle]];
	[showscore selectItemWithTag:[MALEngine getScore]];
	[showstatus selectItemAtIndex:[MALEngine getWatchStatus]];
	// Stop Timer temporarily if scrobbling is turned on
	if (scrobbling == TRUE) {
		[self stoptimer];
	}
	
}
- (void)myPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1) {
        BOOL result = [MALEngine updatestatus:[MALEngine getAniID] score:[showscore selectedTag] watchstatus:[showstatus titleOfSelectedItem]];
        if (result)
            [self setStatusText:@"Scrobble Status: Updating of Watch Status/Score Successful."];
        else
            [self setStatusText:@"Scrobble Status: Unable to update Watch Status/Score."];
    }
    //If scrobbling is on, restart timer
	if (scrobbling == TRUE) {
		[self starttimer];
	}
    [self enableUpdateItems];
}

-(IBAction)closeupdatestatus:(id)sender {
	[updatepanel orderOut:self];
	[NSApp endSheet:updatepanel returnCode:0];
}
-(IBAction)updatetitlestatus:(id)sender {
	[updatepanel orderOut:self];
	[NSApp endSheet:updatepanel returnCode:1];
}

//Misc Methods
- (void)appendToAnimeInfo:(NSString*)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ \n", text]];
        
        [[animeinfo textStorage] appendAttributedString:attr];
    });
}
-(void)showNotication:(NSString *)title message:(NSString *) message{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    notification.soundName = nil;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}
-(void)showConfirmationNotication:(NSString *)title message:(NSString *) message updateData:(NSDictionary *)d{
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
        NSString * title = [notification.userInfo objectForKey:@"title"];
        NSString * episode = [notification.userInfo objectForKey:@"episode"];
        // Only confirm update if the title and episode is the same with the last scrobbled.
        if ([[MALEngine getLastScrobbledTitle] isEqualToString:title] && [episode intValue] == [[MALEngine getLastScrobbledEpisode] intValue]) {
            //Confirm Update
            [self confirmupdate];
        }
        else{
            return;
        }
    }
}
-(IBAction)confirmupdate:(id)sender{
    [self confirmupdate];
}
-(void)confirmupdate{
    BOOL success = [MALEngine confirmupdate];
    if (success) {
        [self updateLastScrobbledTitleStatus:false];
        [self addrecord:[MALEngine getLastScrobbledActualTitle] Episode:[MALEngine getLastScrobbledEpisode] Date:[NSDate date]];
        [confirmupdate setHidden:YES];
        [self setStatusText:@"Scrobble Status: Update was successful."];
        [self showNotication:@"MAL Updater OS X" message:[NSString stringWithFormat:@"%@ Episode %@ has been updated.",[MALEngine getLastScrobbledActualTitle],[MALEngine getLastScrobbledEpisode]]];
        if ([MALEngine getisNewTitle]) {
            // Enable Update Status functions for new and unconfirmed titles.
            [confirmupdate setHidden:YES];
            [updatedupdatestatus setEnabled:YES];
        }
    }
    else{
        [self showNotication:@"MAL Updater OS X" message:@"Failed to confirm update. Please try again later."];
        [self setStatusText:@"Unable to confirm update."];
    }
}
-(IBAction)showAboutWindow:(id)sender{
    // Properly show the about window in a menu item application
    [NSApp activateIgnoringOtherApps:YES];
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:self];
}
-(void)disableUpdateItems{
    // Disables update options to prevent erorrs
    panelactive = true;
    [statusMenu setAutoenablesItems:NO];
    [updatecorrect setAutoenablesItems:NO];
    [updatenow setEnabled:NO];
    [togglescrobbler setEnabled:NO];
    [updatedcorrecttitle setEnabled:NO];
    [updatedupdatestatus setEnabled:NO];
    [confirmupdate setEnabled:NO];
}
-(void)enableUpdateItems{
    // Reenables update options
    panelactive = false;
    [updatenow setEnabled:YES];
    [togglescrobbler setEnabled:YES];
    [updatedcorrecttitle setEnabled:YES];
    if (confirmupdate.hidden) {
        [updatedupdatestatus setEnabled:YES];
    }
    [updatecorrect setAutoenablesItems:YES];
    [statusMenu setAutoenablesItems:YES];
    [confirmupdate setEnabled:YES];
}
-(void)registerHotkey{
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceScrobbleNowShortcut handler:^{
        // Scrobble Now Global Hotkey
        if ([self checktoken] && !panelactive) {
            [self firetimer:nil];
        }
    }];
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceShowStatusMenuShortcut handler:^{
        // Status Window Toggle Global Hotkey
        [self togglescrobblewindow:nil];
    }];
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceToggleScrobblingShortcut handler:^{
        // Auto Scrobble Toggle Global Hotkey
        [self toggletimer:nil];
    }];
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceConfirmUpdateShortcut handler:^{
        // Confirm Update Hotkey
        if (!confirmupdate.hidden) {
            [self confirmupdate];
        }
    }];
}

-(BOOL)checkoldAPI{
    if ([[NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"MALAPIURL"]] isEqualToString:@"https://malapi.shioridiary.me"]||[[NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"MALAPIURL"]] isEqualToString:@"http://mal-api.com"]) {
        return true;
    }
    return false;
}
/*
 Share Services
 */
-(void)generateShareMenu{
    //Clear Share Menu
    [shareMenu removeAllItems];
    // Workaround for Share Toolbar Item
    NSMenuItem *shareIcon = [[NSMenuItem alloc] init];
    [shareIcon setImage:[NSImage imageNamed:NSImageNameShareTemplate]];
    [shareIcon setHidden:YES];
    [shareIcon setTitle:@""];
    [shareMenu addItem:shareIcon];
    //Generate Items to Share
    shareItems = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@ - %@", [MALEngine getLastScrobbledTitle], [MALEngine getLastScrobbledEpisode] ], [NSURL URLWithString:[NSString stringWithFormat:@"http://myanimelist.net/anime/%@", [MALEngine getAniID]]] ,nil];
    //Get Share Services for Items
    NSArray *shareServiceforItems = [NSSharingService sharingServicesForItems:shareItems];
    //Generate Share Items and populate Share Menu
    for (NSSharingService * cservice in shareServiceforItems){
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
@end
