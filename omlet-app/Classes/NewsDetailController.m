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

#import "NewsDetailController.h"
#import "Download.h"

@implementation NewsDetailController
@synthesize borderView;
@synthesize image;
@synthesize headlineLabel;
@synthesize textLabel;
@synthesize scrollView;
@synthesize newsItem;
@synthesize delegate;
@synthesize imageData = _imageData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"News";
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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

- (void) layoutUI{
    
    CGFloat yOffset = 0;
    CGFloat width = self.view.frame.size.width;
    
    if (_imageData)
    {
        UIImage *img = [UIImage imageWithData:_imageData];
        
        CGFloat scale = img.size.width / width;
        
        UIImage *scaledImg = [UIImage imageWithCGImage:[img CGImage] scale:scale orientation:UIImageOrientationUp];
        
        self.image.frame = CGRectMake(0, 0, self.view.frame.size.width, scaledImg.size.height);
        self.image.image = scaledImg;
        yOffset += scaledImg.size.height;
    }
    
    borderView.frame = CGRectMake(0, yOffset, 320, 5);
    yOffset += 25; 
    
    CGSize size = [self fitLabel:headlineLabel withWidth:270 x:30 y:yOffset];
    yOffset += size.height + 10;  
    
    size = [self fitLabel:textLabel withWidth:270 x:30 y:yOffset];
    yOffset += size.height; 
    
    scrollView.contentSize = CGSizeMake(width, yOffset); 
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    headlineLabel.text = [newsItem objectForKey:@"headline"];
    textLabel.text = [newsItem objectForKey:@"text"];
}

-(void) markAsUnread:(id)sender
{
    if (delegate)
    {
        [delegate markNewsItemAsUnread:newsItem];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [self layoutUI];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Mark as unread"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(markAsUnread:)];
    self.navigationItem.rightBarButtonItem = rightButton;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [rightButton release];

    
    [super viewWillAppear:animated];
}



- (void)viewDidUnload
{
    [self setTextLabel:nil];
    [self setHeadlineLabel:nil];
    [self setImage:nil];
    [self setScrollView:nil];
    [self setBorderView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)setImageData:(NSData *)imageData
{
    _imageData = imageData;
    [self layoutUI];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [newsItem release];
    [textLabel release];
    [headlineLabel release];
    [image release];
    [scrollView release];
    [borderView release];
    [super dealloc];
}
@end
