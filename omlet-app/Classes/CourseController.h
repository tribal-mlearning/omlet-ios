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

#import <UIKit/UIKit.h>
#ifdef PHONEGAP_FRAMEWORK
#import <PhoneGap/PhoneGapViewController.h>
#else
#import "PhoneGapViewController.h"
#endif

#import <QuartzCore/QuartzCore.h>
#import "MainMenuController.h"

@protocol CourseControllerDelegate <NSObject>
- (void) removeCourseData:(NSString*)packageId;
@end

@interface CourseController : UITableViewController {
    NSString *downloadsLocation;
    NSMutableArray *courses;
    NSMutableArray *images;
    BOOL tabBarHidden;
}

- (void) refresh;

@property (retain, nonatomic) IBOutlet UIView *infoView;
@property (retain, nonatomic) IBOutlet UILabel *versionInfo;
@property (retain, nonatomic) IBOutlet UIScrollView *cnView;
@property (nonatomic, assign) id<CourseControllerDelegate> delegate;
@property (nonatomic, retain) MainMenuController *mainMenu;
@property (nonatomic, retain) CAGradientLayer *tabGradient;

- (void)showInfo;
- (IBAction)closeInfo:(id)sender;

@end
