//
//  MAL_Updater_OS_XTests.m
//  MAL Updater OS XTests
//
//  Created by 天々座理世 on 2017/04/20.
//
//

#import <XCTest/XCTest.h>
#import "MyAnimeList.h"
#import "MyAnimeList+Keychain.h"
#import "MAL_Updater_OS_XAppDelegate.h"
#import "AutoExceptions.h"
#import "DonationKeyConstants.h"
#import "Utility.h"

@interface MAL_Updater_OS_XTests : XCTestCase
@property (strong) MyAnimeList *MALEngine;
@property (strong) NSArray *testdata;
@property (strong) NSNumber *confirmnewtitles;
@property (strong) NSNumber *useSearchCache;
@end

@implementation MAL_Updater_OS_XTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _MALEngine = [[MyAnimeList alloc] init];
    MAL_Updater_OS_XAppDelegate *delegate = (MAL_Updater_OS_XAppDelegate *)[NSApplication sharedApplication].delegate;
    //Check for latest Auto Exceptions
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"ExceptionsLastUpdated"] timeIntervalSinceNow] < -604800 ||![[NSUserDefaults standardUserDefaults] objectForKey:@"ExceptionsLastUpdated"]) {
        // Has been 1 Week, update Auto Exceptions
        [AutoExceptions updateAutoExceptions];
    }
    // Set Context
    [_MALEngine setManagedObjectContext:[delegate getObjectContext]];
    // Load Test Data
    NSBundle *mainBundle = [NSBundle bundleForClass:[self class]];
    NSData *dataset = [NSData dataWithContentsOfFile:[mainBundle pathForResource: @"testdata" ofType: @"json"]
                                             options:0
                                               error:NULL];
    NSError *error;
    _testdata = [NSArray alloc];
    _testdata= [NSJSONSerialization JSONObjectWithData:dataset options:kNilOptions error:&error];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _confirmnewtitles = [defaults valueForKey:@"ConfirmNewTitle"];
    [defaults setValue:@NO forKey:@"ConfirmNewTitle"];
    _useSearchCache  = [defaults valueForKey:@"useSearchCache"];
    [defaults setValue:@NO forKey:@"useSearchCache"];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:_confirmnewtitles forKey:@"ConfirmNewTitle"];
    [defaults setValue:_useSearchCache forKey:@"useSearchCache"];
}

- (void)testScrobble {
    if ([_MALEngine checkaccount]) {
        // Test an array of file names (Retrieve a JSON file from local drive)
        int success = 0;
        int fail = 0;
        int incorrect = 0;
        NSUInteger icount = _testdata.count;
        int count = (int)icount;
        NSLog(@"Testing a dataset with %i filenames", count);
        NSLog(@"Starting Test...\n\n");
        for (NSDictionary *d in _testdata) {
            @autoreleasepool {
                NSString *filename = d[@"filename"];
                NSString *expectedtitle = d[@"expected-title"];
                NSString *detectedepisode = d[@"detectedepisode"];
                NSNumber *deletetitle = d[@"deletetitle"];
                int status = [_MALEngine performscrobbletest:filename delete:deletetitle.boolValue];
                switch (status) {
                    case ScrobblerUpdateSuccessful:
                    case ScrobblerAddTitleSuccessful:
                    case ScrobblerConfirmNeeded:
                    case ScrobblerUpdateNotNeeded:
                        if ([expectedtitle isEqualToString:[_MALEngine getLastScrobbledActualTitle]] && [detectedepisode isEqualToString:[_MALEngine getLastScrobbledEpisode]]) {
                            NSLog(@"Scrobble of %@ - %@ was sucessful with status: %i",expectedtitle,detectedepisode,status);
                            success++;
                        }
                        else {
                            NSLog(@"Scrobble of %@ - %@ was successful, but incorrect (detected as %@ instead) with status: %i",expectedtitle,detectedepisode,[_MALEngine getLastScrobbledActualTitle],status);
                            incorrect++;
                        }
                        break;
                    default:
                        NSLog(@"Scrobble of %@ - %@ failed with status: %i",expectedtitle,detectedepisode,status);
                        fail++;
                        break;
                }
            }
        }
        NSLog(@"Test results: %i successful, %i incorrect, %i failed", success, incorrect, fail);
        if (fail > 0 || (incorrect/count) > .05) {
            XCTAssert(NO, @"Test Failed: Failed scrobbles or too many incorrect updates");
        }
        else {
            XCTAssert(YES, @"No Errors");
        }
    }
    else {
        XCTAssert(NO, @"Test Failed: There is no account stored");
    }
}

- (void)testDonationKeyValidation {
    int status = [Utility checkDonationKey:donorkey name:donorname];
    if (status == 1) {
        NSLog(@"Donation key validated successfully");
        XCTAssert(YES, @"No Errors");
    }
    else {
        NSLog(@"Donation key validated failed");
        XCTAssert(NO, @"Key validation failed.");
    }
}

@end
