//
//  ExceptionsPref.h
//  MAL Updater OS X
//
//  Created by 高町なのは on 2014/11/16.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>
#import "FixSearchDialog.h"
#import "MAL_Updater_OS_XAppDelegate.h"
@class FixSearchDialog;
@interface ExceptionsPref : NSViewController <MASPreferencesViewController>{
    IBOutlet NSArrayController * arraycontroller;
    IBOutlet NSArrayController * ignorearraycontroller;
    IBOutlet NSArrayController * ignorefilenamearraycontroller;
    IBOutlet NSTableView * tb;
    IBOutlet NSTableView * iftb;
    NSString *detectedtitle;
    NSManagedObjectContext *managedObjectContext;
}
@property(strong) FixSearchDialog *fsdialog;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@end
