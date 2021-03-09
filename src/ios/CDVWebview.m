    /*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVWebview.h"
#import <Cordova/CDVPluginResult.h>
#import <Cordova/CDVUserAgentUtil.h>
#import <foundation/foundation.h>

#define    kInAppBrowserTargetSelf @"_self"
#define    kInAppBrowserTargetSystem @"_system"
#define    kInAppBrowserTargetBlank @"_blank"

#define    kInAppBrowserToolbarBarPositionBottom @"bottom"
#define    kInAppBrowserToolbarBarPositionTop @"top"

#define    TOOLBAR_HEIGHT 44.0
#define    LOCATIONBAR_HEIGHT 21.0
#define    FOOTER_HEIGHT ((TOOLBAR_HEIGHT) + (LOCATIONBAR_HEIGHT))

#pragma mark CDVInAppBrowser

@interface CDVEmbeddedWebView () {
    NSInteger _previousStatusBarStyle;
}
@end

@implementation CDVEmbeddedWebView

- (void)pluginInitialize
{
    _previousStatusBarStyle = -1;
    _callbackIdPattern = nil;
   
    _brw = [NSMutableArray array];
   
//    for (int i=0;i<6;i++){
//        [_brw addObject:[[CDVEmbeddedWebViewPlug alloc]init]];
//    }
}

- (void)getCookie:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    NSMutableDictionary* webviewProperties = [self.brw objectAtIndex:i.intValue];
    WKWebView* webview = [webviewProperties objectForKey:@"webview"];
    WKHTTPCookieStore *cookieStore = webview.configuration.websiteDataStore.httpCookieStore;
    [cookieStore getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
        NSString* str = @"";
        for (NSHTTPCookie *cookie in cookies)
        {
            str = [str stringByAppendingString:cookie.name];
            str = [str stringByAppendingString:@"="];
            str = [str stringByAppendingString:cookie.value];
            str = [str stringByAppendingString:@";"];
        }
        self.callbackId = command.callbackId;
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:str];
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    }];
}

- (void)open:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    NSString* i = [command argumentAtIndex:0];
    NSString* url = [command argumentAtIndex:1];
    NSString* options = [command argumentAtIndex:2 withDefault:@"" andClass:[NSString class]];
    
    if (url != nil) {
#ifdef __CORDOVA_4_0_0
        NSURL* baseUrl = [self.webViewEngine URL];
#else
        NSURL* baseUrl = [self.webView.request URL];
#endif
        NSURL* absoluteUrl = [[NSURL URLWithString:url relativeToURL:baseUrl] absoluteURL];
        
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        
        //[self openInWebPlug:absoluteUrl withOptions:options];
        [self openInWebPlug:absoluteUrl index:i withOptions:options];
        
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"incorrect number of arguments"];
    }
    
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    self.callbackId = command.callbackId;
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)load:(CDVInvokedUrlCommand*)command
{
    
    NSString* i = [command argumentAtIndex:0];
    NSString* url = [command argumentAtIndex:1];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    
    //if (self.webplug == nil) {
    if (el == nil) {
        NSLog(@"Tried to show IAB after it was closed. Load");
        return;
    }
    if (url != nil) {
#ifdef __CORDOVA_4_0_0
        NSURL* baseUrl = [self.webViewEngine URL];
#else
        NSURL* baseUrl = [self.webView.request URL];
#endif
        NSURL* absoluteUrl = [[NSURL URLWithString:url relativeToURL:baseUrl] absoluteURL];
        
        //[self.webplug navigateTo:absoluteUrl];
        
        
        [el navigateTo:absoluteUrl];
        
    }
    // else {
    //     pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"incorrect number of arguments"];
    // }
}

- (void)close:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    //if (self.webplug == nil) {
   if (el == nil) {
        NSLog(@"Tried to close IAB after it was closed.");
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self.webplug removeFromSuperview];
        //self.webplug = nil;
        CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
        [el removeFromSuperview];
        el = nil;
    });
}

- (void)show:(CDVInvokedUrlCommand*)command
{
 NSString* i = [command argumentAtIndex:0];
    NSMutableDictionary* webviewProperties = [self.brw objectAtIndex:i.intValue];
    WKWebView* webview = [webviewProperties objectForKey:@"webview"];
    //if (self.webplug == nil) {
    if (webview == nil) {
        NSLog(@"Tried to hide IAB after it was closed.");
        return;
    }
    //self.webplug.hidden = No;
    webview.hidden = NO;
}


- (void)hide:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    NSMutableDictionary* webviewProperties = [self.brw objectAtIndex:i.intValue];
    WKWebView* webview = [webviewProperties objectForKey:@"webview"];
    //if (self.webplug == nil) {
    if (webview == nil) {
        NSLog(@"Tried to hide IAB after it was closed.");
        return;
    }
    //self.webplug.hidden = YES;
    webview.hidden = YES;
}

- (void)getStateLoading:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    NSMutableDictionary* webviewProperties = [self.brw objectAtIndex:i.intValue];
    id state = [webviewProperties objectForKey:@"loading"];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK  messageAsString:state];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)openURL:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    NSString* url = [command argumentAtIndex:1];
    NSMutableDictionary* webviewProperties = [self.brw objectAtIndex:i.intValue];
    WKWebView* webview = [webviewProperties objectForKey:@"webview"];
    
    NSURL* absoluteUrl = [NSURL URLWithString:url];
    
    NSURLRequest* request = [NSURLRequest requestWithURL:absoluteUrl];
    
    [webviewProperties setValue:[NSNumber numberWithBool:YES] forKey:@"loading"];
    
    [webview loadRequest:request];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK  messageAsString:@""];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setPosition:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    //if (self.webplug == nil) {
    if (el == nil) {
        NSLog(@"Tried to show IAB after it was closed.Set Position");
        return;
    }
    
    if (command.arguments.count < 3) {
        NSLog(@"Parameters is not long enough.");
        return;
    }
    
    NSString* sl = [command argumentAtIndex:1];
    NSString* st = [command argumentAtIndex:2];
    
    float fl = [sl floatValue];
    float ft = [st floatValue];
    
    //CGRect frame = self.webplug.frame;
    CGRect frame = el.frame;
    frame.origin.x = fl;
    frame.origin.y = ft;
    //self.webplug.frame = frame;
    el.frame = frame;
}

- (void)setSize:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    //if (self.webplug == nil) {
    if (el == nil) {
        NSLog(@"Tried to show IAB after it was closed.");
        return;
    }
    if (command.arguments.count < 3) {
        NSLog(@"Parameters is not long enough.");
        return;
    }
    
    NSString* sw = [command argumentAtIndex:1];
    NSString* sh = [command argumentAtIndex:2];
    
    float fw = [sw floatValue];
    float fh = [sh floatValue];
    
    //CGRect frame = self.webplug.frame;
    CGRect frame = el.frame;
    frame.size.width = fw;
    frame.size.height = fh;
    //self.webplug.frame = frame;
    el.frame = frame;
}

- (void)openInWebPlug:(NSURL*)url index:(NSString*)i withOptions:(NSString*)options
{
//    CDVEmbeddedWebViewPlug* el = [self.brw objectAtIndex:i.intValue];
    CDVWebviewOptions* browserOptions = [CDVWebviewOptions parseOptions:options];
//
//    if (browserOptions.clearcache) {
//        NSHTTPCookie *cookie;
//        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//        for (cookie in [storage cookies])
//        {
//            if (![cookie.domain isEqual: @".^filecookies^"]) {
//                [storage deleteCookie:cookie];
//            }
//        }
//    }
//
//    if (browserOptions.clearsessioncache) {
//        NSHTTPCookie *cookie;
//        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//        for (cookie in [storage cookies])
//        {
//            if (![cookie.domain isEqual: @".^filecookies^"] && cookie.isSessionOnly) {
//                [storage deleteCookie:cookie];
//            }
//        }
//    }
//
//    //if (self.webplug == nil) {
//    if (el == nil) {
//        NSString* originalUA = [CDVUserAgentUtil originalUserAgent];
//
//        el = [[CDVEmbeddedWebViewPlug alloc] initWithUserAgent:originalUA prevUserAgent:[self.commandDelegate userAgent] browserOptions:browserOptions];
//        //self.webplug.navigationDelegate = self;
//        el.navigationDelegate =self;
//    }
//
//
//    // prevent webView from bouncing
//    if (browserOptions.disallowoverscroll) {
//        /*if ([self.webplug respondsToSelector:@selector(scrollView)]) {
//            ((UIScrollView*)[self.webplug scrollView]).bounces = NO;
//        } else {
//            for (id subview in self.webplug.subviews) {
//                if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
//                    ((UIScrollView*)subview).bounces = NO;
//                }
//            }
//        }*/
//        if ([el respondsToSelector:@selector(scrollView)]) {
//            ((UIScrollView*)[el scrollView]).bounces = NO;
//        } else {
//            for (id subview in el.subviews) {
//                if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
//                    ((UIScrollView*)subview).bounces = NO;
//                }
//            }
//        }
//
//    }
    
    
    
    // UIWebView options
//    el.scalesPageToFit = browserOptions.enableviewportscale;
//    el.mediaPlaybackRequiresUserAction = browserOptions.mediaplaybackrequiresuseraction;
//    el.allowsInlineMediaPlayback = browserOptions.allowinlinemediaplayback;
//    if (IsAtLeastiOSVersion(@"6.0")) {
//        el.keyboardDisplayRequiresUserAction = browserOptions.keyboarddisplayrequiresuseraction;
//        el.suppressesIncrementalRendering = browserOptions.suppressesincrementalrendering;
//    }
    
    WKWebViewConfiguration* configurationB = [[WKWebViewConfiguration alloc] init];
    
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    [userContentController addScriptMessageHandler:self name:@"showMessage"];
    configurationB.userContentController = userContentController;
    
    WKWebsiteDataStore *websiteDataStoreB = [WKWebsiteDataStore nonPersistentDataStore];
    configurationB.websiteDataStore = websiteDataStoreB;
    
    WKWebView* webView2 = [[WKWebView alloc] initWithFrame:CGRectMake(browserOptions.left.floatValue,  browserOptions.top.floatValue, browserOptions.width.floatValue, browserOptions.height.floatValue) configuration:configurationB];
    [UIApplication.sharedApplication.keyWindow addSubview:webView2];
    webView2.navigationDelegate = self;
    
    NSMutableDictionary* webviewProperties = [NSMutableDictionary dictionary];
    [webviewProperties setObject:webView2 forKey:@"webview"];
    [webviewProperties setObject:[NSNumber numberWithBool:YES] forKey:@"loading"];
    [self.brw addObject:webviewProperties];
    
    WKHTTPCookieStore *cookieStore = webView2.configuration.websiteDataStore.httpCookieStore;
    NSMutableDictionary* cookieProperties = [NSMutableDictionary dictionary];
    
    // set cookie to browser
    NSString *jsonCookie = browserOptions.cookie;
    NSData* jsonData = [jsonCookie dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonError;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONWritingPrettyPrinted error:&jsonError];
    for (NSString *cookieName in [jsonObject allKeys]) {
        NSString* cookieValue = [jsonObject objectForKey:cookieName];
        //set rest of the properties
        [cookieProperties setObject:cookieName forKey:NSHTTPCookieName];
        [cookieProperties setObject:cookieValue forKey:NSHTTPCookieValue];
        [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
        [cookieProperties setObject:@".facebook.com" forKey:NSHTTPCookieDomain];
        //create a NSDate for some future time
        NSDate* expiryDate = [[NSDate date] dateByAddingTimeInterval:2629743];
        [cookieProperties setObject:expiryDate forKey:NSHTTPCookieExpires];
        [cookieProperties setObject:@"TRUE" forKey:NSHTTPCookieSecure];

        NSHTTPCookie *cookie1 = [NSHTTPCookie cookieWithProperties:cookieProperties];
        [cookieStore setCookie:cookie1 completionHandler:^{
            
        }];
    }
    
    
    
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [webView2 loadRequest:request];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [webView2 removeFromSuperview];
        webView2.hidden = NO;
        [self.webView.superview addSubview:webView2];
        [self.webView.superview bringSubviewToFront:webView2];
    });

    
    
    
}



// Image from uiwebview
- (UIImage *) imageFromWebView:(UIWebView *)view
{
    // tempframe to reset view size after image was created
    CGRect tmpFrame         = view.frame;

    // set new Frame
    CGRect aFrame               = view.frame;
    aFrame.size.height  = [view sizeThatFits:[[UIScreen mainScreen] bounds].size].height;
    view.frame              = aFrame;

    // do image magic
    UIGraphicsBeginImageContext([view sizeThatFits:[[UIScreen mainScreen] bounds].size]);

    CGContextRef resizedContext = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:resizedContext];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    // reset Frame of view to origin
    view.frame = tmpFrame;
    return image;
}

- (void)getScreenshot:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    NSString* i = [command argumentAtIndex:0];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    NSString *encodedString = @"";

    //if (self.webplug == nil) {
    if (el == nil) {
    }
    else {
        float fq = 1;
        if (command.arguments.count < 2) {
            NSString* sq = [command argumentAtIndex:1];
            fq = [sq floatValue];
        }

        //UIImage* image = [self imageFromWebView:self.webplug];
        UIImage* image = [self imageFromWebView:el];
        NSData *imageData = UIImageJPEGRepresentation(image, fq);
        encodedString = [imageData base64Encoding];
    }

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK  messageAsString:encodedString];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
- (void)hasHistory:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    NSString* i = [command argumentAtIndex:0];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    NSString *ret = @"0";
    
    //if (self.webplug == nil) {
    if (el == nil) {
    }
    else {
        if ([el canGoBack]) {
            ret=@"1";
        }
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK  messageAsString:ret];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
- (void)goBack:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    
    if ([el canGoBack]) {
        [el goBack];
    }
}

// This is a helper method for the inject{Script|Style}{Code|File} API calls, which
// provides a consistent method for injecting JavaScript code into the document.
//
// If a wrapper string is supplied, then the source string will be JSON-encoded (adding
// quotes) and wrapped using string formatting. (The wrapper string should have a single
// '%@' marker).
//
// If no wrapper is supplied, then the source string is executed directly.

- (void)injectDeferredObject:(NSString*)source index:(NSString*) i withWrapper:(NSString*)jsWrapper withCallbackId:(NSString*)callbackId
{
    __block NSString *resultString = nil;
    __block BOOL finished = NO;
    NSMutableDictionary* webviewProperties = [self.brw objectAtIndex:i.intValue];
    WKWebView* webview = [webviewProperties objectForKey:@"webview"];
    [webview evaluateJavaScript:source completionHandler:^(id result, NSError *error) {
        if (error == nil) {
            if (result != nil) {
                resultString = [NSString stringWithFormat:@"%@", result];
            }
            CDVPluginResult* result1 = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@""];
            [self.commandDelegate sendPluginResult:result1 callbackId:callbackId];
        } else {
            NSLog(@"evaluateJavaScript error : %@", error.localizedDescription);
            CDVPluginResult* result1 = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@""];
            [self.commandDelegate sendPluginResult:result1 callbackId:callbackId];
        }
        finished = YES;
    }];
//    if (!_injectedIframeBridge) {
//        _injectedIframeBridge = YES;
//        // Create an iframe bridge in the new document to communicate with the CDVInAppBrowserViewController
//        [el stringByEvaluatingJavaScriptFromString:@"(function(d){var e = _cdvIframeBridge = d.createElement('iframe');e.style.display='none';d.body.appendChild(e);})(document)"];
//    }
//
//    if (jsWrapper != nil) {
//        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:@[source] options:0 error:nil];
//        NSString* sourceArrayString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//        if (sourceArrayString) {
//            NSString* sourceString = [sourceArrayString substringWithRange:NSMakeRange(1, [sourceArrayString length] - 2)];
//            NSString* jsToInject = [NSString stringWithFormat:jsWrapper, sourceString];
//            [el stringByEvaluatingJavaScriptFromString:jsToInject];
//        }
//    } else {
//        [el stringByEvaluatingJavaScriptFromString:source];
//    }
}

-(void)saveDataInNSDefault:(id)object key:(NSString *)key{
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:encodedObject forKey:key];
    [defaults synchronize];
}

-(id)getDataFromNSDefaultWithKey:(NSString *)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedObject = [defaults objectForKey:key];
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
    return object;
}

- (void)onMessage:(CDVInvokedUrlCommand*)command
{
    self.commandIdHandleMessage = command.callbackId;
}

- (void)saveDataStore:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    NSMutableDictionary* webviewProperties = [self.brw objectAtIndex:i.intValue];
    WKWebView* webview = [webviewProperties objectForKey:@"webview"];
    WKWebsiteDataStore *websiteDataStore = webview.configuration.websiteDataStore;
    [self saveDataInNSDefault:websiteDataStore key:@"datastore1"];
}

- (void)injectScriptCode:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper = nil;
    NSString* i = [command argumentAtIndex:0];
    
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"_cdvIframeBridge.src='gap-iab://%@/'+encodeURIComponent(JSON.stringify([eval(%%@)]));", command.callbackId];
    }
    [self injectDeferredObject:[command argumentAtIndex:1] index:i withWrapper:jsWrapper withCallbackId:command.callbackId];
}

- (void)injectScriptFile:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    NSString* i = [command argumentAtIndex:0];
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('script'); c.src = %%@; c.onload = function() { _cdvIframeBridge.src='gap-iab://%@'; }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('script'); c.src = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] index:i withWrapper:jsWrapper withCallbackId:command.callbackId];
}

- (void)injectStyleCode:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    NSString* i = [command argumentAtIndex:0];
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('style'); c.innerHTML = %%@; c.onload = function() { _cdvIframeBridge.src='gap-iab://%@'; }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('style'); c.innerHTML = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] index:i withWrapper:jsWrapper withCallbackId:command.callbackId];
}

- (void)injectStyleFile:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    NSString* i = [command argumentAtIndex:0];
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('link'); c.rel='stylesheet'; c.type='text/css'; c.href = %%@; c.onload = function() { _cdvIframeBridge.src='gap-iab://%@'; }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('link'); c.rel='stylesheet', c.type='text/css'; c.href = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] index:i withWrapper:jsWrapper withCallbackId:command.callbackId];
}

- (BOOL)isValidCallbackId:(NSString *)callbackId
{
    NSError *err = nil;
    // Initialize on first use
    if (self.callbackIdPattern == nil) {
        self.callbackIdPattern = [NSRegularExpression regularExpressionWithPattern:@"^InAppBrowser[0-9]{1,10}$" options:0 error:&err];
        if (err != nil) {
            // Couldn't initialize Regex; No is safer than Yes.
            return NO;
        }
    }
    if ([self.callbackIdPattern firstMatchInString:callbackId options:0 range:NSMakeRange(0, [callbackId length])]) {
        return YES;
    }
    return NO;
}

- (void)didFinishNavigation:(WKWebView*)theWebView
{
    for (NSMutableDictionary* webviewProperties in self.brw) {
        WKWebView* webview = [webviewProperties objectForKey:@"webview"];
        if ([webview isEqual:theWebView]) {
            [webviewProperties setValue:[NSNumber numberWithBool:NO] forKey:@"loading"];
        }
    }
    
    NSString* url = [theWebView.URL absoluteString];
    if(url == nil){
        url = @"";
    }
        
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    CDVPluginResult* result1 = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message.body];
    [result1 setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result1 callbackId:self.commandIdHandleMessage];
}

#pragma mark WKNavigationDelegate
- (void)webView:(WKWebView *)theWebView didStartProvisionalNavigation:(WKNavigation *)navigation{
    NSLog(@"didStartProvisionalNavigation");
}

- (void)webView:(WKWebView *)theWebView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSLog(@"decidePolicyForNavigationAction");
    for (NSMutableDictionary* webviewProperties in self.brw) {
        WKWebView* webview = [webviewProperties objectForKey:@"webview"];
        if ([webview isEqual:theWebView]) {
            [webviewProperties setValue:[NSNumber numberWithBool:YES] forKey:@"loading"];
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
    
}

- (void)webView:(WKWebView *)theWebView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"didFinishNavigation");
    [self didFinishNavigation:theWebView];
}
    
- (void)webView:(WKWebView*)theWebView failedNavigation:(NSString*) delegateName withError:(nonnull NSError *)error{
    // log fail message, stop spinner, update back/forward
    NSLog(@"failedNavigation");
}

- (void)webView:(WKWebView*)theWebView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error
{
    [self webView:theWebView failedNavigation:@"didFailNavigation" withError:error];
}
    
- (void)webView:(WKWebView*)theWebView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error
{
    [self webView:theWebView failedNavigation:@"didFailProvisionalNavigation" withError:error];
}

@end


@implementation CDVWebviewOptions

- (id)init
{
    if (self = [super init]) {
        // default values
        self.location = YES;
        self.toolbar = YES;
        self.closebuttoncaption = nil;
        self.toolbarposition = kInAppBrowserToolbarBarPositionBottom;
        self.clearcache = NO;
        self.clearsessioncache = NO;

        self.enableviewportscale = NO;
        self.mediaplaybackrequiresuseraction = NO;
        self.allowinlinemediaplayback = NO;
        self.keyboarddisplayrequiresuseraction = YES;
        self.suppressesincrementalrendering = NO;
        self.hidden = NO;
        self.disallowoverscroll = NO;
    }

    return self;
}

+ (CDVWebviewOptions*)parseOptions:(NSString*)options
{
    CDVWebviewOptions* obj = [[CDVWebviewOptions alloc] init];

    // NOTE: this parsing does not handle quotes within values
    NSArray* pairs = [options componentsSeparatedByString:@"|"];

    // parse keys and values, set the properties
    for (NSString* pair in pairs) {
        NSArray* keyvalue = [pair componentsSeparatedByString:@"="];

        if ([keyvalue count] == 2) {
            NSString* key = [[keyvalue objectAtIndex:0] lowercaseString];
            NSString* value = [keyvalue objectAtIndex:1];
            NSString* value_lc = [value lowercaseString];

            BOOL isBoolean = [value_lc isEqualToString:@"yes"] || [value_lc isEqualToString:@"no"];
            NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setAllowsFloats:YES];
            BOOL isNumber = [numberFormatter numberFromString:value_lc] != nil;

            // set the property according to the key name
            if ([obj respondsToSelector:NSSelectorFromString(key)]) {
                if (isNumber) {
                    [obj setValue:[numberFormatter numberFromString:value_lc] forKey:key];
                } else if (isBoolean) {
                    [obj setValue:[NSNumber numberWithBool:[value_lc isEqualToString:@"yes"]] forKey:key];
                } else {
                    [obj setValue:value forKey:key];
                }
            }
        }
    }

    return obj;
}

@end


@implementation CDVEmbeddedWebViewPlug

@synthesize currentURL;

- (id)initWithUserAgent:(NSString*)userAgent prevUserAgent:(NSString*)prevUserAgent browserOptions: (CDVWebviewOptions*) browserOptions
{
    self = [super init];
    if (self != nil) {
        _userAgent = userAgent;
        _prevUserAgent = prevUserAgent;
        _browserOptions = browserOptions;
#ifdef __CORDOVA_4_0_0
        _webViewDelegate = [[CDVUIWebViewDelegate alloc] initWithDelegate:self];
#else
        _webViewDelegate = [[CDVWebViewDelegate alloc] initWithDelegate:self];
#endif
        
        self.delegate = _webViewDelegate;
        self.backgroundColor = [UIColor whiteColor];
        
        self.clearsContextBeforeDrawing = YES;
        self.clipsToBounds = YES;
        self.contentMode = UIViewContentModeScaleToFill;
        self.multipleTouchEnabled = YES;
        self.opaque = YES;
        self.scalesPageToFit = NO;
        self.userInteractionEnabled = YES;
    }
    
    return self;
}

- (void)navigateTo:(NSURL*)url
{
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    //if (_userAgentLockToken != 0)
    //{
        [self loadRequest:request];
    //}
    // else
    // {
    //     [CDVUserAgentUtil acquireLock:^(NSInteger lockToken) {
    //         _userAgentLockToken = lockToken;
    //         [CDVUserAgentUtil setUserAgent:_userAgent lockToken:lockToken];
    //         [self loadRequest:request];
    //     }];
    // }
}

@end
