//
//  LoginPref.m
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 MAL Updater OS X Group. All rights reserved.
//

#import "LoginPref.h"
#import "Base64Category.h"
#import "MAL_Updater_OS_XAppDelegate.h"
#import <AFNetworking/AFNetworking.h>
#import "AuthWindow.h"
#import "Utility.h"
#import "ClientConstants.h"
#import "PKCEGenerator.h"

@implementation LoginPref
@synthesize logo;
@synthesize fieldusername;
@synthesize fieldpassword;
@synthesize savebut;
@synthesize clearbut;
@synthesize loggedinuser;
@synthesize appdelegate;
@synthesize MALEngine;
@synthesize loginview;
@synthesize loggedinview;

- (id)init
{
	return [super initWithNibName:@"LoginView" bundle:nil];
}

- (id)initwithAppDelegate:(MAL_Updater_OS_XAppDelegate *)adelegate{
    appdelegate = adelegate;
    return [super initWithNibName:@"LoginView" bundle:nil];
}

- (void)loadView{
    [super loadView];
    // Retrieve MyAnimeList Engine instance from app delegate
    MALEngine = appdelegate.MALEngine;
    // Set Logo
    logo.image = NSApp.applicationIconImage;
    // Load Login State
    [self loadlogin];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"LoginPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameUser];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Login", @"Toolbar item name for the Login preference pane");
}

#pragma mark Login Preferences Functions
- (void)loadlogin
{
    // Load Username
    if ([MALEngine checkaccount]) {
        [clearbut setEnabled: YES];
        [savebut setEnabled: NO];
        [loggedinview setHidden:NO];
        [loginview setHidden:YES];
        loggedinuser.stringValue = [MALEngine getusername];
    }
    else {
        //Disable Clearbut
        [clearbut setEnabled: NO];
        [savebut setEnabled: YES];
    }
}

- (IBAction)authorize:(id)sender {
    if (!_authw) {
        _authw = [AuthWindow new];
    }
    else {
        [_authw.window makeKeyAndOrderFront:self];
        [_authw loadAuthorization];
        [_authw close];
    }
    savebut.enabled = NO;
    [self.view.window beginSheet:_authw.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            NSString *pin = _authw.pin.copy;
            _authw.pin = nil;
            [self login:pin withChallenge:_authw.challenge];
        }
        else {
            savebut.enabled = YES;
        }
    }];
}

- (void)login:(NSString *)pin withChallenge:(NSString *)challenge {
    AFOAuth2Manager *OAuth2Manager =
    [[AFOAuth2Manager alloc] initWithBaseURL:[NSURL URLWithString:@"https://myanimelist.net/"]
                                    clientID:kMALClientID
                                      secret:kMALClientSecret];
    OAuth2Manager.useHTTPBasicAuthentication = NO;
    NSDictionary *parameters = @{@"grant_type" : @"authorization_code", @"code" : pin, @"code_verifier" : challenge};
    NSLog(@"%@", parameters);
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"/v1/oauth2/token" parameters:parameters success:^(AFOAuthCredential * _Nonnull credential) {
        NSLog(@"Token: %@", credential.accessToken);
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Error: %@", error);

    }];
    /*
    //Set Login URL
    NSURL *url = [NSURL URLWithString:@"https://myanimelist.net/api/account/verify_credentials.xml"];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    [Utility setUserAgent:request];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Username and Password
    request.headers = (NSMutableDictionary *)@{@"Authorization": [NSString stringWithFormat:@"Basic %@", [[NSString stringWithFormat:@"%@:%@", username, password] base64Encoding]]};
    //Verify Username/Password
    [request startRequest];
    // Check for errors
    NSError *error = request.error;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([request getStatusCode] == 200 && !error) {
                //Login successful
                [Utility showsheetmessage:@"Login Successful" explaination: @"Login is successful." window:self.view.window];
                // Store account in login keychain
                [MALEngine storeaccount:fieldusername.stringValue password:fieldpassword.stringValue];
                [clearbut setEnabled: YES];
                loggedinuser.stringValue = username;
                [loggedinview setHidden:NO];
                [loginview setHidden:YES];
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSinceNow:60*60*24] forKey:@"credentialscheckdate"];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"credentialsvalid"];
        }
        else {
            if (error.code == NSURLErrorNotConnectedToInternet) {
                [Utility showsheetmessage:@"MAL Updater OS X was unable to log you in since you are not connected to the internet" explaination:@"Check your internet connection and try again." window:self.view.window];
                [savebut setEnabled: YES];
                savebut.keyEquivalent = @"\r";
            }
            else {
                //Login Failed, show error message
                [Utility showsheetmessage:@"MAL Updater OS X was unable to log you in since you don't have the correct username and/or password." explaination:@"Check your username and password and try logging in again. If you recently changed your password, enter your new password and try again." window:self.view.window];
                [savebut setEnabled: YES];
                savebut.keyEquivalent = @"\r";
            }
        }
        [savebut setEnabled:YES];
    }); */
}

- (IBAction)registermal:(id)sender
{
    //Show MAL Registration Page
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://myanimelist.net/register.php"]];
}

- (IBAction) showgettingstartedpage:(id)sender
{
    //Show Getting Started help page
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/malupdaterosx-cocoa/wiki/Getting-Started"]];
}

- (IBAction)clearlogin:(id)sender
{
    if (!appdelegate.scrobbling && !appdelegate.scrobbleractive) {
        // Set Up Prompt Message Window
        NSAlert *alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        alert.messageText = @"Do you want to log out?";
        alert.informativeText = @"Once you logged out, you need to log back in before you can use this application.";
        // Set Message type to Warning
        alert.alertStyle = NSWarningAlertStyle;
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode== NSAlertFirstButtonReturn) {
                //Remove account from keychain
                [MALEngine removeaccount];
                //Disable Clearbut
                [clearbut setEnabled: NO];
                [savebut setEnabled: YES];
                loggedinuser.stringValue = @"";
                [loggedinview setHidden:YES];
                [loginview setHidden:NO];
                fieldusername.stringValue = @"";
                fieldpassword.stringValue = @"";
                [appdelegate resetUI];
            }
        }];
    }
    else {
        [Utility showsheetmessage:@"Cannot Logout" explaination:@"Please turn off automatic scrobbling before logging out." window:self.view.window];
    }
}
@end
