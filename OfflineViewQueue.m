//
//  OfflineViewQueue.m
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/01/08.
//
//

#import "OfflineViewQueue.h"

@interface OfflineViewQueue ()

@end

@implementation OfflineViewQueue
@dynamic managedObjectContext;
- (NSManagedObjectContext *)managedObjectContext {
    MAL_Updater_OS_XAppDelegate *appDelegate = (MAL_Updater_OS_XAppDelegate *)[NSApplication sharedApplication].delegate;
    return appDelegate.managedObjectContext;
}
-(id)init{
    self = [super initWithWindowNibName:@"OfflineViewQueue"];
    if(!self)
        return nil;
    return self;
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
