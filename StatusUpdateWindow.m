//
//  StatusUpdateWindow.m
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/06/04.
//
//

#import "StatusUpdateWindow.h"
#import "MAL_Updater_OS_XAppDelegate.h"
#import "MyAnimeList.h"

@interface StatusUpdateWindow ()

@end

@implementation StatusUpdateWindow
- (instancetype)init{
    self = [super initWithWindowNibName:@"StatusUpdateWindow"];
    if(!self)
        return nil;
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)showUpdateDialog:(NSWindow *)w withMALEngine:(MyAnimeList *)MALEngine{
    // Show Sheet
    [self.window makeKeyAndOrderFront:self];
    [self.window orderOut:self];
    // Set up UI
    _showtitle.objectValue = MALEngine.LastScrobbledTitle;
    [_showscore selectItemWithTag:MALEngine.TitleScore];
    [_showstatus selectItemAtIndex:[MALEngine getWatchStatus]];
    _episodefield.stringValue = [NSString stringWithFormat:@"%i", MALEngine.DetectedCurrentEpisode];
    if (MALEngine.TotalEpisodes !=0) {
        _epiformatter.maximum = @(MALEngine.TotalEpisodes);
    }
    // Stop Timer temporarily if scrobbling is turned on
    MAL_Updater_OS_XAppDelegate *appdel = (MAL_Updater_OS_XAppDelegate *)[NSApplication sharedApplication].delegate;
    if (appdel.scrobbling) {
        [appdel stoptimer];
    }
    if (w) {
        [w beginSheet:self.window completionHandler:^(NSModalResponse returnCode) {
            self.completion(returnCode);
        }];
    }
    else {
        self.completion([NSApp runModalForWindow:self.window]);
    }
}

- (IBAction)closeupdatestatus:(id)sender {
    if (self.window.sheetParent) {
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
    }
    else {
        [NSApp stopModalWithCode:NSModalResponseCancel];
    }
    [self.window close];
}

- (IBAction)updatetitlestatus:(id)sender {
    if (self.window.sheetParent) {
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
    }
    else {
        [NSApp stopModalWithCode:NSModalResponseOK];
    }
    [self.window close];
}

- (void)updateDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    self.completion(returnCode);
}
@end
