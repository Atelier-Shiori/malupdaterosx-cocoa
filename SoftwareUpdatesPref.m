//
//  SoftwareUpdatesPref.m
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved.
//

#import "SoftwareUpdatesPref.h"


@implementation SoftwareUpdatesPref
@synthesize betacheck;

- (id)init
{
	return [super initWithNibName:@"SoftwareUpdateView" bundle:nil];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"SoftwareUpdatesPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"SoftwareUpdates"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Software Updates", @"Toolbar item name for the Software Updatespreference pane");
}
- (void)loadView{
    [super loadView];
    if([(NSString *)[[NSUserDefaults standardUserDefaults] valueForKey:@"SUFeedURL"] isEqualToString:@"https://updates.malupdaterosx.moe/malupdaterosx-beta/profileInfo.php"]) {
        betacheck.state = 1;
    }
}
- (IBAction)setBetaChannel:(id)sender{
    if (betacheck.state == 1) {
        [[NSUserDefaults standardUserDefaults] setObject:@"https://updates.malupdaterosx.moe/malupdaterosx-beta/profileInfo.php" forKey:@"SUFeedURL"];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setObject:@"https://updates.malupdaterosx.moe/malupdaterosx/profileInfo.php" forKey:@"SUFeedURL"];
    }
}
@end
