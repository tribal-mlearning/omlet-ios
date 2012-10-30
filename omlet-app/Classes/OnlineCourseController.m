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

#import "OnlineCourseController.h"
#import "ZipHelper.h"
#import "CourseDetailController.h"
#import "AppPackageInstaller.h"
#import "Framework.h"
#import "CustomTableViewCell.h"
#import "EmptyDataCell.h"

@interface OnlineCourseController ()
-(void) updateUIFor:(CustomTableViewCell *)cell state:(PackageState) state;
- (void)updateUI;
-(void)refreshCourseList:(OnRefreshCourseListCompleted)callback;
- (void) downloadImageFor:(NSIndexPath *)indexPath imageUrl:(NSString *)url;
@end

@implementation OnlineCourseController
@synthesize courses, canDownload;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Catalog" image:
          [UIImage imageNamed:@"catalogue.png"] tag:2] autorelease];
        self.title = @"Download";
        imageCache = [[NSMutableDictionary alloc] init];
        imageDownloader = [[DownloadManager alloc] initWithCapacity:6]; 
        
        UIBarButtonItem *syncButton = [[UIBarButtonItem alloc] initWithTitle:@"Sync" style:UIBarButtonItemStylePlain target:nil action:nil];                
        self.navigationItem.rightBarButtonItem = syncButton;
        [syncButton release];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(downloadItemStatusChanged:)
                                                     name:@"DownloadStatusChanged"
                                                   object:nil ];
    }
    return self;
}

-(void)downloadItemStatusChanged: (NSNotification *) notification
{
    NSDictionary *courseInf = (NSDictionary*)notification.object;
    int state = [[courseInf objectForKey:@"status"] intValue];
    NSDictionary *course = [courseInf objectForKey:@"course"];
    
    
    PackageState pState = [[AppPackageInstaller sharedInstaller] getPackageState:course]; 
    
    int i;
    for (i=0; i < [self.courses count]; i++) {
        if([[[self.courses objectAtIndex:i] objectForKey:@"uniqueId"] isEqualToString:[course objectForKey:@"uniqueId"]]) {
            break;
        }
    }
    
    int row =i;
    
    CustomTableViewCell *cell = (CustomTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];            
    if([cell isKindOfClass:[CustomTableViewCell class]])
    {
        [self updateUIFor:cell state:pState];
    }
    
    if (detailViewController.course == course)
        [detailViewController setState:state];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.canDownload)
        [self refreshCourseList:nil];
    
    if (detailViewController)
    {
        NSUInteger cellIndex = [self.courses indexOfObject:detailViewController.course];
        NSIndexPath *cellPath = [NSIndexPath indexPathForRow:cellIndex inSection:0];
        
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:cellPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
        
        [detailViewController release];
        detailViewController = nil;
    }
}



- (void)setCanDownload:(BOOL)_canDownload {
    
    if (canDownload != _canDownload)
    {    
        canDownload = _canDownload;
        //[self updateUI];
    
        if (self.canDownload)
            [self refreshCourseList:nil];
        else
            [[self tableView] reloadData];
    
        if (detailViewController)
        {
            if (canDownload == NO) {
                [[self navigationController] popToViewController:self animated:NO];
            }
            detailViewController.canDownload = _canDownload;
        }
    }
}

-(void)refreshCourseList:(OnRefreshCourseListCompleted)callback{
    id<Server> server = [Framework server];
    
    [server getPackages:^(bool success, id data) {
        if (success) {
            NSMutableArray *mCourses = [NSMutableArray arrayWithArray:data];
            
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:TRUE selector:@selector(caseInsensitiveCompare:)];
                        
            NSPredicate *filterPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                return ([evaluatedObject objectForKey:@"files"] != nil);
            }];
            
            [mCourses filterUsingPredicate:filterPredicate];
            [mCourses sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            [sortDescriptor release];
            
            self.courses = [NSArray arrayWithArray:mCourses];
            
            [self.tableView reloadData];
        }
        
        if(callback){
            callback();
        }
    }];
}

- (void)updateUI {
    if (self.isViewLoaded == NO) return;
    if (!canDownload) return;
    
    BOOL downloaderBusy = [imageDownloader activeDownloadCount] > 0;
    
    for (CustomTableViewCell *cell in [self.tableView visibleCells]) {
                  
        NSDictionary *course = [courses objectAtIndex:[self.tableView indexPathForCell:cell].row];
        PackageState state = [[AppPackageInstaller sharedInstaller] getPackageState:course];
        
        if([cell isKindOfClass:[CustomTableViewCell class]])
            [self updateUIFor:cell state:state];
        
        if (canDownload && ([cell isKindOfClass:[CustomTableViewCell class]] && cell.leftImageView.image == nil) && !downloaderBusy)
            [self downloadImageFor:[self.tableView indexPathForCell:cell] imageUrl:[course objectForKey:@"thumbnailUrl"]];        
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
   
    [self updateUI];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.6 alpha:1];    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;       
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)clearCachedData
{
    [courses release];
    courses = nil;
}

- (void)dealloc {
     [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadStatusChanged" object:nil];
    [detailViewController release];
    [imageDownloader release];
    [courses release];
    [imageCache release];
    
    [super dealloc];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section
    if(canDownload){
        tableView.scrollEnabled = YES;
        return [[self courses] count];
    }
    else {
        tableView.scrollEnabled = NO;
        return 1; //Allow generation of empty data message
    }    
}

-(void) updateUIFor:(CustomTableViewCell *)cell state:(PackageState) state{
           
    switch (state) {
        case PackageInstalled:
            cell.rightLabel.text = @"INSTALLED";
            cell.rightLabel.hidden = FALSE;
            cell.rightButton.hidden = TRUE;
            break; 
            
        case PackageInstalling:            
            cell.rightLabel.text = @"INSTALLING";
            cell.rightLabel.hidden = FALSE;
            cell.rightButton.hidden = TRUE;
            break; 
            
        case PackageDownloading:            
            cell.rightLabel.text = @"DOWNLOADING";
            cell.rightLabel.hidden = FALSE;
            cell.rightButton.hidden = TRUE;
            break; 
            
        case PackageNotInstalled:        
            cell.rightLabel.hidden = YES;
            cell.rightButton.hidden = !canDownload;
            [cell.rightButton setTitle:@"DOWNLOAD" forState:UIControlStateNormal];
            break;   
            
        case PackageQueued:
            cell.rightLabel.text = @"QUEUED";
            cell.rightLabel.hidden = FALSE;
            cell.rightButton.hidden = TRUE;
            break;  
            
        case PackageFailed:            
            cell.rightLabel.text = @"FAILED";
            cell.rightLabel.hidden = FALSE;
            cell.rightButton.hidden = TRUE;
            break; 
            
        case PackageUpdateAvailable:
            cell.rightLabel.hidden = TRUE;
            cell.rightButton.hidden = !canDownload;
            [cell.rightButton setTitle:@"UPDATE" forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
    
    [cell setNeedsLayout];
}

-(void)beginDownload:(UIButton *)sender{ 
    
    UIView *contentView = sender.superview;
    UITableViewCell *cell = (UITableViewCell *)contentView.superview;
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    NSDictionary *course = [self.courses objectAtIndex:path.row];
    
    [[AppPackageInstaller sharedInstaller] canDownloadCourse:course callback:^(_Bool success) {
        
        if (success)
        {
            NSData *imgData = [imageCache objectForKey:course];          
            [[AppPackageInstaller sharedInstaller] downloadCourse:course imageData:imgData];
        }
    }]; 
}


- (void) downloadImageFor:(NSIndexPath *)indexPath imageUrl:(NSString *)url
{          
    [imageDownloader enqueueDownload:url withAuth:NO expectedSize:0 downloadComplete:^(Download *download, NSData *data) {
           
        if (data)
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            
            [imageCache setObject:data forKey:[courses objectAtIndex:indexPath.row]]; 
            
            if ([courses objectAtIndex:indexPath.row] == detailViewController.course)
            {
                detailViewController.imageData = data;
            }
            
            if ([cell isKindOfClass:[CustomTableViewCell class]])
            {
                CustomTableViewCell *customCell = (CustomTableViewCell *)cell;   
                UIImage *image = [UIImage imageWithData:data];
                customCell.leftImageView.image = image; 
                [cell setNeedsLayout];
            }
        }
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (canDownload)
    {
        static NSString *CellIdentifier = @"Cell";
        
        NSDictionary *course = [courses objectAtIndex:indexPath.row];
        
        CustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[CustomTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                               reuseIdentifier:CellIdentifier] autorelease];
        }
        
        if ((indexPath.row % 2) == 0)
            cell.customStyle = CustomTableViewCellBasicStyle;
        else
            cell.customStyle = CustomTableViewCellAltStyle;
        
        [cell.rightButton addTarget:self action:@selector(beginDownload:) forControlEvents:UIControlEventTouchUpInside];
        [cell.rightButton setTitle:@"download" forState:UIControlStateNormal];
        
        PackageState state = [[AppPackageInstaller sharedInstaller] getPackageState:course];        
        [self updateUIFor:cell state:state];
        
        
        cell.headerLabel.text = [course objectForKey:@"title"];
        
        NSString *courseCode = [course objectForKey:@"courseCode"];
        
        if (courseCode && [courseCode isKindOfClass:[NSString class]])
            cell.subHeaderLabel.text = courseCode;
        else
            cell.subHeaderLabel.text = @"";
        
        NSData *imageData = [imageCache objectForKey:course];
        
        if (imageData)
        {
            cell.leftImageView.image
            = [UIImage imageWithData:imageData];
        }
        else
        {
            cell.leftImageView.image = [UIImage imageNamed:@"placeholder.png"];
            if (canDownload)
                [self downloadImageFor:indexPath imageUrl:[course objectForKey:@"thumbnailUrl"]];
        }
        
        return cell;
    }
    else
    {
        EmptyDataCell *cell = [[[EmptyDataCell alloc] init] autorelease];
        cell.imageName = @"connection.png";
        cell.message.text = @"An internet connection is\nrequired to download new items";
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(void) navigateToDetailForCourse:(NSDictionary*)course
{
    [detailViewController release];
    detailViewController = nil;
    
    detailViewController = [[CourseDetailController alloc] init];  
    
    detailViewController.course = course;
    
    detailViewController.courseSize = [[AppPackageInstaller sharedInstaller] getSizeOfCourse:course];
    
    detailViewController.imageData = [imageCache objectForKey:course];
    detailViewController.title = [course objectForKey:@"title"];
    detailViewController.canDownload = canDownload;
    
    [[self navigationController] pushViewController:detailViewController animated:YES];
}
               
-(void) navigateToDetailForCourseWithId:(NSString*)uniqueId
{
   if(self.courses)
    {
        for (NSDictionary *c in self.courses) {
            if([[c objectForKey:@"uniqueId"] isEqualToString:uniqueId])
            {
                [self navigateToDetailForCourse:c];
                return;
            }
        }
    }
    //The referenced course isn't in the list yet, reload the courses
    [self refreshCourseList:^(){
        for (NSDictionary *c in self.courses) {
            if([[c objectForKey:@"uniqueId"] isEqualToString:uniqueId])
            {
                [self navigateToDetailForCourse:c];
                
                //Image for this course won't yet have been downloaded
                [imageDownloader enqueueDownload:[c objectForKey:@"thumbnailUrl"] withAuth:NO expectedSize:0 downloadComplete:^(Download *download, NSData *data) {
                    
                    if (data)
                    {
                        [imageCache setObject:data forKey:c];
                        if([[detailViewController.course objectForKey:@"uniqueId"] isEqualToString:uniqueId])
                        {
                            detailViewController.imageData = data;
                        }
                    }
                }];
                
                
                return;
            }
        }
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *course = [self.courses objectAtIndex:indexPath.row];
    [self navigateToDetailForCourse:course];
}
@end
