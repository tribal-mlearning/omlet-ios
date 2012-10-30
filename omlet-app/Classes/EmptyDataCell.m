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

#import "EmptyDataCell.h"



@implementation EmptyDataCell

@synthesize image;
@synthesize message;
@synthesize imageName;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.imageName = @"books.png";
        
        image = [[UIImageView alloc] init];
        image.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:image];
        
        message = [[UILabel alloc] init];
        message.font = [UIFont systemFontOfSize:12];
        message.textAlignment = UITextAlignmentCenter;
        message.textColor = [UIColor grayColor];
        message.numberOfLines =0;
        [self.contentView addSubview:message];
        message.backgroundColor = [UIColor clearColor];
        
        self.userInteractionEnabled = NO;
        
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)layoutSubviews
{

    
    float xOffset = self.contentView.frame.origin.x;
    float cellWidth = self.contentView.frame.size.width;
    
    float yOffset = self.contentView.frame.origin.y;
    
    yOffset += 140;
    
    UIImage *booksImage = [UIImage imageNamed:self.imageName];
    [image setImage:booksImage];
    image.frame = CGRectMake(110, yOffset, 100, 100);
    
    yOffset += 120;
     
    message.textAlignment = UITextAlignmentCenter;
    
    CGSize labelSize = [message.text sizeWithFont:message.font
                              constrainedToSize:CGSizeMake(cellWidth, 100)
                                  lineBreakMode:message.lineBreakMode];
    message.frame = CGRectMake(xOffset, yOffset,cellWidth, labelSize.height);
    
    self.contentView.frame = CGRectMake(0, 0, 320, 400);
}

- (void)dealloc
{
    [image release];
    [message release];
    self.imageName = nil;
    
    [super dealloc];
}

@end
