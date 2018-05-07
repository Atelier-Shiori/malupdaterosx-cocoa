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
@property bool airing;
@property bool completedairing;
@property int currentwatchedepisode;
@end

@implementation StatusUpdateWindow
- (instancetype)init{
    self = [super initWithWindowNibName:@"StatusUpdateWindow"];
    if (!self) {
        return nil;
    }
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
    _showtitle.objectValue = MALEngine.LastScrobbledActualTitle;
    [_showscore selectItemWithTag:MALEngine.TitleScore];
    [_showstatus selectItemAtIndex:[MALEngine getWatchStatus]];
    _airing = MALEngine.airing;
    _completedairing = MALEngine.completedairing;
    _currentwatchedepisode = MALEngine.DetectedCurrentEpisode;
    _episodefield.stringValue = [NSString stringWithFormat:@"%i", MALEngine.DetectedCurrentEpisode];
    if (MALEngine.TotalEpisodes !=0) {
        _epiformatter.maximum = @(MALEngine.TotalEpisodes);
    }
    else {
        _epiformatter.maximum = @(9999999);
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
        [NSApp activateIgnoringOtherApps:YES];
        [self.window makeKeyAndOrderFront:self];
    }
}

- (IBAction)closeupdatestatus:(id)sender {
    if (self.window.sheetParent) {
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
    }
    else {
        _completion(NSModalResponseCancel);
        [self.window close];
    }
}

- (IBAction)updatetitlestatus:(id)sender {
    if (_airing && !_completedairing && [_showstatus.selectedItem.title isEqualToString:@"completed"]) {
        NSBeep();
        return;
    }
    else if (_episodefield.intValue > _epiformatter.maximum.intValue || _episodefield.intValue < 0) {
        NSBeep();
        _episodefield.intValue = _currentwatchedepisode;
        return;
    }
    else if ([_showstatus.selectedItem.title isEqualToString:@"completed"]) {
        _episodefield.intValue = _epiformatter.maximum.intValue;
    }
    if (self.window.sheetParent) {
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
    }
    else {
        _completion(NSModalResponseOK);
        [self.window close];
    }
}

- (void)updateDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    self.completion(returnCode);
}
@end
