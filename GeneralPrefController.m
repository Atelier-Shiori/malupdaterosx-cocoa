//
//  GeneralPrefController.m
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved.
//

#import "GeneralPrefController.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>
#import "MAL_Updater_OS_XAppDelegate.h"
#import "AutoExceptions.h"
#import "Utility.h"
#import "LoginItems.h"


@implementation GeneralPrefController
- (id)init
{
	return [super initWithNibName:@"GeneralPreferenceView" bundle:nil];
}

-(IBAction)toggleLaunchAtStartup:(id)sender{
    [LoginItems toggleLaunchAtStartup];
}

#pragma mark -
#pragma mark MASPreferencesViewController
-(void)loadView{
    [super loadView];
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9) {
        // Disable Yosemite UI options
        [disablenewtitlebar setEnabled:NO];
        [disablevibarency setEnabled: NO];
    }
    [startatlogin setState:[LoginItems isLaunchAtStartup]]; // Set Launch at Startup State
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
    });
    
}
-(IBAction)disableAutoExceptions:(id)sender{
    if ([updateexceptionschk state]) {
        [self updateAutoExceptions:sender];
    }
    else {
        // Clears Exceptions if User chooses
        // Set Up Prompt Message Window
        NSAlert * alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:@"Do you want to remove all Auto Exceptions Data?"];
        [alert setInformativeText:@"Since you are disabling Auto Exceptions, you can delete the Auto Exceptions Data. You will be able to download it again."];
        // Set Message type to Warning
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode) {
                if (returnCode== NSAlertFirstButtonReturn) {
                    [AutoExceptions clearAutoExceptions];
                }
        }];
    }
}
- (IBAction)changetimerinterval:(id)sender {
    // Sets new time for the timer, if running
    MAL_Updater_OS_XAppDelegate * delegate = (MAL_Updater_OS_XAppDelegate *)[NSApplication sharedApplication].delegate;
    if ([delegate getisScrobbling]) {
        [delegate stoptimer];
        [delegate starttimer];
    }
}
@end
