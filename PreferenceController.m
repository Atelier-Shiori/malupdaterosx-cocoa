//
//  PreferenceController.m
//  MAL Updater OS X
//
//  Created by Tohno Minagi on 8/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
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
	choice = NSRunCriticalAlertPanel(@"Are you sure you want to remove this token?", @"Once done, this action cannot be undone,", @"Yes", @"No", nil, 8);
	NSLog(@"%i", choice);
	if (choice == 1) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:@"" forKey:@"Base64Token"];
		// Clear Username
		[defaults setObject:@"" forKey:@"Username"];
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
			choice = NSRunCriticalAlertPanel(@"MAL Updater OS X was unable to log you in since you didn't enter a username", @"Enter a valid username and try logging in again", @"OK", nil, nil, 8);
			[savebut setEnabled: YES];
		}
		else {
			if ( [[fieldpassword stringValue] length] == 0 ) {
				//No Password Entered! Show error message.
				choice = NSRunCriticalAlertPanel(@"MAL Updater OS X was unable to log you in since you didn't enter a password", @"Enter a valid password and try logging in again", @"OK", nil, nil, 8);
				[savebut setEnabled: YES];
			}
			else {
				//Set Login URL
				NSURL *url = [NSURL URLWithString:@"http://mal-api.com/account/verify_credentials"];
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
						choice = NSRunAlertPanel(@"Login Successful", @"Login Token has been created.", @"OK", nil, nil, 8);
						// Generate API Key
						NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] autorelease];
						NSString * Token = [NSString stringWithFormat:@"%@:%@", [fieldusername stringValue], [fieldpassword stringValue]];
						[defaults setObject:[Token base64Encoding] forKey:@"Base64Token"];
						[defaults setObject:[fieldusername stringValue] forKey:@"Username"];
						[clearbut setEnabled: YES];
						break;
					case 401:
						//Login Failed, show error message
						choice = NSRunCriticalAlertPanel(@"MAL Updater OS X was unable to log you in since you don't have the correct username and/or password", @"Check your username and password and try logging in again. If you recently changed your password, ener you new password and try again.", @"OK", nil, nil, 8);
						[savebut setEnabled: YES];
						[savebut setKeyEquivalent:@"\r"];
						break;
					default:
						//Login Failed, show error message
						choice = NSRunCriticalAlertPanel(@"MAL Updater OS X was unable to log you in because of an unknown error.", [NSString stringWithFormat:@"Error %i", statusCode], @"OK", nil, nil, 8);
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
@end
