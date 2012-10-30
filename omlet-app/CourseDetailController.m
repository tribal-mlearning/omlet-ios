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

#import "CourseDetailController.h"
#import "AppPackageInstaller.h"
#import <QuartzCore/QuartzCore.h>

@implementation CourseDetailController

@synthesize course;
@synthesize imageData = _imageData;
@synthesize courseSize, canDownload;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        //download status
        downloadButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];        
        [downloadButton setTitle:@"DOWNLOAD" forState:UIControlStateNormal];
        [downloadButton addTarget:self action:@selector(beginDownload:) forControlEvents:UIControlEventTouchUpInside];
        
        stateLabel = [[UILabel alloc] init];  
        downloadButton.titleLabel.font = [UIFont systemFontOfSize:9]; 
        stateLabel.textColor = [UIColor grayColor];
        stateLabel.numberOfLines = 0;    
        stateLabel.lineBreakMode = UILineBreakModeWordWrap;
        stateLabel.font = [UIFont systemFontOfSize:14];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(downloadItemStatusChanged:)
                                                     name:@"DownloadStatusChanged"
                                                   object:nil ];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)downloadItemStatusChanged: (NSNotification *) notification
{
    NSDictionary *courseInf = (NSDictionary*)notification.object;
    NSDictionary *c = [courseInf objectForKey:@"course"];
    
    if([c objectForKey:@"uniqueId"] == [course objectForKey:@"uniqueId"]){
        PackageState packageState = [[AppPackageInstaller sharedInstaller] getPackageState:course];
        [self setState:packageState];
    }
}

#pragma mark - View lifecycle

- (CGSize) fitLabel:(UILabel *) label withWidth:(CGFloat)width x:(CGFloat)x y:(CGFloat)y
{
    CGSize size = [label.text sizeWithFont:label.font 
                         constrainedToSize:CGSizeMake(width, 16*1000.f) 
                             lineBreakMode:UILineBreakModeWordWrap];
    
    label.frame = CGRectMake(x, y, width, size.height);
    
    return size;
}

- (NSString *)getRootPackagePath
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *www = [documentsDirectory stringByAppendingPathComponent:@"/packages/downloads/"];    
    return www;
}

-(void)animateText:(NSString *)text startX:(NSUInteger)x startY:(NSUInteger)y
{
    if (animationLabel)
    {
        [animationLabel release];
        animationLabel = nil;
    }
    
    animationLabel = [[UILabel alloc] init];
    animationLabel.text = text;
    animationLabel.font = [UIFont systemFontOfSize:10];
    [self.view addSubview:animationLabel];
    
    
    CGSize size = [animationLabel.text sizeWithFont:animationLabel.font 
                                          constrainedToSize:CGSizeMake(16*1000.f, 16*1000.f) 
                                              lineBreakMode:UILineBreakModeWordWrap];
    
    CGPoint startPoint = CGPointMake(x, y);
    animationLabel.frame = CGRectMake(startPoint.x, startPoint.y, MIN(size.width, 150), size.height);
    
    int width = animationLabel.frame.size.width;
    int height = animationLabel.frame.size.height;
    
    [CATransaction begin];
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.calculationMode = kCAAnimationCubic;
    pathAnimation.fillMode = kCAFillModeForwards;
    pathAnimation.duration = 0.5;
    
    CGPoint endPoint = CGPointMake(self.view.bounds.size.width - (width / 2),
                                   self.view.bounds.size.height - (height / 2));
    
    CGMutablePathRef curvedPath = CGPathCreateMutable();
    CGPathMoveToPoint(curvedPath, NULL, startPoint.x, startPoint.y);
    CGPathAddCurveToPoint(curvedPath, NULL, endPoint.x, startPoint.y, endPoint.x, startPoint.y, endPoint.x, endPoint.y);
    pathAnimation.path = curvedPath;
    CGPathRelease(curvedPath);
    pathAnimation.delegate = self;
    
    [[animationLabel layer] addAnimation:pathAnimation forKey:@"position"];
    [CATransaction commit];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [animationLabel removeFromSuperview];
    
    if (animationLabel)
    {
        [animationLabel release];
        animationLabel = nil;
    }
    
    [[AppPackageInstaller sharedInstaller] downloadCourse:course imageData:self.imageData];
}

-(void)beginDownload:(UIButton *)sender{ 

        [[AppPackageInstaller sharedInstaller] canDownloadCourse:course callback:^(_Bool success) {
            
            if (success)
            {
                downloadButton.hidden = TRUE;
                
                [self animateText:[course objectForKey:@"title"]
                           startX:downloadButton.frame.origin.x
                           startY:downloadButton.frame.origin.y];
            }
        }];
}

- (UIImageView *)imageView
{
    if (_imageView == nil)
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 100, 100)];
    
    return _imageView;
}

-(void)setImageData:(NSData *)imageData
{
    _imageData = imageData;
    self.imageView.image = [UIImage imageWithData:imageData] != nil ? [UIImage imageWithData:imageData] : [UIImage imageNamed:@"placeholder.png"];
}

-(void) setState:(PackageState)state
{
    switch (state) {
        case PackageInstalled:
            stateLabel.text = @"INSTALLED";
            stateLabel.hidden = FALSE;
            downloadButton.hidden = TRUE;
            break; 
            
        case PackageInstalling:            
            stateLabel.text = @"INSTALLING";
            stateLabel.hidden = FALSE;
            downloadButton.hidden = TRUE;
            break; 
            
        case PackageDownloading:            
            stateLabel.text = @"DOWNLOADING";
            stateLabel.hidden = FALSE;
            downloadButton.hidden = TRUE;
            break; 
            
        case PackageNotInstalled:        
            stateLabel.hidden = TRUE;
            downloadButton.hidden = !canDownload;
            break;   
            
        case PackageQueued:
            stateLabel.text = @"QUEUED";
            stateLabel.hidden = FALSE;
            downloadButton.hidden = TRUE;
            break; 
            
        case PackageFailed:
            stateLabel.text = @"FAILED";
            stateLabel.hidden = FALSE;
            downloadButton.hidden = TRUE;
            
        default:
            break;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.view.backgroundColor = [UIColor whiteColor];
    
    UIScrollView *scrollview = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];     
    [self.view addSubview:scrollview];
    [scrollview release];
    
    if (self.imageView)
        [scrollview addSubview:self.imageView];
    
    UILabel *title = [[[UILabel alloc] init] autorelease];
    title.font = [UIFont systemFontOfSize:17];
    title.numberOfLines = 0;    
    title.lineBreakMode = UILineBreakModeWordWrap;
    title.text = [course objectForKey:@"title"];
    title.textColor = [UIColor colorWithRed:57/255.0f green:16/255.0f blue:52/255.0f alpha:1];
    CGSize size = [self fitLabel:title withWidth:190 x:120 y:10];
    [scrollview addSubview:title];
    
    CGFloat yOffset = size.height + 20;   
    
    if (yOffset < 130) {
        downloadButton.frame = CGRectMake(120, yOffset, 70, 30); 
    }
    else{
        downloadButton.frame = CGRectMake(20, yOffset, 70, 30); 
    }
    [downloadButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    downloadButton.backgroundColor = [UIColor colorWithRed:209.0f/255.0f 
                                                  green:211.0f/255.0f 
                                                   blue:212.0f/255.0f 
                                                  alpha:1];
    downloadButton.layer.borderColor = [UIColor colorWithRed:174.0f/255.0f 
                                                    green:171.0f/255.0f 
                                                     blue:174.0f/255.0f 
                                                    alpha:1].CGColor;
    downloadButton.layer.borderWidth = 1.0f;
    downloadButton.layer.cornerRadius = 3.0f;
    downloadButton.titleLabel.font = [UIFont systemFontOfSize:9]; 
    if (yOffset < 130) {
        stateLabel.frame = CGRectMake(120, yOffset, 130, 30); 
    }
    else {
        stateLabel.frame = CGRectMake(20, yOffset, 130, 30);
    }
    [scrollview addSubview:downloadButton];    
    [scrollview addSubview:stateLabel]; 
    
    yOffset += 50; 
    yOffset = MAX(yOffset, 140); 
        
    
    UILabel *descLabel = [[[UILabel alloc] init] autorelease];
    descLabel.font = [UIFont boldSystemFontOfSize:12];
    descLabel.numberOfLines = 0;
    descLabel.text = @"DESCRIPTION";
    descLabel.textColor = [UIColor colorWithRed:128/255.0f green:130/255.0f blue:133/255.0f alpha:1];
    size = [self fitLabel:descLabel withWidth:300 x:10 y:yOffset];
    [scrollview addSubview:descLabel];
    yOffset += size.height + 2; 
    
    UIView *descLineView = [[[UIView alloc] initWithFrame:CGRectMake(10, yOffset + 2, self.view.bounds.size.width - 20, 1)] autorelease];
    descLineView.backgroundColor = [UIColor colorWithRed:128/255.0f green:130/255.0f blue:133/255.0f alpha:1];
    [scrollview addSubview:descLineView];
    yOffset += 5;  
    
    UILabel *description = [[[UILabel alloc] init] autorelease];
    description.font = [UIFont systemFontOfSize:13];
    description.numberOfLines = 0;
    description.lineBreakMode = UILineBreakModeWordWrap;
    description.textColor = [UIColor colorWithRed:77/255.0f green:77/255.0f blue:79/255.0f alpha:1];
    description.text = [course objectForKey:@"description"]; 
    size = [self fitLabel:description withWidth:300 x:10 y:yOffset];
    [scrollview addSubview:description];    
    yOffset += size.height + 20;
    
    
    UILabel *detailsLabel = [[[UILabel alloc] init] autorelease];
    detailsLabel.font = [UIFont boldSystemFontOfSize:12];
    detailsLabel.numberOfLines = 0;
    detailsLabel.text = @"DETAILS";
    detailsLabel.textColor = [UIColor colorWithRed:128/255.0f green:130/255.0f blue:133/255.0f alpha:1];
    size = [self fitLabel:detailsLabel withWidth:300 x:10 y:yOffset];
    [scrollview addSubview:detailsLabel];
    yOffset += size.height + 2; 
    
    UIView *lineView = [[[UIView alloc] initWithFrame:CGRectMake(10, yOffset + 2, self.view.bounds.size.width - 20, 1)] autorelease];
    lineView.backgroundColor = [UIColor colorWithRed:128/255.0f green:130/255.0f blue:133/255.0f alpha:1];
    [scrollview addSubview:lineView];
    yOffset += 5; 
    
    NSString *courseCode = [course objectForKey:@"courseCode"];
    
    if (courseCode && [courseCode isKindOfClass:[NSString class]])
    {
        UILabel *courseCodeLabel = [[[UILabel alloc] init] autorelease];
        courseCodeLabel.font = [UIFont systemFontOfSize:12];
        courseCodeLabel.textColor = [UIColor grayColor];
        courseCodeLabel.numberOfLines = 0;    
        courseCodeLabel.lineBreakMode = UILineBreakModeWordWrap;  
        courseCodeLabel.textColor = [UIColor colorWithRed:77/255.0f green:77/255.0f blue:79/255.0f alpha:1];
        courseCodeLabel.text = [NSString stringWithFormat:@"Course Code: %@",courseCode];
        
        size = [self fitLabel:courseCodeLabel withWidth:300 x:10 y:yOffset];

        [scrollview addSubview:courseCodeLabel];
        yOffset += size.height; 
    }
    
    UILabel *sizeLabel = [[[UILabel alloc] init] autorelease];
    sizeLabel.font = [UIFont systemFontOfSize:12];
    sizeLabel.numberOfLines = 0;
    sizeLabel.lineBreakMode = UILineBreakModeWordWrap;
    sizeLabel.textColor = [UIColor colorWithRed:77/255.0f green:77/255.0f blue:79/255.0f alpha:1];
    
    float sizeVal = self.courseSize;
    
    if (sizeVal > 0)
    {
        if (sizeVal > 1024)
            sizeLabel.text = [NSString stringWithFormat:@"Size: %.2fMB", sizeVal / 1024];
        else                  
            sizeLabel.text = [NSString stringWithFormat:@"Size: %.0fKB", sizeVal]; 
    }
    
    size = [self fitLabel:sizeLabel withWidth:300 x:10 y:yOffset];
    [scrollview addSubview:sizeLabel];    
    yOffset += size.height;
    
    scrollview.contentSize = CGSizeMake(self.view.frame.size.width, yOffset); 
    
    NSDictionary *fileData = [[AppPackageInstaller sharedInstaller] getFileDataForCourse:course];
    
    if([fileData objectForKey:@"version"])
    {
        UILabel *versionLabel = [[[UILabel alloc] init]  autorelease];
        versionLabel.font = [UIFont systemFontOfSize:12];
        versionLabel.numberOfLines = 0;
        versionLabel.lineBreakMode = UILineBreakModeWordWrap;
        versionLabel.textColor = [UIColor colorWithRed:77/255.0f green:77/255.0f blue:79/255.0f alpha:1];
        versionLabel.text = [NSString stringWithFormat:@"Version: %@",[fileData objectForKey:@"version"]];
        /*size = */[self fitLabel:versionLabel withWidth:300 x:10 y:yOffset];
        [scrollview addSubview:versionLabel];    
        //yOffset += size.height;
    }
}

-(void) updateUI
{
    [self setState:[[AppPackageInstaller sharedInstaller] getPackageState:course]];
}

- (void)setCanDownload:(BOOL)_canDownload
{
    canDownload = _canDownload;
    [self updateUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateUI];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc { 
    if (animationLabel)
    {
        [animationLabel release];
        animationLabel = nil;
    }
    
    [downloadButton release];
    [stateLabel release];
    
    self.imageData = nil;
    [_imageView release];
    [course release];
    
    [super dealloc];
}
@end
