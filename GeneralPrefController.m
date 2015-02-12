//
//  GeneralPrefController.m
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved.
//

#import "GeneralPrefController.h"
#import "EasyNSURLConnection.h"
#import "MAL_Updater_OS_XAppDelegate.h"
#import "AutoExceptions.h"
#import "Utility.h"


@implementation GeneralPrefController
- (id)init
{
	return [super initWithNibName:@"GeneralPreferenceView" bundle:nil];
}
#pragma mark Launch at Startup
// Launch at Startup Functions - http://bdunagan.com/2010/09/25/cocoa-tip-enabling-launch-on-startup/ - MIT License
- (BOOL)isLaunchAtStartup {
    // See if the app is currently in LoginItems.
    LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
    // Store away that boolean.
    BOOL isInList = itemRef != nil;
    // Release the reference if it exists.
    if (itemRef != nil) CFRelease(itemRef);
    
    return isInList;
}

- (IBAction)toggleLaunchAtStartup:(id)sender {
    // Toggle the state.
    BOOL shouldBeToggled = ![self isLaunchAtStartup];
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return;
    if (shouldBeToggled) {
        // Add the app to the LoginItems list.
        CFURLRef appUrl = (CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, appUrl, NULL, NULL);
        if (itemRef) CFRelease(itemRef);
    }
    else {
        // Remove the app from the LoginItems list.
        LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
        LSSharedFileListItemRemove(loginItemsRef,itemRef);
        if (itemRef != nil) CFRelease(itemRef);
    }
    CFRelease(loginItemsRef);
}

- (LSSharedFileListItemRef)itemRefInLoginItems {
    LSSharedFileListItemRef itemRef = nil;
    NSURL *itemUrl = nil;
    
    // Get the app's URL.
    NSURL *appUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return nil;
    // Iterate over the LoginItems.
    NSArray *loginItems = (NSArray *)LSSharedFileListCopySnapshot(loginItemsRef, nil);
    for (int currentIndex = 0; currentIndex < [loginItems count]; currentIndex++) {
        // Get the current LoginItem and resolve its URL.
        LSSharedFileListItemRef currentItemRef = (LSSharedFileListItemRef) loginItems[(NSUInteger) currentIndex];
        if (LSSharedFileListItemResolve(currentItemRef, 0, (CFURLRef *) &itemUrl, NULL) == noErr) {
            // Compare the URLs for the current LoginItem and the app.
            if ([itemUrl isEqual:appUrl]) {
                // Save the LoginItem reference.
                itemRef = currentItemRef;
            }
        }
    }
    // Retain the LoginItem reference.
    if (itemRef != nil) CFRetain(itemRef);
    // Release the LoginItems lists.
    [loginItems release];
    CFRelease(loginItemsRef);
    
    return itemRef;
}


#pragma mark -
#pragma mark MASPreferencesViewController
-(void)loadView{
    [super loadView];
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9){
        // Disable Yosemite UI options
        [disablenewtitlebar setEnabled:NO];
        [disablevibarency setEnabled: NO];
    }
    [startatlogin setState:[self isLaunchAtStartup]]; // Set Launch at Startup State
}
- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
}
#pragma mark General Preferences Functions
-(IBAction)testapi:(id)sender
{
	//Load API URL
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Set URL
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/animelist/chikorita157", [defaults objectForKey:@"MALAPIURL"]]];
	EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
	//Ignore Cookies
	[request setUseCookies:NO];
	//Test API
	[request startRequest];
	// Get Status Code
	long statusCode = [request getStatusCode];
	switch (statusCode) {
		case 200:
            [Utility showsheetmessage:@"API Test Successful" explaination:[NSString stringWithFormat:@"HTTP Code: %li", statusCode] window: [[self view] window]];
			break;
		default:
			[Utility showsheetmessage:@"API Test Unsuccessful" explaination:[NSString stringWithFormat:@"HTTP Code: %li", statusCode] window:[[self view] window]];
			break;
	}
	//release
    [request release];
	
}
-(IBAction)resetapiurl:(id)sender
{
	//Reset Unofficial MAL API URL
	[APIUrl setStringValue:@"https://malapi.ateliershiori.moe"];
	// Generate API Key
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults] ;
	[defaults setObject:[APIUrl stringValue] forKey:@"MALAPIURL"];
	
}
-(IBAction)clearSearchCache:(id)sender{
    // Remove All cache data from Core Data Entity
    MAL_Updater_OS_XAppDelegate * delegate = (MAL_Updater_OS_XAppDelegate *)[[NSApplication sharedApplication] delegate];
    NSManagedObjectContext *moc = [delegate getObjectContext];
    NSFetchRequest * allCaches = [[NSFetchRequest alloc] init];
    [allCaches setEntity:[NSEntityDescription entityForName:@"Cache" inManagedObjectContext:moc]];
    
    NSError * error = nil;
    NSArray * caches = [moc executeFetchRequest:allCaches error:&error];
    //error handling goes here
    for (NSManagedObject * cachentry in caches) {
        [moc deleteObject:cachentry];
    }
    error = nil;
    [moc save:&error];
    [allCaches release];
}
-(IBAction)updateAutoExceptions:(id)sender{
    // Updates Auto Exceptions List
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        // In a queue, download latest Auto Exceptions JSON, disable button until done and show progress wheel
        dispatch_async(dispatch_get_main_queue(), ^{
            [updateexceptionsbtn setEnabled:NO];
            [updateexceptionschk setEnabled:NO];
            [indicator startAnimation:self];});
        [AutoExceptions updateAutoExceptions];
        dispatch_async(dispatch_get_main_queue(), ^{
            [indicator stopAnimation:self];
            [updateexceptionsbtn setEnabled:YES];
            [updateexceptionschk setEnabled:YES];
        });
        dispatch_release(queue);
    });
    
}
-(IBAction)disableAutoExceptions:(id)sender{
    if ([updateexceptionschk state]) {
        [self updateAutoExceptions:sender];
    }
    else{
    // Clears Exceptions if User chooses
    // Set Up Prompt Message Window
    NSAlert * alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    [alert setMessageText:@"Do you want to remove all Auto Exceptions Data?"];
    [alert setInformativeText:@"Since you are disabling Auto Exceptions, you can delete the Auto Exceptions Data. You will be able to download it again."];
    // Set Message type to Warning
    [alert setAlertStyle:NSWarningAlertStyle];
    if ([alert runModal]== NSAlertFirstButtonReturn) {
        // Remove All cache data from Auto Exceptions
        MAL_Updater_OS_XAppDelegate * delegate = (MAL_Updater_OS_XAppDelegate *)[[NSApplication sharedApplication] delegate];
        NSManagedObjectContext *moc = [delegate getObjectContext];
        NSFetchRequest * allExceptions = [[NSFetchRequest alloc] init];
        [allExceptions setEntity:[NSEntityDescription entityForName:@"AutoExceptions" inManagedObjectContext:moc]];
        
        NSError * error = nil;
        NSArray * exceptions = [moc executeFetchRequest:allExceptions error:&error];
        //error handling goes here
        for (NSManagedObject * exception in exceptions) {
            [moc deleteObject:exception];
        }
        error = nil;
        [moc save:&error];
        [allExceptions release];
    }
        [alert release];
    }

}
@end
