//
//  Video.m
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 __MyCompanyName__. All rights reserved.
//

#import "Video.h"


@implementation Video

- (id)init
{
	return [super initWithNibName:@"VideoDetection" bundle:nil];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"VideoPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"movies.tiff"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Video Detection", @"Toolbar item name for the Video preference pane");
}

@end
