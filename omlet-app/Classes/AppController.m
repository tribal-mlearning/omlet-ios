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

#import "AppController.h"
#import "DownloadContoller.h"
#import "KeyChainItemWrapper.h"
#import "SubMenuController.h"
#import "PackageInstaller.h"
#import <PhoneGap/JSONKit.h>
#import "PEBookResource.h"
#import <MediaPlayer/MediaPlayer.h> 
#import "MFPhoneGapDelegate.h"
#import "NSFileManager+DoNotBackup.h"
#import "SettingsTable.h"

#define DEFAULTKEY @"123456"
#define UNIQUEKEYCHAIN @"OMLET_"
#define ALERTNOTDOWNLOADED 1
#define ALERTLOGOUT 2
#define ALERTUNTRUSTEDCONNECTION 3
#define ALERTNOAPPFORFILETYPE 4

@interface AppController()
- (void)logout;
-(void)updateConnectionType;
- (void) updateSyncButtonVisibility;
- (void)setSyncNotifaction;
@end

@implementation AppController
@synthesize delegate, window, downloadLocation, netStatus, syncing;

NSString *pendingPackageId;
BOOL untrustedHost = NO;
UIDocumentInteractionController *docController = nil;

- (id)init {
    if (self = [super init]) {
        conn = [[Framework alloc] init];
        conn.delegate = self;
        conn.serverURL =  
            @"http://opensource-services.m-learning.net";
        conn.connectionType = HttpConnectionDataTypeHeaders;
        
        reach = [[Reachability reachabilityForInternetConnection] retain];
        [reach startNotifier];
        netStatus = [reach currentReachabilityStatus];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:
         @selector(updatedConnectionTypeNotified:) name:kReachabilityChangedNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:
        NSUserDefaultsDidChangeNotification object:nil];
        
        SettingPreferences *sP = [SettingPreferences userPreferences];
        dataUse = sP.dataUse;
    }
    return self;
}

- (void)updatedConnectionTypeNotified:(NSNotification*)note {
    Reachability* curReach = [note object];
    
    if (curReach != nil && [curReach isKindOfClass:[Reachability class]]) {
        netStatus = [curReach currentReachabilityStatus];
        [self updateConnectionType];
    }
}

-(BOOL)isOnlineModeActive{
    if (netStatus == 0 || untrustedHost == YES)
        return NO;
    else if (dataUse == SettingsDataWifiOnly && netStatus == ReachableViaWWAN)
        return NO;
    else if (dataUse == SettingsDataCellularOnly && netStatus == ReachableViaWiFi)
        return NO;
    else
        return YES;
    
    //return (netStatus != 0) && (untrustedHost != YES);
}

- (void)packageChanged:(NSString *)packageId
{
    if (delegate)
        [delegate packageChanged:packageId];
}

-(void)updateConnectionType
{    
    if (![self isOnlineModeActive])
    {
        if([AppPackageInstaller sharedInstaller].downloadingCourses.count >0)
        {
            [[AppPackageInstaller sharedInstaller] cancelDownloads];   
        }
    }
    else if (tabBarController.view.window && [self isOnlineModeActive]) {
        
        NSArray *notifs = [UIApplication sharedApplication].scheduledLocalNotifications;
        for (UILocalNotification *n in notifs) {
            if ([[n.userInfo objectForKey:@"task"] isEqualToString:@"sync"]) {
                [[UIApplication sharedApplication] cancelLocalNotification:n];
                break;
            }
        }
        
        [self setSyncNotifaction];
    } else {
        NSArray *notifs = [UIApplication sharedApplication].scheduledLocalNotifications;
        for (UILocalNotification *n in notifs) {
            if ([[n.userInfo objectForKey:@"task"] isEqualToString:@"sync"]) {
                [[UIApplication sharedApplication] cancelLocalNotification:n];
                break;
            }
        }

    }
    if (loginViewController) {
        if (![self isOnlineModeActive]) 
            loginViewController.canLogin = NO;
        else loginViewController.canLogin = YES;
    }
    
    if (onlineCourses) {
        if (![self isOnlineModeActive]) onlineCourses.canDownload = NO;
        else onlineCourses.canDownload = YES;
    }
    
    [AppPackageInstaller sharedInstaller].netStatus = netStatus;    
    [self updateSyncButtonVisibility];
    
}

- (void)start {
    if (self.keyPIN) {
        if (![self isOnlineModeActive]) { 
            [conn updateUserId:[code objectAtIndex:1] username:DEFAULTKEY password:[code objectAtIndex:0]];
            [self loadView:self.mainMenu.view];
            [self loadView:self.tabBar.view];
        } 
    } //else [self loadView:self.loginController.view];
}

-(void)performAuthenticationCheck
{
    if((code != nil && [code objectAtIndex:0]) || [self keyPIN])
    {
        if (![self isOnlineModeActive]) return;
        
        UIImageView *imgv = nil;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [self showIndicator:UIActivityIndicatorViewStyleGray location:CGPointMake(160, 240)];
        if(window && [[window subviews] count] ==0)
        {        
            UIImage *uiImg = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:
                                                                      @"Default" ofType:@"png"]];
            
            imgv = [[UIImageView alloc] initWithImage:uiImg];
            imgv.userInteractionEnabled = YES;
            [self loadView:imgv];
            [imgv.window sendSubviewToBack:imgv];
            [imgv release];
            [uiImg release];
        }
        
        //[self loadView:self.loginController.view];            
        [self authenticatePIN:[code objectAtIndex:0] onAuthenticationCompleted:
         ^(bool success, id data) {
             if (success == false) {
                 NSDictionary *result = [data objectFromJSONString];
                 
                 if([[result objectForKey:@"error"] isEqualToNumber:[NSNumber numberWithInt:NSURLErrorUserCancelledAuthentication]])
                 {
                     BOOL alreadyUntrusted = untrustedHost;
                     //Not connecting to trusted host, go into offline mode
                     untrustedHost = YES;
                                          
                     [conn updateUserId:[code objectAtIndex:1] username:DEFAULTKEY password:[code objectAtIndex:0]];
                     [self loadView:self.mainMenu.view];
                     [self loadView:self.tabBar.view];
                     
                     if(!alreadyUntrusted)
                     {
                         //Certificate is not trusted
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CertificateNotTrusted", @"") message:NSLocalizedString(@"CertificateNotTrustedDetail", @"") delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"DialogOK", @""), nil];
                         
                         alert.tag = ALERTUNTRUSTEDCONNECTION;
                         [alert show];
                         [alert release];
                     }
                 }
                 else if(![[result objectForKey:@"error"] isEqualToNumber:[NSNumber numberWithInt:NSURLErrorNotConnectedToInternet]])
                 {
                     //else user credentials no longer work....
                     [self loadView:self.loginController.view];
                 }
             }
             
             [self updateConnectionType];
             
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [self hideIndicator];
             if(imgv!=nil){
                 [imgv removeFromSuperview];
             }
         }];
    }
    else {
        [self updateConnectionType];
        
        //else user credentials no longer work....
        [self loadView:self.loginController.view];
    }
}

- (void)loadView:(UIView *)view {
    if (window) {
        if (view == self.tabBar.view && [self isOnlineModeActive]) {
            NSArray *notifs = [UIApplication sharedApplication].scheduledLocalNotifications;
            for (UILocalNotification *n in notifs) {
                if ([[n.userInfo objectForKey:@"task"] isEqualToString:@"sync"]) {
                    [[UIApplication sharedApplication] cancelLocalNotification:n];
                    break;
                }
            }
            [self setSyncNotifaction];
        }
        [window addSubview:view];
    }
}

- (void)showIndicator:(UIActivityIndicatorViewStyle)style location:(CGPoint)point {
    if (window == nil) return;
    
    if (activityIndicator == nil) {
        activityIndicator = [[delegate performSelector:@selector(activityView)] retain];
        activityIndicator.hidden = NO;
    }
    
    activityIndicator.activityIndicatorViewStyle = style;
    activityIndicator.center = point;
    if (activityIndicator.window == nil)
        [window addSubview:activityIndicator];
    
    [window bringSubviewToFront:activityIndicator];
    
    [activityIndicator startAnimating];
}

- (void)hideIndicator {
    if (activityIndicator == nil) return;
    [activityIndicator stopAnimating];
}

- (void)setKeyPIN:(NSString *)string {
    if (string == nil) {
        KeychainItemWrapper* kC = [[KeychainItemWrapper alloc] initWithIdentifier:@"MAICPDAccess" accessGroup:nil];
        [kC resetKeychainItem];
        [kC release];
        
        if (code) {
            [code release];
            code = nil;
        }
    }
    
    if (code) {
        if ([[code objectAtIndex:0] isEqualToString:string]) return;
        [code release];
        code = nil;
    }
    KeychainItemWrapper* kC = [[KeychainItemWrapper alloc] initWithIdentifier:
                               [UNIQUEKEYCHAIN stringByAppendingString:@"Access"] accessGroup:nil];
    [kC setObject:[UNIQUEKEYCHAIN stringByAppendingString:DEFAULTKEY] forKey:(id)kSecAttrAccount];
    [kC setObject:DEFAULTKEY forKey:(id)kSecAttrLabel];
    [kC setObject:[string stringByAppendingFormat:@"&%@", [conn getUserId]] forKey:(id)kSecValueData];
    [kC release];
}

- (BOOL)keyPIN {
    if (code) { 
        [code release];
        code = nil;
    }
    
    KeychainItemWrapper* kC = [[KeychainItemWrapper alloc] initWithIdentifier:[UNIQUEKEYCHAIN stringByAppendingString:@"Access"] accessGroup:nil];
    NSString *key = [kC objectForKey:(id)kSecAttrAccount];
    NSString *val = [kC objectForKey:(id)kSecValueData];
    
    if ([key isEqualToString:@""] || [val isEqualToString:@""]) {
        [kC setObject:[UNIQUEKEYCHAIN stringByAppendingString:DEFAULTKEY] forKey:(id)kSecAttrAccount];
        [kC setObject:DEFAULTKEY forKey:(id)kSecAttrLabel];
    } else if ([val isEqualToString:@""] == NO) {
        NSArray *split = [val componentsSeparatedByString:@"&"];
        if ([split count] == 2) {
            code = [split copy];
            [kC release];
            return YES;
        }
    }
    
    [kC release];
    return NO;
}

- (UITableViewController *)mainMenu {
    if (menu == nil) { 
        menu = [[MainMenuController alloc] initWithNibName:@"MainMenuController" bundle:nil];
        menu.menuItems = [NSArray arrayWithObjects:@"About", @"Sync", @"Logout", nil];        
        BOOL isVisible = [self isOnlineModeActive] && !syncing;    
        [menu setButtonEnabled:1 isEnabled:isVisible];
        menu.delegate = self;
    }
    
    return menu;

}

- (void)login {
    [loginViewController.view removeFromSuperview];
    [loginViewController release];
    loginViewController = nil;
    
    //Ensure thumbs directory for downloaded courses exists
    [[NSFileManager defaultManager] createDirectoryAtPath:[[AppPackageInstaller sharedInstaller] getThumbPath]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil]; 
    
    NSURL *backupURL = [[[NSFileManager defaultManager] URLsForDirectory:
                         NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    backupURL = [backupURL URLByAppendingPathComponent:@"backups" isDirectory:YES];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:[backupURL absoluteString] withIntermediateDirectories:YES attributes:nil error:nil];
    
    [[NSFileManager defaultManager] addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:downloadLocation]];
    [[NSFileManager defaultManager] addSkipBackupAttributeToItemAtURL:backupURL];
    
    
    
    //        [self loadView:self.mainMenu.view];
    [self loadView:self.tabBar.view];

}

- (void)mainMenuItem:(NSIndexPath *)path {
    [UIView animateWithDuration:0.5 animations:^() {
        CGRect rect = self.tabBar.view.frame;
        rect.origin.x = 0;
        self.tabBar.view.frame = rect;
    } completion:^(BOOL finished) {
        if (finished) {
            gradient.hidden = YES;
            if (path.section == 0) {
                switch (path.row) {
                    case 0:
                         [courseController showInfo];
                        break;
                    case 1:
                        [self syncTask:nil];
                        break;
                    case 2:
                       
                        [self logout];
                         break;
                    default:
                        break;
                }
            }
        }
    }];
}

- (void)logout {
    
    //Confirm if user wants to logout
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Logout Title", @"")
                                                    message:NSLocalizedString(@"Logout Message", @"")
                                                   delegate:self 
                                          cancelButtonTitle:NSLocalizedString(@"DialogCancel", @"")
                                          otherButtonTitles:NSLocalizedString(@"DialogContinue", @""), nil];
    alert.tag = ALERTLOGOUT;
    [alert show];
    [alert release];
}

-(void)performLogout{
    [self showIndicator:UIActivityIndicatorViewStyleGray location:CGPointMake(160, 240)];
    tabBarController.tabBar.userInteractionEnabled = NO;
    courseController.view.userInteractionEnabled = NO;
    courseController.navigationController.navigationBar.userInteractionEnabled = NO;
    if([AppPackageInstaller sharedInstaller].downloadingCourses.count >0)
    {
        [[AppPackageInstaller sharedInstaller] cancelDownloads];  
    }
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
//        SettingsTable *st = [SettingsTable new];
//        [st deleteAllSettings];
//        [st release];
        [menu.view removeFromSuperview];
        [menu release];
        menu = nil;
        
        NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:downloadLocation error:nil];
        
        if (files) {
            for (NSString *file in files) 
                [[NSFileManager defaultManager] removeItemAtPath:[downloadLocation stringByAppendingPathComponent:file] error:nil];
        }
        
        [delegate performSelector:@selector(clearWebCache)];
                
        files = [[NSFileManager defaultManager]
                    contentsOfDirectoryAtPath:[MFPhoneGapDelegate getBackupPath]
                                        error:nil];
        
        if (files) {
            for (NSString *file in files) 
                [[NSFileManager defaultManager] removeItemAtPath:[[MFPhoneGapDelegate getBackupPath] stringByAppendingPathComponent:file] error:nil];
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:
         [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] 
          stringByAppendingPathComponent:@"news.plist"] error:nil];    
        
        
        [PackageInstaller clearPackageList];
        [onlineCourses clearCachedData];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            tabBarController.tabBar.userInteractionEnabled = YES;
            courseController.view.userInteractionEnabled = YES;
            courseController.navigationController.navigationBar.userInteractionEnabled = YES;
            [self loadView:self.loginController.view];            
            [self setKeyPIN:nil];
            [self hideIndicator];
        });
    });
}

- (void)authenticatePIN:(NSString *)string onAuthenticationCompleted:(OnAuthenticationCompleted)block {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self showIndicator:UIActivityIndicatorViewStyleWhite location:CGPointMake(160, 240)];
    [conn login:string password:DEFAULTKEY onAuthenticationCompleted:^(bool success, id data) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self hideIndicator];
        if (block) block(success, data);
        if (success) { 
            [self setKeyPIN:string];
            [self login];
        } else 
        {   
            NSDictionary *result = [data objectFromJSONString];
            if([[result objectForKey:@"error"] isEqualToNumber:[NSNumber numberWithInt:NSURLErrorUserCancelledAuthentication]])
            {
                BOOL alreadyUntrusted = untrustedHost;
                untrustedHost = YES;
                
                if(!alreadyUntrusted)
                {
                    //Certificate is not trusted
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CertificateNotTrusted", @"") message:NSLocalizedString(@"CertificateNotTrustedDetail", @"") delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"DialogOK", @""), nil];
                    
                    alert.tag = ALERTUNTRUSTEDCONNECTION;
                    [alert show];
                    [alert release];
                }
            }
        }
    }];
}

- (UIViewController *)loginController {
    if (loginViewController == nil) {
        loginViewController = [[LoginController alloc] init];
        loginViewController.delegate = self;
        if ([self isOnlineModeActive]) loginViewController.canLogin = YES;
    }
    return loginViewController;
}

- (void)downloadOnComplete:(NSString *)location packageID:(NSString *)iD {
    if ([[courseNav topViewController] isKindOfClass:[CourseController class]]) {
        CourseController * courses = (CourseController *) [courseNav topViewController];
        [courses refresh];
    }
}

- (void)startSync:(id)sender
{
    [self syncTask:nil];
}

- (NSArray *)tabs {

    if (courseNav == nil) {
        courseController = [[CourseController alloc] init];
        courseController.delegate = self;
        courseController.tabGradient = gradient;
        courseController.mainMenu = self.mainMenu;
        courseNav = [[UINavigationController alloc] initWithRootViewController:courseController];
        courseNav.delegate = self;
        courseController.navigationItem.rightBarButtonItem.target = self;
        courseController.navigationItem.rightBarButtonItem.action = @selector(startSync:);
        courseNav.navigationBar.tintColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.6 alpha:1];        
    }
    
    if (onlineNav == nil) {
        if (onlineCourses == nil)
        {            
            onlineCourses = [[OnlineCourseController alloc] init];
            onlineCourses.navigationItem.rightBarButtonItem.target = self;
            onlineCourses.navigationItem.rightBarButtonItem.action = @selector(startSync:);
        }
        if ([self isOnlineModeActive]) onlineCourses.canDownload = YES;
      
        onlineNav = [[UINavigationController alloc] initWithRootViewController:onlineCourses];
    }
    
    [self updateSyncButtonVisibility];
    
    NSArray *tabControllers = [NSArray arrayWithObjects: courseNav, onlineNav, nil];    
    return tabControllers;
}

- (void) removeCourseData:(NSString*)packageId
{
    id webStorageContext = [delegate performSelector:@selector(webStorageContext)];
    
    if (webStorageContext != nil && [packageId isEqualToString:webStorageContext])
        [delegate performSelector:@selector(clearWebCache)];
        
    NSArray* files = [[NSFileManager defaultManager]
             contentsOfDirectoryAtPath:[MFPhoneGapDelegate getBackupPath]
             error:nil];
    
    if (files) {
        for (NSString *file in files)
        {
            if ([packageId isEqualToString:file])
            {            
                [[NSFileManager defaultManager] removeItemAtPath:[[MFPhoneGapDelegate getBackupPath] stringByAppendingPathComponent:file] error:nil];
            }
        }
    }
}

- (UINavigationController *)courseNavController {
    return courseNav;
}

- (UINavigationController *)onlineNavController {
    return onlineNav;
}

- (UITabBarController *)tabBar {
    if (tabBarController == nil) {
        tabBarController = [[UITabBarController alloc] init];
        if (gradient) [gradient release];
        gradient = [[CAGradientLayer layer] retain];
        gradient.frame = CGRectMake(0, 0, 3, 480);
        gradient.startPoint = CGPointMake(0.0, 0.5);
        gradient.endPoint = CGPointMake(1.0, 0.5);
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0] CGColor], 
                           (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0] CGColor], nil];
        gradient.hidden = YES;
        [tabBarController.view.layer insertSublayer:gradient atIndex:2];
        tabBarController.viewControllers = [self tabs];
        //tabBarController.selectedIndex = 1;
    }
    return tabBarController;
}

- (FinderPackage*) finderPacakgeFor:(NSString*)packageId
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *destinationPath = [documentsDirectory stringByAppendingFormat:@"/packages/downloads/%@/package.xml", packageId];
    if([[NSFileManager defaultManager] fileExistsAtPath:destinationPath]){
        return [[[FinderPackage alloc] initWithXML:destinationPath] autorelease];
    }
    return nil;
}

- (void)openMenu:(PEMenu *)_menu{
    
    [[Framework client] setCurrentElement:_menu];
    
    SubMenuStyle menuStyle = SubMenuStyleNormalList;
    if ([_menu.layout isEqualToString:@"minilist"]) menuStyle = SubMenuStyleMiniList;
    SubMenuController *menuController = [[SubMenuController alloc] initWithMenu:_menu andStyle:menuStyle withDescription:_menu.desc]; 
    menuController.hidesBottomBarWhenPushed = YES;
    menuController.title = _menu.title;
    
    [courseNav pushViewController:menuController animated:YES];
    [menuController release];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{  
    if ([viewController isKindOfClass:[CustomPhoneGapViewController class]])
    {
        [self.delegate switchWebController:(CustomPhoneGapViewController*)viewController];
        NSString *package = ((CustomPhoneGapViewController*)viewController).reference;
        [[Framework client] setCurrentPacakge:package];
    }
}

- (void)phoneGapControllerPopped:(CustomPhoneGapViewController *)controller
{
    [[Framework client] terminate];
    [delegate clearCacheForWebView:controller];
}

- (void) openResource:(PEResource *)resource{
    
    NSString *path = ((Framework *)[Framework client]).packagePath;
    NSString *url = [NSString stringWithFormat:@"%@/%@", path, [resource path]];
    NSLog(@"URL: %@", [NSURL  fileURLWithPath:url]);

    [[Framework client] setCurrentElement:resource];
    
    if([resource isKindOfClass:[PEBookResource class]])
    {
        NSURL *fileUrl = [NSURL fileURLWithPath:url];
        if(docController != nil)
            [docController release];
        docController = [[UIDocumentInteractionController interactionControllerWithURL:fileUrl] retain];
            
       if(![docController presentOpenInMenuFromRect:CGRectZero inView:courseNav.topViewController.view animated:YES])
       {
           //No apps available for this file, notify user
           UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FileOpenNoApp", @"")
                                                           message:[NSString stringWithFormat:NSLocalizedString(@"FileOpenNoAppDetail", @""),[fileUrl pathExtension]]
                                                          delegate:self 
                                                 cancelButtonTitle:nil
                                                 otherButtonTitles:NSLocalizedString(@"DialogOK", @""), nil];
           alert.tag = ALERTNOAPPFORFILETYPE;
           [alert show];
           [alert release];
       }        
    }
    else if ([resource isKindOfClass:[PEVideoResource class]])
    {
        NSURL *fileUrl = [NSURL fileURLWithPath:url];
        
        MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:fileUrl];
        [tabBarController presentMoviePlayerViewControllerAnimated:player];
        [player release];
    }
    else {
       
        CustomPhoneGapViewController *newWebController = [[CustomPhoneGapViewController alloc] init];
        newWebController.delegate = self;
        newWebController.hidesBottomBarWhenPushed = YES;
        
        UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        UIWebView *webview = [[UIWebView alloc] initWithFrame:view.bounds];
        webview.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [view addSubview:webview];
        newWebController.view = view;
        newWebController.webView = webview;
        
        newWebController.reference = [NSString stringWithFormat:@"%@.", [[Framework client] getCurrentPackageId]];
        newWebController.title = [[Framework client] currentPackageTitle];
                                
        [courseNav pushViewController:newWebController animated:YES];
        [newWebController.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:url]]];
        [[Framework client] initialize];
        [newWebController release];
        [webview release];
        [view release];
    }       
}

-(void) determineActionForNotDownloadedPackage:(NSString *)packageId  pacakgeName:(NSString*)packageName
{
    pendingPackageId = packageId;
    [pendingPackageId retain];

    //ask the user if they want to download the package...
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"RedirectToDownloadPackageTitle", @"") 
                                                    message:[NSString stringWithFormat:NSLocalizedString(@"RedirectToDownloadPackageMessage", @""),packageName]
                                                   delegate:self 
                                          cancelButtonTitle:NSLocalizedString(@"DialogNo", @"")
                                          otherButtonTitles:NSLocalizedString(@"DialogYes", @""), nil];
    alert.tag = ALERTNOTDOWNLOADED;
    [alert show];
    [alert release];
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(actionSheet.tag == ALERTNOTDOWNLOADED)
    {
        if(buttonIndex == 1)
        {
            //user wants to download the course
            [tabBarController setSelectedIndex:2];
            [onlineCourses navigateToDetailForCourseWithId:pendingPackageId];
        }
        else {
            //user doesn't want to download the course...
        }
        [pendingPackageId release];
        [self hideIndicator];
    }
    else if (actionSheet.tag == ALERTLOGOUT)
    {
        if(buttonIndex == 1)
        {
            [self performLogout];
        }
    }
}

- (void)defaultsChanged:(NSNotification *)notif {
    BOOL prevOnlineStatus = [self isOnlineModeActive];
    
    SettingPreferences *sP = [SettingPreferences userPreferences];
    SettingsSyncFreq sF = sP.syncFrequency;
    SettingsData sD = sP.dataUse;
 
    dataUse = sD;
    untrustedHost = NO;        
    if (prevOnlineStatus != [self isOnlineModeActive])
    {
        if ([self isOnlineModeActive])
            [self performAuthenticationCheck];
        else
            [self updateConnectionType];
    }
        
    if (freq == sF) return;
    freq = sF;
    
    
    NSArray *notifs = [UIApplication sharedApplication].scheduledLocalNotifications;
    for (UILocalNotification *n in notifs) {
        if ([[n.userInfo objectForKey:@"task"] isEqualToString:@"sync"]) {
            [[UIApplication sharedApplication] cancelLocalNotification:n];
            break;
        }
    }
    
    [self setSyncNotifaction];
}

- (void) updateSyncButtonVisibility
{  
    BOOL isVisible = [self isOnlineModeActive] && !syncing;    
    [self.mainMenu setButtonEnabled:1 isEnabled:isVisible];

    onlineCourses.navigationItem.rightBarButtonItem.enabled = isVisible;
}

- (void)syncTask:(UILocalNotification *)notif {
    if (syncing || ![self isOnlineModeActive]) return; 
    
    syncing = YES;
    [self updateSyncButtonVisibility];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [[Framework client] sync:^(bool success) {
        if (success == false) [[Framework client] notify:NSLocalizedString(@"sync error", @"")];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        syncing = NO;
        [self updateSyncButtonVisibility];
        if (notif) [self setSyncNotifaction];
    }];

}

- (void)setSyncNotifaction {
    if (freq == SettingsSyncManual) return;
    
    NSArray *notifs = [UIApplication sharedApplication].scheduledLocalNotifications;
    for (UILocalNotification *n in notifs) {
        if ([[n.userInfo objectForKey:@"task"] isEqualToString:@"sync"]) return;
    }
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    NSDate *today = [NSDate date];
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dC = [NSDateComponents new];
    if (freq == SettingsSync15Minutes) dC.minute = 15;
    else if (freq == SettingsSync10Minutes) dC.minute = 10;
    else dC.minute = 5;
    
    localNotif.fireDate = [cal dateByAddingComponents:dC toDate:today options:0];
    
    [dC release];
    [cal release];
    
    localNotif.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"sync", @"task", nil];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    [localNotif release];
}

- (void)dealloc {
    [gradient release];
    [reach release];
    [code release];
    [menu release];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:
        kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    [loginViewController release];
    [conn release];
    [homeNav release];
    [courseNav release];
    [tabBarController release];
    [courseController release];
    [onlineCourses release];
    if(docController != nil)
        [docController release];
    [super dealloc];
}

@end
