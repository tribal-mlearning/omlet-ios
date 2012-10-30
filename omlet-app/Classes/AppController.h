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

#import <Foundation/Foundation.h>
#import "LoginController.h"
#import "Framework.h"
#ifdef PHONEGAP_FRAMEWORK
    #import <PhoneGap/Reachability.h>
#else
    #import "PhoneGap/Reachability.h"
#endif

#import "DownloadContoller.h"
#import "CourseController.h"
#import "OnlineCourseController.h"
#import "MainMenuController.h"
#import <QuartzCore/QuartzCore.h>
#import "CustomPhoneGapViewController.h"
#import "SettingPreferences.h"

@protocol AppControllerDelegate <NSObject>
- (void)switchWebController:(CustomPhoneGapViewController *)webController;
- (void)clearCacheForWebView:(CustomPhoneGapViewController *)webController;
- (void)packageChanged:(NSString*)packageId;
@end


@interface AppController : NSObject<LoginControllerDelegate, 
                                    FrameworkDelegate, 
                                    UINavigationControllerDelegate,
                                    CustomPhoneGapViewControllerDelegate,
                                    CourseControllerDelegate> {
    id<AppControllerDelegate> delegate;
    LoginController *loginViewController;
    UITabBarController *tabBarController;
    UIActivityIndicatorView* activityIndicator;
    UINavigationController* courseNav;
    UINavigationController* onlineNav;
    UINavigationController* homeNav;
    UIWindow *window;
    Framework *conn;
    NSArray *code;
    Reachability *reach;
    OnlineCourseController *onlineCourses;
    MainMenuController *menu;
    CAGradientLayer *gradient;
    SettingsSyncFreq freq;
    CourseController *courseController;                                    
    SettingsData dataUse;
}

@property (nonatomic, assign) id<AppControllerDelegate> delegate;
@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, copy) NSString* downloadLocation;
@property (nonatomic, assign) NetworkStatus netStatus;
@property (nonatomic, readonly, assign) BOOL syncing;

- (BOOL)isOnlineModeActive;
- (void)loadView:(UIView *)view;
- (void)start;
- (UIViewController *)loginController;
- (UITabBarController *)tabBar;
- (MainMenuController *)mainMenu;
- (void)showIndicator:(UIActivityIndicatorViewStyle)style location:(CGPoint)point;
- (void)hideIndicator;
- (UINavigationController *)courseNavController;
- (UINavigationController *)onlineNavController;
- (BOOL)keyPIN;
- (void)performAuthenticationCheck;
- (void)syncTask:(UILocalNotification *)notif;
- (void)packageChanged:(NSString*)packageId;

@end
