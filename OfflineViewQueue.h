//
//  OfflineViewQueue.h
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/01/08.
//
//

#import <Cocoa/Cocoa.h>
#import "MAL_Updater_OS_XAppDelegate.h"

@interface OfflineViewQueue : NSWindowController{
    	NSManagedObjectContext *managedObjectContext;
    MAL_Updater_OS_XAppDelegate * delegate;
}
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
-(id)initwithDelegate:(MAL_Updater_OS_XAppDelegate *)d;
@end
