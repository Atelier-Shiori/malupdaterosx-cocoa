//
//  MAL_Updater_OS_XAppDelegate.m
//  MAL Updater OS X
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2010 Chikorita157's Anime Blog. All rights reserved. Code licensed under New BSD License
//

#import "MAL_Updater_OS_XAppDelegate.h"
#import "PreferenceController.h"
#import "JSON/JSON.h"
#import "PFMoveApplication.h"

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
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
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
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
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
	[defaultValues setObject:@"http://mal-api.com/" forKey:@"MALAPIURL"];
	[defaultValues setObject:[NSNumber numberWithInt:0] forKey:@"PlayerSel"];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"ScrobbleatStartup"];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"EnableTwitterUpdates"];
	//Register Dictionary
	[[NSUserDefaults standardUserDefaults]
	 registerDefaults:defaultValues];
	
}
- (void) awakeFromNib{
    
    //Create the NSStatusBar and set its length
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
    
    //Used to detect where our files are
    NSBundle *bundle = [NSBundle mainBundle];
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    statusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"StatusIcon" ofType:@"tiff"]];
    statusHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"StatusIcon" ofType:@"tiff"]];
    
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
	NSSortDescriptor* sortDescriptor = [[[NSSortDescriptor alloc]
										 initWithKey: @"Date" ascending: NO] autorelease];
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
	//Register Growl
	NSBundle *myBundle = [NSBundle bundleForClass:[MAL_Updater_OS_XAppDelegate class]];
	NSString *growlPath = [[myBundle privateFrameworksPath] stringByAppendingPathComponent:@"Growl.framework"];
	NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
	if (growlBundle && [growlBundle load]) {
		// Register ourselves as a Growl delegate
		[GrowlApplicationBridge setGrowlDelegate:self];
	}
	else {
		NSLog(@"ERROR: Could not load Growl.framework");
	}
	// Disable Update Button
	[updatetoolbaritem setEnabled:NO];
	// Hide Window
	[window orderOut:self];
	
	// Notify User if there is no Account Info
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([[defaults objectForKey:@"Base64Token"] length] == 0) {
		//Notify the user that there is no login token.
		[GrowlApplicationBridge notifyWithTitle:@"MAL Updater OS X"
									description:@"No Auth Token Detected. \n\nBefore you can use this program, you need to verify your MAL Account. This can be done in Preferences."
							   notificationName:@"Message"
									   iconData:nil
									   priority:0
									   isSticky:NO
								   clickContext:[NSDate date]];
	}
	// Autostart Scrobble at Startup
	if ([defaults boolForKey:@"ScrobbleatStartup"] == 1) {
		[self autostarttimer];
	}
}
/*
 
 General UI Functions
 
 */

-(void)showPreferences:(id)sender
{
	//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
	[NSApp activateIgnoringOtherApps:YES];
	//Is preferenceController nil?
	if (!preferenceController) {
		preferenceController = [[PreferenceController alloc] init];
	}
	[preferenceController showWindow:self];
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
        [alert release];
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
		if (timer == nil) {
			//Create Timer
			timer = [[NSTimer scheduledTimerWithTimeInterval:300
													  target:self
													selector:@selector(firetimer:)
													userInfo:nil
													 repeats:YES] retain];
			[togglescrobbler setTitle:@"Stop Scrobbling"];
			[ScrobblerStatus setObjectValue:@"Scrobble Status: Started"];
			[GrowlApplicationBridge notifyWithTitle:@"MAL Updater OS X"
										description:@"Auto Scrobble is now turned on."
								   notificationName:@"Message"
										   iconData:nil
										   priority:0
										   isSticky:NO
									   clickContext:[NSDate date]];
		}
		else {
			//Stop Timer
			// Remove Timer
			[timer invalidate];
			[timer release];
			timer = nil;
			[togglescrobbler setTitle:@"Start Scrobbling"];
			[ScrobblerStatus setObjectValue:@"Scrobble Status: Stopped"];
			[GrowlApplicationBridge notifyWithTitle:@"MAL Updater OS X"
										description:@"Auto Scrobble is now turned off."
								   notificationName:@"Message"
										   iconData:nil
										   priority:0
										   isSticky:NO
									   clickContext:[NSDate date]];
		}
	}
	
}
-(void)autostarttimer {
	//Check to see if there is an API Key stored
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([[defaults objectForKey:@"Base64Token"] length] == 0) {
		[GrowlApplicationBridge notifyWithTitle:@"MAL Updater OS X"
									description:@"Unable to start scrobbling since there is no auth token. Please verify your login in Preferences."
							   notificationName:@"Message"
									   iconData:nil
									   priority:0
									   isSticky:NO
								   clickContext:[NSDate date]];
	}
	else {
		//Create Timer
		timer = [[NSTimer scheduledTimerWithTimeInterval:300
												  target:self
												selector:@selector(firetimer:)
												userInfo:nil
												 repeats:YES] retain];
		[togglescrobbler setTitle:@"Stop Scrobbling"];
		[ScrobblerStatus setObjectValue:@"Scrobble Status: Started"];
		[GrowlApplicationBridge notifyWithTitle:@"MAL Updater OS X"
									description:@"Auto Scrobble is now turned on."
							   notificationName:@"Message"
									   iconData:nil
									   priority:0
									   isSticky:NO
								   clickContext:[NSDate date]];
	}
}
- (void)firetimer:(NSTimer *)aTimer {
	//Tell MALEngine to detect and scrobble if necessary.
	NSLog(@"Starting...");
	[MALEngine startscrobbling];
	//Enable the Update button if a title is detected
	if ([MALEngine getAniID] > 0) {
		[updatetoolbaritem setEnabled:YES];
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

	// Release Managed Object
	[obj release];
}
-(IBAction)clearhistory:(id)sender
{
	// Set Up Prompt Message Window
	NSAlert * alert = [[[NSAlert alloc] init] autorelease];
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
		[allHistory release];
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
		  contextInfo:(void *)[[NSNumber numberWithFloat:choice] retain]];
	// Set up UI
	[showtitle setObjectValue:[MALEngine getLastScrobbledTitle]];
	[currentepisodes setObjectValue:[MALEngine getLastScrobbledEpisode]];
	[totalepisodes setObjectValue:[MALEngine getTotalEpisodes]];
	
}
- (void)myPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	float payload;
	if (returnCode == NSCancelButton) return;
	
	
	payload = [(NSNumber *)contextInfo floatValue];
	[(NSNumber *)contextInfo release];
}
-(IBAction)closeupdatestatus:(id)sender {
	[updatepanel orderOut:self];
	[NSApp endSheet:updatepanel returnCode:0];
}
-(IBAction)updatetitlestatus:(id)sender {
	[updatepanel orderOut:self];
	[NSApp endSheet:updatepanel returnCode:1];
}

/* 
 
 Dealloc
 
 */

- (void) dealloc {
    //Deallocate all active objects
    [statusImage release];
    [statusHighlightImage release];
	[managedObjectContext release];
    [persistentStoreCoordinator release];
    [managedObjectModel release];
	[window release];
	[historywindow release];
    [MALEngine release];
	if (!preferenceController) {
	}
	else {
		[preferenceController release];
	}
	
    [super dealloc];
}
@end
