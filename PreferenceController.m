//
//  PreferenceController.m
//  MAL Updater OS X
//
//  Created by James M. on 8/8/10.
//  Copyright 2009-2010 Chikorita157's Anime Blog. All rights reserved. Code licensed under New BSD License
//

#import "PreferenceController.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "Base64Category.h"

@implementation PreferenceController
- (id)init
{
	if(![super initWithWindowNibName:@"Preferences"])
		return nil;
	return self;
}

-(void)windowDidLoad
{
	//Check Login Keychain
	[self loadlogin];
}

-(void)loadlogin
{
	// Load Username
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *Base64Token = [defaults objectForKey:@"Base64Token"];
	if (Base64Token.length > 0) {
		[clearbut setEnabled: YES];
		[savebut setEnabled: NO];
	}
	else {
		//Disable Clearbut
		[clearbut setEnabled: NO];
		[savebut setEnabled: YES];
	}
	//Release Keychain Item
	[Base64Token release];
}
-(IBAction)clearlogin:(id)sender
{
	// Set Up Prompt Message Window
	NSAlert * alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"Yes"];
	[alert addButtonWithTitle:@"No"];
	[alert setMessageText:@"Are you sure you want to remove this token?"];
	[alert setInformativeText:@"Once done, this action cannot be undone."];
	// Set Message type to Warning
	[alert setAlertStyle:NSWarningAlertStyle];
	// Show as Sheet on historywindow
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(clearcookieended:code:conext:)
						contextInfo:NULL];
}
-(IBAction)startlogin:(id)sender
{
	{
		//Start Login Process
		//Disable Login Button
		[savebut setEnabled: NO];
		[savebut displayIfNeeded];
		//Load API URL
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ( [[fieldusername stringValue] length] == 0) {
			//No Username Entered! Show error message
			[self showsheetmessage:@"MAL Updater OS X was unable to log you in since you didn't enter a username" explaination:@"Enter a valid username and try logging in again"];
			[savebut setEnabled: YES];
		}
		else {
			if ( [[fieldpassword stringValue] length] == 0 ) {
				//No Password Entered! Show error message.
				[self showsheetmessage:@"MAL Updater OS X was unable to log you in since you didn't enter a password" explaination:@"Enter a valid password and try logging in again."];
				[savebut setEnabled: YES];
			}
			else {
				//Set Login URL
				NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/account/verify_credentials", [defaults objectForKey:@"MALAPIURL"]]];
				ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
				//Ignore Cookies
				[request setUseCookiePersistence:NO];
				//Set Username
				[request setUsername:[fieldusername stringValue]];
				[request setPassword:[fieldpassword stringValue]];
				//Vertify Username/Password
				[request startSynchronous];
				// Get Status Code
				int statusCode = [request responseStatusCode];
				switch (statusCode) {
					case 200:
						//Login successful
						[self showsheetmessage:@"Login Successful" explaination: @"Login Token has been created."];
						// Generate API Key
						NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] autorelease];
						NSString * Token = [NSString stringWithFormat:@"%@:%@", [fieldusername stringValue], [fieldpassword stringValue]];
						[defaults setObject:[Token base64Encoding] forKey:@"Base64Token"];
						[defaults setObject:[fieldusername stringValue] forKey:@"Username"];
						[clearbut setEnabled: YES];
						break;
					case 401:
						//Login Failed, show error message
						[self showsheetmessage:@"MAL Updater OS X was unable to log you in since you don't have the correct username and/or password." explaination:@"Check your username and password and try logging in again. If you recently changed your password, enter your new password and try again."];
						[savebut setEnabled: YES];
						[savebut setKeyEquivalent:@"\r"];
						break;
					default:
						//Login Failed, show error message
						[self showsheetmessage:@"MAL Updater OS X was unable to log you in because of an unknown error." explaination:[NSString stringWithFormat:@"Error %i", statusCode]];
						[savebut setEnabled: YES];
						[savebut setKeyEquivalent:@"\r"];
						break;
				}
				//release
				request = nil;
				url = nil;
			}
		}
	}
}
-(IBAction)checkupdates:(id)sender
{
	//Initalize Update
	[[SUUpdater sharedUpdater] checkForUpdates:sender];
}
-(IBAction)registermal:(id)sender
{
	//Show MAL Registration Page
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://myanimelist.net/register.php"]];
}
-(void)clearcookieended:(NSAlert *)alert
				   code:(int)achoice
				 conext:(void *)v
{
	if (achoice == 1000) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:@"" forKey:@"Base64Token"];
		// Clear Username
		[defaults setObject:@"" forKey:@"Username"];
		//Disable Clearbut
		[clearbut setEnabled: NO];
		[savebut setEnabled: YES];
	}
}
-(IBAction)testapi:(id)sender
{
	//Load API URL
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Set URL
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/animelist/chikorita157", [defaults objectForKey:@"MALAPIURL"]]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
	//Test API
	[request startSynchronous];
	// Get Status Code
	int statusCode = [request responseStatusCode];
	switch (statusCode) {
		case 200:
			[self showsheetmessage:@"API Test Successful" explaination:[NSString stringWithFormat:@"HTTP Code: %i", statusCode]];
			break;
		default:
			[self showsheetmessage:@"API Test Unsuccessful" explaination:[NSString stringWithFormat:@"HTTP Code: %i", statusCode]];
			break;
	}
	//release
	request = nil;
	url = nil;
	
}
-(IBAction)resetapiurl:(id)sender
{
	[APIUrl setStringValue:@"http://mal-api.com/"];
}
-(void)showsheetmessage:(NSString *)message
		   explaination:(NSString *)explaination
{
	// Set Up Prompt Message Window
	NSAlert * alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:message];
	[alert setInformativeText:explaination];
	// Set Message type to Warning
	[alert setAlertStyle:1];
	// Show as Sheet on Preference Window
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:nil
						contextInfo:NULL];
}
@end
