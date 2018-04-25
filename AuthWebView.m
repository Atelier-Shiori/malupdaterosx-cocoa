//
//  AuthWebView.m
//  Shukofukurou
//
//  Created by 小鳥遊六花 on 4/24/18.
//  Copyright © 2018 Atelier Shiori. All rights reserved.
//

#import "AuthWebView.h"
#import "ClientConstants.h"
#import "PKCEGenerator.h"

@interface AuthWebView ()
@property (strong) WKWebView *webView;
@property (strong) NSString *challenge;
@end

@implementation AuthWebView
- (void)loadView {
    WKWebViewConfiguration *webConfiguration = [WKWebViewConfiguration new];
    _webView = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:webConfiguration];
    _webView.UIDelegate = self;
    _webView.navigationDelegate = self;
    self.view = _webView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self loadAuthorization];
}

- (NSURL *)authURL {
    _challenge = [PKCEGenerator generateCodeChallenge:[PKCEGenerator createVerifierString]];
    NSString *authurl = [NSString stringWithFormat:@"https://myanimelist.net/v1/oauth2/authorize?response_type=code&client_id=%@&code_challenge=%@&code_challenge_method=plain",kMALClientID,_challenge];
    return [NSURL URLWithString:authurl];
}

- (void)loadAuthorization {
    [_webView loadRequest:[NSURLRequest requestWithURL:[self authURL]]];
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSLog(@"%@",navigationAction.request.URL.absoluteString);
    if ([navigationAction.request.URL.absoluteString containsString:@"https://malupdaterosx.moe/?code="]) {
        // Save Pin
        decisionHandler(WKNavigationActionPolicyCancel);
        [self resetWebView];
        _completion([navigationAction.request.URL.absoluteString stringByReplacingOccurrencesOfString:@"https://malupdaterosx.moe/?code=" withString:@""], _challenge);
    }
    else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}


- (void)resetWebView {
    // Clears WebView cookies and cache
    NSSet *websiteDataTypes;
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_12) {
        websiteDataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeDiskCache,WKWebsiteDataTypeOfflineWebApplicationCache,WKWebsiteDataTypeMemoryCache,WKWebsiteDataTypeLocalStorage,WKWebsiteDataTypeCookies,WKWebsiteDataTypeSessionStorage,WKWebsiteDataTypeIndexedDBDatabases, WKWebsiteDataTypeWebSQLDatabases]];
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
        }];
    }
    else {
        return;
    }
}



@end
