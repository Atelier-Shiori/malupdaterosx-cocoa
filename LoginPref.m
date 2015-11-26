//
//  LoginPref.m
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved.
//

#import "LoginPref.h"
#import "Base64Category.h"
#import "MAL_Updater_OS_XAppDelegate.h"

#import "EasyNSURLConnection.h"
#import "Utility.h"


@implementation LoginPref
@synthesize loginpanel;

- (id)init
{
	return [super initWithNibName:@"LoginView" bundle:nil];
}
- (id)initwithAppDelegate:(MAL_Updater_OS_XAppDelegate *)adelegate{
    appdelegate = adelegate;
    return [super initWithNibName:@"LoginView" bundle:nil];
}
-(void)loadView{
    [super loadView];
    // Retrieve MyAnimeList Engine instance from app delegate
    MALEngine = [appdelegate getMALEngineInstance];
    // Set Logo
    [logo setImage:[NSApp applicationIconImage]];
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
-(void)loadlogin
{
	// Load Username
	if ([MALEngine checkaccount]) {
		[clearbut setEnabled: YES];
		[savebut setEnabled: NO];
        [loggedinview setHidden:NO];
        [loginview setHidden:YES];
        [loggedinuser setStringValue:[MALEngine getusername]];
	}
	else {
		//Disable Clearbut
		[clearbut setEnabled: NO];
		[savebut setEnabled: YES];
	}
}
-(IBAction)startlogin:(id)sender
{
	{
		//Start Login Process
		//Disable Login Button
		[savebut setEnabled: NO];
		[savebut displayIfNeeded];
		if ( [[fieldusername stringValue] length] == 0) {
			//No Username Entered! Show error message
			[Utility showsheetmessage:@"MAL Updater OS X was unable to log you in since you didn't enter a username" explaination:@"Enter a valid username and try logging in again" window:[[self view] window]];
			[savebut setEnabled: YES];
		}
		else {
			if ( [[fieldpassword stringValue] length] == 0 ) {
				//No Password Entered! Show error message.
				[Utility showsheetmessage:@"MAL Updater OS X was unable to log you in since you didn't enter a password" explaination:@"Enter a valid password and try logging in again." window:[[self view] window]];
				[savebut setEnabled: YES];
			}
			else {
                    [self login:[fieldusername stringValue] password:[fieldpassword stringValue]];
                }
		}
	}
}
-(void)login:(NSString *)username password:(NSString *)password{
    //Set Login URL
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/1/account/verify_credentials", [defaults objectForKey:@"MALAPIURL"]]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
	//Ignore Cookies
	[request setUseCookies:NO];
	//Set Username and Password
    [request addHeader:[NSString stringWithFormat:@"Basic %@", [[NSString stringWithFormat:@"%@:%@", username, password] base64Encoding]] forKey:@"Authorization"];
	//Verify Username/Password
	[request startRequest];
	// Check for errors
    NSError * error = [request getError];
    if ([request getStatusCode] == 200 && error == nil) {
        //Login successful
        [Utility showsheetmessage:@"Login Successful" explaination: @"Login is successful." window:[[self view] window]];
		// Store account in login keychain
        [MALEngine storeaccount:[fieldusername stringValue] password:[fieldpassword stringValue]];
        [clearbut setEnabled: YES];
        [loggedinuser setStringValue:username];
        [loggedinview setHidden:NO];
        [loginview setHidden:YES];
    }
    else{
        if (error.code == NSURLErrorNotConnectedToInternet) {
            [Utility showsheetmessage:@"MAL Updater OS X was unable to log you in since you are not connected to the internet" explaination:@"Check your internet connection and try again." window:[[self view] window]];
            [savebut setEnabled: YES];
            [savebut setKeyEquivalent:@"\r"];
        }
        else{
            //Login Failed, show error message
            [Utility showsheetmessage:@"MAL Updater OS X was unable to log you in since you don't have the correct username and/or password." explaination:@"Check your username and password and try logging in again. If you recently changed your password, enter your new password and try again." window:[[self view] window]];
            [savebut setEnabled: YES];
            [savebut setKeyEquivalent:@"\r"];
        }
    }
}
-(IBAction)registermal:(id)sender
{
	//Show MAL Registration Page
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://myanimelist.net/register.php"]];
}
-(IBAction) showgettingstartedpage:(id)sender
{
    //Show Getting Started help page
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/malupdaterosx-cocoa/wiki/Getting-Started"]];
}
-(IBAction)clearlogin:(id)sender
{
    if (![appdelegate getisScrobbling] && ![appdelegate getisScrobblingActive]) {
        // Set Up Prompt Message Window
        NSAlert * alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:@"Do you want to log out?"];
        [alert setInformativeText:@"Once you logged out, you need to log back in before you can use this application."];
        // Set Message type to Warning
        [alert setAlertStyle:NSWarningAlertStyle];
        if ([alert runModal]== NSAlertFirstButtonReturn) {
            //Remove account from keychain
            [MALEngine removeaccount];
            //Disable Clearbut
            [clearbut setEnabled: NO];
            [savebut setEnabled: YES];
            [loggedinuser setStringValue:@""];
            [loggedinview setHidden:YES];
            [loginview setHidden:NO];
            [fieldusername setStringValue:@""];
            [fieldpassword setStringValue:@""];
        }
    }
    else{
        [Utility showsheetmessage:@"Cannot Logout" explaination:@"Please turn off automatic scrobbling before logging out." window:[[self view] window]];
    }
}
/*
 Reauthorization Panel
 */
-(IBAction)reauthorize:(id)sender{
    if (![appdelegate getisScrobbling] && ![appdelegate getisScrobblingActive]) {
        [NSApp beginSheet:self.loginpanel
           modalForWindow:[[self view] window] modalDelegate:self
           didEndSelector:@selector(reAuthPanelDidEnd:returnCode:contextInfo:)
              contextInfo:(void *)nil];
    }
    else{
        [Utility showsheetmessage:@"Cannot Logout" explaination:@"Please turn off automatic scrobbling before reauthorizing." window:[[self view] window]];
    }
}
- (void)reAuthPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1) {
        [self login: (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"Username"] password:[passwordinput stringValue]];
    }
    //Reset and Close
    [passwordinput setStringValue:@""];
    [invalidinput setHidden:YES];
    [self.loginpanel close];
}
-(IBAction)cancelreauthorization:(id)sender{
    [self.loginpanel orderOut:self];
    [NSApp endSheet:self.loginpanel returnCode:0];
    
}
-(IBAction)performreauthorization:(id)sender{
    if ([[passwordinput stringValue] length] == 0) {
        // No password, indicate it
        NSBeep();
        [invalidinput setHidden:NO];
    }
    else{
        [invalidinput setHidden:YES];
        [self.loginpanel orderOut:self];
        [NSApp endSheet:self.loginpanel returnCode:1];
    }
}
@end
