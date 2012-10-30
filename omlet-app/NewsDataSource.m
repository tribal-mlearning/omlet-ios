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

#import "NewsDataSource.h"
#import "CustomTableViewCell.h"

@implementation NewsDataSource

@synthesize newsItems;
@synthesize navigationController;
@synthesize readNewsIds = _readNewsIds;

- (void)saveReadNewsIds
{
    if (_readNewsIds)
    {
        NSString *error;
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *newsListPath = [documentsDirectory stringByAppendingPathComponent:@"/news.plist"];
                
        NSData *data = [NSPropertyListSerialization dataFromPropertyList:_readNewsIds
                                                                  format:NSPropertyListBinaryFormat_v1_0
                                                        errorDescription:&error];
        
        if (data) 
            [data writeToFile:newsListPath atomically:YES];        
    }
}

- (NSMutableArray *)readNewsIds{
    
    if (_readNewsIds == nil)
    {
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *newsListPath = [documentsDirectory stringByAppendingPathComponent:@"/news.plist"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:newsListPath]) 
        {
            NSPropertyListFormat format;
            NSString *error;
            
            _readNewsIds = [[NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfFile:newsListPath]
                                                       mutabilityOption:NSPropertyListMutableContainers
                                                                 format:&format
                                                       errorDescription:&error] mutableCopy];
        }
        
        if (_readNewsIds == nil)
            _readNewsIds = [[NSMutableArray alloc] init];
    }
    
    return _readNewsIds;
}



-(NSString *) getNewsId:(NSDictionary *)news{
    return [news description];
}

- (BOOL)hasNewsBeenRead:(NSDictionary *)newsItem {
    
    NSString *newsId = [self getNewsId:newsItem];
    
    for (NSString *n in self.readNewsIds) {
        if ([n isEqualToString:newsId])
            return YES;
    }
    
    return NO;
}

- (BOOL)hasNewsBeenReadAt:(NSUInteger)index {
    
    return [self hasNewsBeenRead:[newsItems objectAtIndex:index]];
}

- (void)markNewsAsRead:(NSDictionary *)newsItem {
    if (![self hasNewsBeenRead:newsItem])
    {   
        NSString *newsId = [self getNewsId:newsItem];
        [self.readNewsIds addObject:newsId];
        [self saveReadNewsIds];
    }
}

-(NSUInteger)getUnreadNewsCount{
    NSUInteger count = 0;
    
    for (NSDictionary* newsItem in newsItems) {
        if(![self hasNewsBeenRead:newsItem])
            count++;
    }
    
    return count;
}

- (id)init {
    self = [super init];
    if (self) {
        imageDownloader = [[DownloadManager alloc] initWithCapacity:6];
        imageCache = [[NSMutableDictionary alloc] init];
        largeImageCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (BOOL) hasThumbnail:(NSDictionary *)newsItem
{
    return [newsItem valueForKey:@"thumbnailUrl"] != nil;
}

- (void) downloadImageFor:(NSDictionary *)newsItem imageUrl:(NSString *)url tableView:(UITableView *)tableView
{          
    [imageDownloader enqueueDownload:url withAuth:NO expectedSize:0 downloadComplete:^(Download *download, NSData *data) {
        
        if (data)
        {
            [imageCache setObject:data forKey:newsItem]; 
            
            if (tableView)
            {
                NSUInteger index = [newsItems indexOfObject:newsItem];
                CustomTableViewCell *cell = (CustomTableViewCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];   
                UIImage *image = [UIImage imageWithData:data];
                cell.leftImageView.image = image; 
                [cell setNeedsLayout];
            }
            
            if (detailController.newsItem == newsItem && ![self hasThumbnail:newsItem])
            {
                detailController.imageData = data;
            }
        }
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [newsItems count];
}

- (void)checkButtonTapped:(id)sender event:(id)event
{
    UITableView *tableView = (UITableView*)[[sender superview] superview];
    
    
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:tableView];
    NSIndexPath *indexPath = [tableView indexPathForRowAtPoint: currentTouchPosition];
    if (indexPath != nil)
    {
        [self goToNewsItem:indexPath.row];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"Cell";
    
    CustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[CustomTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSDictionary *newsItem = [newsItems objectAtIndex:indexPath.row];
    
    cell.headerLabel.text = [newsItem objectForKey:@"headline"];
    cell.subHeaderLabel.text = [newsItem objectForKey:@"text"];
    
    if (![self hasNewsBeenReadAt:indexPath.row])
    {
        cell.customStyle = CustomTableViewCellHighlightedStyle;
    }
    else if ((indexPath.row % 2) == 0)
    {
        cell.customStyle = CustomTableViewCellBasicStyle;
    }
    else
        cell.customStyle = CustomTableViewCellAltStyle;

    NSData *imageData = [imageCache objectForKey:newsItem];
    
    if (imageData)
    {
        cell.leftImageView.image = [UIImage imageWithData:imageData];
    }
    else
    {
        cell.leftImageView.image = nil;
        
        NSString* imgUrl = nil;
        
        if ([self hasThumbnail:newsItem])
            imgUrl = [newsItem valueForKey:@"thumbnailUrl"];
        else
            imgUrl = [newsItem valueForKey:@"imageUrl"];
        
        [self downloadImageFor:newsItem imageUrl:imgUrl tableView:tableView];
    }
    
    UIImage *image = [self hasNewsBeenReadAt:indexPath.row] ? [UIImage imageNamed:@"news_star_small_read.png"] : [UIImage imageNamed:@"news_star_small_unread.png"];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    button.frame = frame;   // match the button's size with the image size
    
    [button setBackgroundImage:image forState:UIControlStateNormal];

    // set the button's target to this table view controller so we can interpret touch events and map that to a NSIndexSet
    [button addTarget:self action:@selector(checkButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = button;
    
    return cell;
}

- (void)markNewsItemAsUnread:(NSDictionary *)newsItem{
    if ([self hasNewsBeenRead:newsItem])
    {   
        NSString *newsId = [self getNewsId:newsItem];
        [self.readNewsIds removeObject:newsId];
        [self saveReadNewsIds];
    }
}

- (void) goToNewsItem:(NSUInteger)index{
    
    if (navigationController)
    {
        NSDictionary *newsItem = [newsItems objectAtIndex:index];
        
        if (newsItem)
        {            
            if (detailController)
            {
                [detailController release];
                detailController = nil;
            }
            
            detailController = [[NewsDetailController alloc] init];
            detailController.delegate = self;
            detailController.newsItem = newsItem;
            
            if ([self hasThumbnail:newsItem])
            { 
                NSData *imageData = [largeImageCache objectForKey:newsItem];
                
                if (imageData)
                    detailController.imageData = imageData;
                else
                {
                    //need to download the image since we dont have it..
                    [imageDownloader enqueueDownload:[newsItem valueForKey:@"imageUrl"] withAuth:NO expectedSize:0 downloadComplete:
                     ^(Download *download, NSData *data) {                        
                        if (data)
                        {
                            [largeImageCache setObject:data forKey:newsItem];                            
                            detailController.imageData = data;
                        }
                    }];                    
                }
            }
            else
            {
                NSData *imageData = [imageCache objectForKey:newsItem];
                
                if (imageData)
                    detailController.imageData = imageData;
            }
            
                        
                        
            [self markNewsAsRead:newsItem];                        
            [[self navigationController] pushViewController:detailController animated:YES];
        }
    }
}

- (void)dealloc {
    self.newsItems = nil;
    [_readNewsIds release];
    [imageCache release];
    [largeImageCache release];
    [imageDownloader release];
    [detailController release];
    
    [super dealloc];
}

@end
