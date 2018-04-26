//
//  FixSearchDialog.m
//  MAL Updater OS X
//
//  Created by 高町なのは on 2014/11/15.
//  Copyright (c) 2014年 MAL Updater OS X Group. All rights reserved.
//

#import "FixSearchDialog.h"
#import <AFNetworking/AFNetworking.h>
#import "NSString_stripHtml.h"
#import "MyAnimeList+Keychain.h"
#import "Utility.h"

@interface FixSearchDialog ()
@property (nonatomic, copy) void (^completionHandler)(long returnCode);
@property (strong) AFHTTPSessionManager *searchManager;
@end

@implementation FixSearchDialog

@synthesize arraycontroller;
@synthesize search;
@synthesize deleteoncorrection;
@synthesize onetimecorrection;
@synthesize tb;
@synthesize selectedsynopsis;
@synthesize selectedtitle;
@synthesize selectedaniid;
@synthesize selectedtotalepisodes;
@synthesize searchquery;
@synthesize correction;
@synthesize allowdelete;

- (id)init{
    self = [super initWithWindowNibName:@"FixSearchDialog"];
     if(!self)
       return nil;
    return self;
}
            
- (void)windowDidLoad {
    if (correction) {
        if (allowdelete) {
            [deleteoncorrection setHidden:NO];
            deleteoncorrection.state = NSOnState;
        }
        [onetimecorrection setHidden:NO];
    }
    else {
        deleteoncorrection.state = 0;
    }
    _searchManager = [AFHTTPSessionManager manager];
    _searchManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [super windowDidLoad];
    if (searchquery.length>0) {
        search.stringValue = searchquery;
        [self search:nil];
    }
}

- (void)showWindowAsModal:(void (^)(long returnCode))completionHandler {
    [self.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    _completionHandler = completionHandler;
}

- (IBAction)closesearch:(id)sender {
    //[self.window orderOut:self];
    //[NSApp endSheet:self.window returnCode:0];
    if (self.window.sheetParent) {
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
    }
    else {
        _completionHandler(NSModalResponseCancel);
        [self.window close];
    }
}

- (IBAction)updatesearch:(id)sender {
    NSDictionary *d = arraycontroller.selectedObjects[0];
    if (correction) {
        // Set Up Prompt Message Window
        NSAlert *alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        alert.messageText = [NSString stringWithFormat:@"Do you want to correct this title as %@?",d[@"title"]];
        alert.informativeText = @"Once done, you cannot undo this action.";
        // Set Message type to Warning
        alert.alertStyle = NSWarningAlertStyle;
        if ([alert runModal]== NSAlertFirstButtonReturn) {
            [self finish:d];
        }
        else {
            return;
        }
    }
    else {
        [self finish:d];
    }   
}

- (void)finish:(NSDictionary *)d{
    selectedtitle = d[@"title"];
    selectedaniid = [d[@"id"] stringValue];
    if (d[@"episodes"]) {
        selectedtotalepisodes = ((NSNumber *)d[@"episodes"]).intValue;
    }
    else {
        // No episode total yet, set to set
        selectedtotalepisodes = 0;
    }
    if (self.window.sheetParent) {
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
    }
    else {
        _completionHandler(NSModalResponseOK);
        [self.window close];
    }
}

- (IBAction)search:(id)sender{
    if ([MyAnimeList checkexpired]) {
        [MyAnimeList refreshtoken:^(bool success) {
            [self search:sender];
        }];
        return;
    }
    if (search.stringValue.length > 0) {
        NSString *searchterm = [Utility urlEncodeString:search.stringValue];
        // Set Token
            [_searchManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [MyAnimeList retrieveCredentials].accessToken] forHTTPHeaderField:@"Authorization"];
        // Perform Search
        [_searchManager GET:[NSString stringWithFormat:@"https://api.myanimelist.net/v2/anime?q=%@&limit=25&fields=id,title,main_picture,alternative_titles,start_date,end_date,synopsis,media_type,status,num_episodes", searchterm] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [self populateData:[Utility convertSearchArray:responseObject[@"data"]]];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        }];
    }
    else {
        //Remove all existing Data
        [[arraycontroller mutableArrayValueForKey:@"content"] removeAllObjects];
    }
}

- (IBAction)getHelp:(id)sender{
    //Show Help
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/malupdaterosx-cocoa/wiki/Correction-Exception-Help"]];
}

- (void)populateData:(NSArray *)searchdata {
    //Remove all existing Data
    [[arraycontroller mutableArrayValueForKey:@"content"] removeAllObjects];
    if (searchdata) {
        //Add it to the array controller
        [arraycontroller addObjects:searchdata];
    }
    //Show on tableview
    [tb reloadData];
    //Deselect Selection
    [tb deselectAll:self];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification{
    if ([notification.object selectedRow] != -1) {
        // Show synopsis
        NSDictionary *d = arraycontroller.selectedObjects[0];
        selectedsynopsis.string = [[NSString stringWithFormat:@"%@", d[@"synopsis"]] stripHtml];
    }
    else {
        selectedsynopsis.string = @"";
    }

}

- (bool)getdeleteTitleonCorrection{
    return (bool) deleteoncorrection.state;
}

- (bool)getcorrectonce{
    return (bool) onetimecorrection.state;
}

@end
