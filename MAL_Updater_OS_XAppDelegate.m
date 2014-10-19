//
//  MAL_Updater_OS_XAppDelegate.m
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2010 Chikorita157's Anime Blog. All rights reserved. Code licensed under New BSD License
//

#import "MAL_Updater_OS_XAppDelegate.h"
//#import "PreferenceController.h"
#import "JSON/JSON.h"
#import "PFMoveApplication.h"
#import "GeneralPrefController.h"
#import "MASPreferencesWindowController.h"
#import "LoginPref.h"
#import "Video.h"
#import "SoftwareUpdatesPref.h"
#import "NSString_stripHtml.h"


@implementation MAL_Updater_OS_XAppDelegate

@synthesize window;
@synthesize historywindow;
@synthesize updatepanel;
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
	[defaultValues setObject:@"https://malapi.shioridiary.me" forKey:@"MALAPIURL"];
	[defaultValues setObject:[NSNumber numberWithInt:0] forKey:@"PlayerSel"];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"ScrobbleatStartup"];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"EnableTwitterUpdates"];
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
    statusHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"StatusIconhilight" ofType:@"tiff"]];
    
    //Yosemite Dark Menu Support
    BOOL oldBusted = (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9);
    if (!oldBusted)
    {
        // 10.10 or higher, so setTemplate: is safe
        [statusImage setTemplate:YES];
        [statusHighlightImage setTemplate:YES];
    }
    
    //Sets the images in our NSStatusItem
    [statusItem setImage:statusImage];
    [statusItem setAlternateImage:statusHighlightImage];
    
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
	// Check for Crash Reports
	[CMCrashReporter check];
	// Insert code here to initialize your application
	//Check if Application is in the /Applications Folder
	PFMoveToApplicationsFolderIfNecessary();
	//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
	[NSApp activateIgnoringOtherApps:YES];
    //Set Notification Center Delegate
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
	// Disable Update Button
	[updatetoolbaritem setEnabled:NO];
	// Hide Window
	[window orderOut:self];
	
	// Notify User if there is no Account Info
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([[defaults objectForKey:@"Base64Token"] length] == 0) {
		//Notify the user that there is no login token.
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"MAL Updater OS X";
        notification.informativeText = @"Add your login infomation in Preferences before using this program.";
        notification.soundName = NSUserNotificationDefaultSoundName;
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
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
        NSViewController *loginViewController = [[LoginPref alloc] init];
		NSViewController *videoViewController = [[Video alloc] init];
		NSViewController *suViewController = [[SoftwareUpdatesPref alloc] init];
        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, loginViewController, videoViewController, suViewController, nil];
        
        // To add a flexible space between General and Advanced preference panes insert [NSNull null]:
        //     NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, [NSNull null], advancedViewController, nil];
        
        NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
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
		[window orderOut:self]; 
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
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([[defaults objectForKey:@"Base64Token"] length] == 0) {
		choice = NSRunCriticalAlertPanel(@"MAL Updater OS X was unable to start scrobbling since you have no auth token stored.", @"Verify and save your login in Preferences and then try again.", @"OK", nil, nil, 8);
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
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([[defaults objectForKey:@"Base64Token"] length] == 0) {
         [self showNotication:@"MAL Updater OS X" message:@"Unable to start scrobbling since there is no login. Please verify your login in Preferences."];
	}
	else {
		[self starttimer];
		[togglescrobbler setTitle:@"Stop Scrobbling"];
		[ScrobblerStatus setObjectValue:@"Scrobble Status: Started"];
        [self showNotication:@"MAL Updater OS X" message:@"Auto Scrobble is now turned on."];
		//Set Scrobbling State to true
		scrobbling = TRUE;
	}
}
-(void)firetimer:(NSTimer *)aTimer {
	//Tell MALEngine to detect and scrobble if necessary.
	NSLog(@"Starting...");
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        [MALEngine startscrobbling];
	//Enable the Update button if a title is detected
	if ([MALEngine getAniID] > 0) {
		[updatetoolbaritem setEnabled:YES];
        //Show Anime Information
        NSDictionary * ainfo = [MALEngine getLastScrobbledInfo];
        [self showAnimeInfo:ainfo];
        
	}});
}
-(void)starttimer {
	NSLog(@"Timer Started.");
	//Create Timer
	timer = [NSTimer scheduledTimerWithTimeInterval:30//300
											  target:self
											selector:@selector(firetimer:)
											userInfo:nil
											 repeats:YES];
}
-(void)stoptimer {
	NSLog(@"Timer Stopped.");
	//Stop Timer
	// Remove Timer
	[timer invalidate];
	timer = nil;
}
-(IBAction)getHelp:(id)sender{
    //Show Help
 	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/malupdaterosx-cocoa/wiki/Getting-Started"]];
}
-(void)showAnimeInfo:(NSDictionary *)d{
    NSLog(@"Adding");
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
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Start Date: %@", [d objectForKey:@"start_date"]]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Airing Status: %@", [d objectForKey:@"status"]]];
    int ep = [d objectForKey:@"episodes"];
    if(ep==0) {[self appendToAnimeInfo:[NSString stringWithFormat:@"Episodes: Ongoing"]];} else {[self appendToAnimeInfo:[NSString stringWithFormat:@"Episodes: %i", ep]];}
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Popularity: %@", [d objectForKey:@"popularity_rank"]]];
    //Image
    NSImage * dimg = [[NSImage alloc]initByReferencingURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", [d objectForKey:@"image_url"]]]]; //Downloads Image
    [img setImage:dimg]; //Sets it
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

/*
 
 Update Status Sheet Window Functions
 
 */

-(IBAction)updatestatus:(id)sender {
	// Show Sheet
	[NSApp beginSheet:updatepanel
	   modalForWindow:[self window] modalDelegate:self
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
- (void)myPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	float payload;
switch (returnCode) {
	case 0:
		break;
	case 1:
		[MALEngine updatestatus:[MALEngine getAniID] score:[showscore selectedTag] watchstatus:[showstatus titleOfSelectedItem]];
		break;
	default:
		break;
}
    //If scrobbling is on, restart timer
	if (scrobbling == TRUE) {
		[self starttimer];
	}
	
	payload = [(__bridge NSNumber *)contextInfo floatValue];
	(__bridge NSNumber *)contextInfo;
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
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}
@end
