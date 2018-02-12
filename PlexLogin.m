//
//  PlexLogin.m
//  Hachidori
//
//  Created by 天々座理世 on 2017/07/08.
//
//

#import "PlexLogin.h"
#import <DetectionKit/DetectionKit.h>
@interface PlexLogin ()
@property (strong) IBOutlet NSTextField *username;
@property (strong) IBOutlet NSSecureTextField *password;
@property (strong) IBOutlet NSButton *loginbutton;
@property (strong) IBOutlet NSButton *cancelbutton;
@property (strong) IBOutlet NSTextField *status;
@property (strong) IBOutlet NSProgressIndicator *progressindicator;

@end

@implementation PlexLogin

- (instancetype)init {
    self = [super initWithWindowNibName:@"PlexLogin"];
    if (!self) {
        return nil;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
- (IBAction)cancel:(id)sender {
    _status.stringValue = @"";
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
    [self.window close];
}

- (IBAction)login:(id)sender {
    _loginbutton.enabled = NO;
    _cancelbutton.enabled = NO;
    _status.stringValue = @"";
    _progressindicator.hidden = NO;
    [_progressindicator startAnimation:self];
    NSString *username = _username.stringValue;
    NSString *password = _password.stringValue;
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        bool success = [PlexAuth performplexlogin:username withPassword:password];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                _status.stringValue = @"";
                [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
                [self.window close];
            }
            else {
                _status.stringValue = @"Login failed.";
            }
            _loginbutton.enabled = YES;
            _cancelbutton.enabled = YES;
            _progressindicator.hidden = YES;
            [_progressindicator stopAnimation:self];
        });
    });
    
}
@end
