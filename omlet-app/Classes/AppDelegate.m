/*
 * Copyright (c) 2012, TATRC and Tribal
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * * Neither the name of TATRC or TRIBAL nor the
 *   names of its contributors may be used to endorse or promote products
 *   derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL TATRC OR TRIBAL BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AppDelegate.h"
#ifdef PHONEGAP_FRAMEWORK
	#import <PhoneGap/PhoneGapViewController.h>
    #import <PhoneGap/PGPlugin.h>
#else
	#import "PhoneGapViewController.h"
    #import "PhoneGap/PGPlugin.h"
#endif

#import <MediaPlayer/MPMoviePlayerViewController.h>
#import "DatabaseHandler.h"
#import "SettingPreferences.h"

@implementation AppDelegate

@synthesize invokeString;
UIDocumentInteractionController *docController;
- (id) init
{	
	/** If you need to do any extra app-specific initialization, you can do it here
	 *  -jm
	 **/
    return [super init];
}

+ (NSString *)wwwFolderName {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *www = [documentsDirectory stringByAppendingPathComponent:@"/packages/downloads/"];
    return www;
}

/**
 * This is main kick off after the app inits, the views and Settings are setup here. (preferred - iOS4 and up)
 */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    BOOL ret = [super application:application didFinishLaunchingWithOptions:launchOptions];
    if (ret) {
//        [NSClassFromString(@"WebView") _enableRemoteInspector];

        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"wasSetup"]){
            [[DatabaseHandler shared] runScript:@"Tables.sql"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"wasSetup"];
        }
                
        pluginObjectsByWebView = [[NSMutableDictionary alloc] init];
        
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        [[SettingPreferences userPreferences] setVersion:[info objectForKey:@"CFBundleVersion"]];

        [self.viewController.view removeFromSuperview];
        appController = [[AppController alloc] init];
        appController.delegate = self;
        appController.window = self.window;
        appController.downloadLocation = [AppDelegate wwwFolderName];
        [appController start];
    }
    
	return ret;
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
    [appController performAuthenticationCheck];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if ([[notification.userInfo objectForKey:@"task"] isEqualToString:@"sync"]) {
        [appController syncTask:notification];
    }
}

// this happens while we are running ( in the background, or from within our own app )
// only valid if omlet-Info.plist specifies a protocol to handle
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url 
{
    // must call super so all plugins will get the notification, and their handlers will be called 
	// super also calls into javascript global function 'handleOpenURL'
    return [super application:application handleOpenURL:url];
}

- (void)clearCacheForWebView:(CustomPhoneGapViewController *)webController
{
    //previously was removing the plugins here, but phonegap send messages to them when the app is closing.
    //NSString *controllerName = currentWebController.name;    
    //if (controllerName)
    //    [pluginObjectsByWebView removeObjectForKey:controllerName];  
    
    //a phonegap controller got popped off the stack   
    //and we're going back to an existing controller (if we were going back to the main menu, these two would be the same)
    if (currentWebController != webController)
    {
        //need to make sure phonegap command queue is clean
        [currentWebController.webView stringByEvaluatingJavaScriptFromString:@"PhoneGap.commandQueueFlushing = false"];
    }
    else
    {
        [self backupCurrentContext:NO];
    }
}

- (void)switchWebController:(CustomPhoneGapViewController *)webController
{
    if (currentWebController != webController)
    {        
        [currentWebController release];
        
        if (webController)
        {  
            currentWebController = [webController retain];            
            self.webView = currentWebController.webView;
            self.webView.delegate = self;
            self.viewController.webView = self.webView;
        }
        else
        {
            currentWebController = nil;
            self.webView = nil;
        }
    }
}

- (void)packageChanged:(NSString *)packageId
{
    [self backupToNewStorageContext:packageId];
}

-(id) getCommandInstance:(NSString*)pluginName
{
	/** You can catch your own commands here, if you wanted to extend the gap: protocol, or add your
	 *  own app specific protocol to it. -jm
	 **/
	//return [super getCommandInstance:className];
    
    NSString* className = [self.pluginsMap objectForKey:[pluginName lowercaseString]];
    if (className == nil) {
        return nil;
    }
    
    NSString *controllerName = currentWebController.name;
    
    if (!controllerName)
        controllerName = @"default";
    
    NSMutableDictionary *plugins = [pluginObjectsByWebView objectForKey:controllerName];
    if (!plugins) {
        plugins = [[[NSMutableDictionary alloc] init] autorelease];
        [pluginObjectsByWebView setObject:plugins forKey:controllerName];
    }
    
    PGPlugin *obj = [plugins objectForKey:className];
    if (!obj) {
        // attempt to load the settings for this command class
        NSDictionary* classSettings = [self.settings objectForKey:className];
        
        if (classSettings) {
            obj = [[NSClassFromString(className) alloc] initWithWebView:self.webView settings:classSettings];
        } else {
            obj = [[NSClassFromString(className) alloc] initWithWebView:self.webView];
        }
        
        if (obj != nil) {
            [plugins setObject:obj forKey:className];
            [obj release];
        } else {
            NSLog(@"PGPlugin class %@ (pluginName: %@) does not exist.", className, pluginName);
        }
    }
    return obj;
}

/**
 Called when the webview finishes loading.  This stops the activity view and closes the imageview
 */
- (void)webViewDidFinishLoad:(UIWebView *)theWebView 
{
	// only valid if omlet-Info.plist specifies a protocol to handle
	if(self.invokeString)
	{
		// this is passed before the deviceready event is fired, so you can access it in js when you receive deviceready
		NSString* jsString = [NSString stringWithFormat:@"var invokeString = \"%@\";", self.invokeString];
		[theWebView stringByEvaluatingJavaScriptFromString:jsString];
	}
   	 // Black base color for background matches the native apps
   	theWebView.backgroundColor = [UIColor blackColor];
    [appController hideIndicator];
	return [ super webViewDidFinishLoad:theWebView ];
}

- (void)webViewDidStartLoad:(UIWebView *)theWebView 
{
	if ([self.activityView isAnimating] == NO)
        [appController showIndicator:UIActivityIndicatorViewStyleGray location:CGPointMake(160, 240)];
    return [ super webViewDidStartLoad:theWebView ];
}

/**
 * Fail Loading With Error
 * Error - If the webpage failed to load display an error with the reason.
 */
- (void)webView:(UIWebView *)theWebView didFailLoadWithError:(NSError *)error 
{
	return [ super webView:theWebView didFailLoadWithError:error ];
}

/**
 * Start Loading Request
 * This is where most of the magic happens... We take the request(s) and process the response.
 * From here we can redirect links and other protocols to different internal methods.
 */
- (BOOL)webView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"Request: %@", [[request URL] absoluteString]);
    NSString *url = [[request URL] absoluteString];
    
    if ([url rangeOfString:@"http://"].location == 0) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    
	if ([[url pathExtension] isEqualToString:@"mp4"]) {
        MPMoviePlayerViewController *mvc = [[MPMoviePlayerViewController alloc] initWithContentURL:[request URL]];
        [currentWebController presentMoviePlayerViewControllerAnimated:mvc];
        [mvc release];
        return NO;
    }
    else if([[url pathExtension] isEqualToString:@"epub"] || [[url pathExtension] isEqualToString:@"mobi"] || [[url pathExtension] isEqualToString:@"pdf"])
    {
        if(docController)
            [docController release];
        docController = [[UIDocumentInteractionController interactionControllerWithURL:[request URL]] retain];
        
        if([docController presentOpenInMenuFromRect:CGRectZero inView:self.viewController.view animated:YES])
        {
            return NO;
        }
    }
    return [ super webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType ];
}


- (BOOL) execute:(InvokedUrlCommand*)command
{
	return [ super execute:command];
}

- (void)dealloc
{
	[appController release];
    if(docController)
        [docController release];
    [pluginObjectsByWebView release];
    [currentWebController release];
    [ super dealloc ];    
}

@end
