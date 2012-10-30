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

#import "CustomTableViewCell.h"
#import "XProgressView.h"
#import <QuartzCore/QuartzCore.h>

@implementation CustomTableViewCell

@synthesize activityIndicator;
@synthesize headerLabel;
@synthesize subHeaderLabel;
@synthesize rightLabel;
@synthesize rightButton;
@synthesize leftImageView;
@synthesize progressView;
@synthesize progressLabel;
@synthesize customStyle;
@synthesize leftLabel;

- (void) updateStyle
{
    if (customStyle == CustomTableViewCellBasicStyle ||
        customStyle == CustomTableViewCellAltStyle)
    {
        subHeaderLabel.textColor = [UIColor colorWithRed:0.0f 
                                                   green:0.0f 
                                                    blue:146.0f/255.0f 
                                                   alpha:1];
        
        leftLabel.textColor = [UIColor colorWithRed:176.0f/255.0f 
                                                   green:85.0f/255.0f 
                                                    blue:146.0f/255.0f 
                                                   alpha:1];
        
        headerLabel.textColor = [UIColor colorWithRed:58.0f/255.0f 
                                                green:15.0f/255.0f 
                                                 blue:52.0f/255.0f 
                                                alpha:1];
    }
    else if (customStyle == CustomTableViewCellHighlightedStyle)
    {
        subHeaderLabel.textColor = [UIColor colorWithRed:218.0f/255.0f 
                                                   green:179.0f/255.0f 
                                                    blue:181.0f/255.0f 
                                                   alpha:1];
        
        leftLabel.textColor = [UIColor colorWithRed:218.0f/255.0f 
                                                   green:179.0f/255.0f 
                                                    blue:181.0f/255.0f 
                                                   alpha:1];
        
        headerLabel.textColor = [UIColor colorWithRed:255.0f/255.0f 
                                                green:255.0f/255.0f 
                                                 blue:255.0f/255.0f 
                                                alpha:1];
        
        
    }
    
    
    
    if (customStyle == CustomTableViewCellBasicStyle)
    {
        self.contentView.backgroundColor = [UIColor colorWithRed:235.0f/255.0f 
                                                           green:231.0f/255.0f 
                                                            blue:235.0f/255.0f 
                                                           alpha:1];
        
        border.backgroundColor = [UIColor grayColor];
    }
    else if (customStyle == CustomTableViewCellAltStyle)
    {
        self.contentView.backgroundColor = [UIColor whiteColor];
        border.backgroundColor = [UIColor grayColor];
    }
    else if (customStyle == CustomTableViewCellHighlightedStyle)
    {
        self.contentView.backgroundColor = [UIColor colorWithRed:58.0 / 255.0
                                                           green:15.0 / 255.0
                                                            blue:52.0 / 255.0
                                                           alpha:1.0f];
        
        border.backgroundColor = [UIColor colorWithRed:165.0 / 255.0
                                                 green:67.0 / 255.0
                                                  blue:137.0 / 255.0
                                                 alpha:1.0f];
    }
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        UIView *myContentView = self.contentView;
                        
        leftImageView = [[UIImageView alloc] init];
        leftImageView.contentMode = UIViewContentModeScaleAspectFit;
        [myContentView addSubview:leftImageView];
        
        // Configure the cell... 
        headerLabel = [[UILabel alloc] init];
        headerLabel.font = [UIFont systemFontOfSize:15];
        headerLabel.textAlignment = UITextAlignmentLeft;
        [myContentView addSubview:headerLabel];
        headerLabel.backgroundColor = [UIColor clearColor];
        
        subHeaderLabel = [[UILabel alloc] init];
        subHeaderLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
        subHeaderLabel.backgroundColor = [UIColor clearColor];
        subHeaderLabel.textAlignment = UITextAlignmentLeft;       
        [myContentView addSubview:subHeaderLabel];
        
        leftLabel = [[UILabel alloc] init];
        leftLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
        leftLabel.backgroundColor = [UIColor clearColor];
        leftLabel.textAlignment = UITextAlignmentLeft;
        [myContentView addSubview:leftLabel];
        
        rightLabel = [[UILabel alloc] init];
        rightLabel.font = [UIFont boldSystemFontOfSize:9];
        rightLabel.textColor    = [UIColor blackColor];
        rightLabel.backgroundColor = [UIColor clearColor];
        rightLabel.textAlignment = UITextAlignmentRight;
        [myContentView addSubview:rightLabel];       
        
        rightButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [rightButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        rightButton.backgroundColor = [UIColor colorWithRed:209.0f/255.0f 
                                                      green:211.0f/255.0f 
                                                       blue:212.0f/255.0f 
                                                      alpha:1];
        
        
        rightButton.layer.borderColor = [UIColor colorWithRed:174.0f/255.0f 
                                                        green:171.0f/255.0f 
                                                         blue:174.0f/255.0f 
                                                        alpha:1].CGColor;
        rightButton.layer.borderWidth = 1.0f;
        rightButton.layer.cornerRadius = 3.0f;
        
        rightButton.titleLabel.font = [UIFont systemFontOfSize:9];         
        [myContentView addSubview:rightButton];
           
        border = [[UIView alloc] init];
        border.backgroundColor = [UIColor grayColor];
        [myContentView addSubview:border]; 
    
        progressView = [[XProgressView alloc] init];        
        [myContentView addSubview:progressView];
        
        progressLabel = [[UILabel alloc] init];
        progressLabel.font = [UIFont systemFontOfSize:13];
        progressLabel.textColor    = [UIColor colorWithRed:0.0f
                                                     green:0.0f
                                                      blue:146.0f/255.0f 
                                                     alpha:1];
        progressLabel.backgroundColor = [UIColor clearColor];
        progressLabel.textAlignment = UITextAlignmentRight;
        [myContentView addSubview:progressLabel];   
    
        activityIndicator = [[UIActivityIndicatorView alloc] init];
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        activityIndicator.hidesWhenStopped = TRUE;
        [myContentView addSubview:activityIndicator]; 
        
        rightLabel.hidden = YES;
        rightButton.hidden = YES;
        progressView.hidden = YES;
        progressLabel.hidden = YES;
        leftLabel.hidden = YES;
        
        self.customStyle = CustomTableViewCellBasicStyle;
       
    }
    return self;
}

- (float) getWidthOfText:(UILabel *)label
{
    CGSize size = [label.text sizeWithFont:label.font 
                         constrainedToSize:CGSizeMake(16*1000.f, 0) 
                             lineBreakMode:UILineBreakModeWordWrap];
    
    return size.width;
}

- (void)layoutSubviews{
    [super layoutSubviews];

    float xOffset = self.contentView.frame.origin.x;
    float cellWidth = self.contentView.frame.size.width;
    
    float imgSize = self.frame.size.height;
    float padding = 5;
    
    float rightWidth = 0.0f;
    
    float leftWidth = xOffset + imgSize;
    
    if (!rightLabel.hidden)
    {
        rightWidth = [self getWidthOfText:rightLabel] + padding;
        rightLabel.frame = CGRectMake(cellWidth - rightWidth - padding, 12.0f, rightWidth, 30.0f);  
    }
    else if (!progressLabel.hidden)
    {
        //rightWidth = 80;
        //rightWidth = [self getWidthOfText:progressLabel] + padding;
        progressLabel.frame = CGRectMake(cellWidth - 80 - padding + xOffset, 32.0f, 80, 30.0f);
    }
    else if(!leftLabel.hidden)
    {
        leftLabel.frame = CGRectMake(leftWidth + padding, 32.0f, 80, 30.0f);
    }
    else if (!rightButton.hidden)
    {
        rightWidth = 70.0f;
        rightButton.frame = CGRectMake(cellWidth - rightWidth - padding, 15.0f, rightWidth, 30.0f);
    }
    
    float cellCenterWidth = cellWidth - imgSize - rightWidth - (padding * 2);
    
    leftImageView.frame = CGRectMake(xOffset, 0, imgSize, imgSize);
    headerLabel.frame = CGRectMake(leftWidth + padding, 7, cellCenterWidth, 19);
    subHeaderLabel.frame = CGRectMake(leftWidth + padding, 25, cellCenterWidth, 19);
    progressView.frame = CGRectMake(leftWidth + padding, 45, cellWidth - imgSize - 50, 5);
    activityIndicator.frame = CGRectMake(cellWidth - 85 - padding, 40, 15.0f, 15.0f);
    
    border.frame = CGRectMake(0, self.contentView.frame.size.height - 1, 320, 1);
    
    self.contentView.frame = CGRectMake(0, 0, 450, imgSize);
}

- (void)dealloc
{
    [activityIndicator release];
    [headerLabel release];
    [subHeaderLabel release];
    [rightLabel release];
    [rightButton release];
    [leftImageView release];
    [progressView release];
    [progressLabel release];
    [border release];
    [leftLabel release];
    
    [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setCustomStyle:(CustomTableViewCellStyle)_customStyle{
    customStyle = _customStyle;
    [self updateStyle];
}

@end
