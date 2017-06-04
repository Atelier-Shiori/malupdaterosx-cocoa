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

- (void)showUpdateDialog:(NSWindow *) w withMALEngine:(MyAnimeList *)MALEngine{
    // Show Sheet
    [NSApp beginSheet:self.window
       modalForWindow:w modalDelegate:self
       didEndSelector:@selector(updateDidEnd:returnCode:contextInfo:)
          contextInfo:(void *)nil];
    // Set up UI
    [_showtitle setObjectValue:[MALEngine getLastScrobbledTitle]];
    [_showscore selectItemWithTag:[MALEngine getScore]];
    [_showstatus selectItemAtIndex:[MALEngine getWatchStatus]];
    [_episodefield setStringValue:[NSString stringWithFormat:@"%i", [MALEngine getCurrentEpisode]]];
    if ([MALEngine getTotalEpisodes] !=0) {
        [_epiformatter setMaximum:@([MALEngine getTotalEpisodes])];
    }
    // Stop Timer temporarily if scrobbling is turned on
    MAL_Updater_OS_XAppDelegate *appdel = (MAL_Updater_OS_XAppDelegate *)[NSApplication sharedApplication].delegate;
    if ([appdel getisScrobbling]) {
        [appdel stoptimer];
    }
    
}

- (IBAction)closeupdatestatus:(id)sender {
    [self.window orderOut:self];
    [NSApp endSheet:self.window returnCode:0];
}

- (IBAction)updatetitlestatus:(id)sender {
    [self.window orderOut:self];
    [NSApp endSheet:self.window returnCode:1];
}

- (void)updateDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    self.completion(returnCode);
}
@end
