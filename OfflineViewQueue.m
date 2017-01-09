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
-(id)init{
    self = [super initWithWindowNibName:@"OfflineViewQueue"];
    if(!self)
        return nil;
    return self;
}
-(id)initwithDelegate:(MAL_Updater_OS_XAppDelegate *)d{
    delegate = d;
    managedObjectContext = [delegate getObjectContext];
    return [self init];
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
