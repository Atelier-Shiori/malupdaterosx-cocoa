//
//  GeneralPrefController.m
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved.
//

#import "GeneralPrefController.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "Base64Category.h"


@implementation GeneralPrefController
- (id)init
{
	return [super initWithNibName:@"GeneralPreferenceView" bundle:nil];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
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
	//Reset Unofficial MAL API URL
	[APIUrl setStringValue:@"https://malapi.shioridiary.me"];
	// Generate API Key
	NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] autorelease];
	[defaults setObject:[APIUrl stringValue] forKey:@"MALAPIURL"];
	
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
	[alert runModal];
	/*[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:nil
						contextInfo:NULL];*/
}
@end
