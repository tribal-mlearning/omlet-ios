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

#import "DownloadContoller.h"
#import "CustomTableViewCell.h"

@interface DownloadContoller ()
- (void) updateBadge;

- (void) updateUIWithProgress:(UIProgressView *)progressView
                       status:(DownloadStatus)status
                    installed:(BOOL)installed
                   percentage:(NSNumber *)percentage
                  statusLabel:(UILabel *)statusLabel
            activityIndicator:(UIActivityIndicatorView *)activityIndicator;

@end

@implementation DownloadContoller

- (NSString *)getRootPackagePath
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *www = [documentsDirectory stringByAppendingPathComponent:@"/packages/downloads"];
    
    return www;
}

- (NSString *)getThumbPath {
    return [[self getRootPackagePath] stringByAppendingPathComponent:@"/thumbs"];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.tabBarItem = [[[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemDownloads tag:3] autorelease];
        
        self.title = @"Downloads";       
        
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
    
    if(notification.userInfo || [[courseInf objectForKey:@"installed"] boolValue] == YES )
    {
        [self.tableView reloadData];
        [self updateBadge];
    }
    else {
        int downloadStatus = [[courseInf objectForKey:@"status"] intValue];
        bool installed = [[courseInf objectForKey:@"installed"] boolValue];
        NSNumber *downloadPercentage = [courseInf objectForKey:@"percentage"];
        
        NSUInteger index = [[[AppPackageInstaller sharedInstaller] downloadingCourses] indexOfObject:courseInf];
        
        CustomTableViewCell *cell = (CustomTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        
        if (downloadStatus == Failed)
            NSLog(@"download Failed");
        else if (downloadStatus == Cancelled)
            NSLog(@"download Cancelled");
        
        //If we are no longer downloading, ensure that the delete/cancel key is hidden
        if(downloadStatus != Queued && downloadStatus != Downloading)
        {
            if([cell isEditing])
            {
                [cell setEditing:NO];
            } 
        }
        
        
        [self updateUIWithProgress:cell.progressView
                            status:downloadStatus
                         installed:installed
                        percentage:downloadPercentage
                       statusLabel:cell.progressLabel//installedStatusLabel
                 activityIndicator:cell.activityIndicator];
    
    }
}

- (void)dealloc
{    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadStatusChanged" object:nil];
    
    [super dealloc];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

- (void) updateUIWithProgress:(UIProgressView *)progressView
                       status:(DownloadStatus)status
                    installed:(BOOL)installed
                   percentage:(NSNumber *)percentage
                  statusLabel:(UILabel *)statusLabel
           activityIndicator:(UIActivityIndicatorView *)activityIndicator
{    
    if (!installed && status == Finished)
    {
        progressView.hidden = TRUE;         
        statusLabel.hidden = FALSE;
        statusLabel.text = @"installing...";
        [activityIndicator startAnimating];
    }
    else
    {
        activityIndicator.hidden = TRUE;
        [activityIndicator stopAnimating];
        
        if (status == Downloading || status == Connecting)
        {    
            statusLabel.hidden = FALSE;
            
            if (status == Downloading)
            {
                progressView.hidden = FALSE; 
                int friendly = (int)([percentage floatValue] * 100);            
                statusLabel.text = [NSString stringWithFormat:@"%d%%", friendly];            
                progressView.progress = [percentage floatValue];
            }
            else
            {
                statusLabel.text = @"connecting";
                progressView.hidden = TRUE;
            }
        }
        else
        {   
            progressView.hidden = TRUE; 
            
            if (status == NotStarted)
            {                               
                statusLabel.hidden = TRUE;
            }
            else
            {          
                statusLabel.hidden = FALSE;
                
                if (status == Queued)
                    statusLabel.text = @"queued";                
                else if (status == Finished)
                    statusLabel.text = @"installed"; 
                else if (status == Failed || status == Cancelled)
                    statusLabel.text = @"failed";
            } 
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.6 alpha:1];    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
    [self updateBadge];
}

- (void)clearCachedData
{
    [self updateBadge];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) updateBadge{
    
    if ([[[AppPackageInstaller sharedInstaller] downloadingCourses] count] > 0)
        self.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", [[[AppPackageInstaller sharedInstaller] downloadingCourses] count]];
    else
        self.tabBarItem.badgeValue = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[AppPackageInstaller sharedInstaller] downloadingCourses] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    CustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSDictionary *course = [[[[AppPackageInstaller sharedInstaller] downloadingCourses] objectAtIndex:indexPath.row] objectForKey:@"course"];
    
    
    if (cell == nil) {
        cell = [[[CustomTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if ((indexPath.row % 2) == 0)
        cell.customStyle = CustomTableViewCellBasicStyle;
    else
        cell.customStyle = CustomTableViewCellAltStyle;
    
    NSMutableDictionary *courseInfo = [[[AppPackageInstaller sharedInstaller] downloadingCourses] objectAtIndex:indexPath.row];
    
    id status = [courseInfo valueForKey:@"status"];
    
    if (status)
    {
        DownloadStatus downloadStatus = [status intValue]; 
        NSNumber *percentage = [NSNumber numberWithFloat:[[courseInfo valueForKey:@"percentage"] floatValue]];
        bool installed = [[courseInfo valueForKey:@"installed"] boolValue];
        
        [self updateUIWithProgress:cell.progressView
                            status:downloadStatus
                         installed:installed
                        percentage:percentage
                       statusLabel:cell.progressLabel
                 activityIndicator:cell.activityIndicator];  
    }
    else
    {
        [self updateUIWithProgress:cell.progressView
                            status:NotStarted
                         installed:false
                        percentage:0
                       statusLabel:cell.progressLabel
                 activityIndicator:cell.activityIndicator];
    }        
    
    cell.headerLabel.text = [course objectForKey:@"title"];
    
    NSString *courseCode = [course objectForKey:@"courseCode"];
    
    if (courseCode && [courseCode isKindOfClass:[NSString class]])    
        cell.subHeaderLabel.text = [course objectForKey:courseCode];
    
    if ([course objectForKey:@"thumbImg"] != nil)
    {
        NSData *imgData = [course objectForKey:@"thumbImg"];
        cell.leftImageView.image = [UIImage imageWithData:imgData];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {

        //get the relevant course info
        NSDictionary *courseInfo = [[[AppPackageInstaller sharedInstaller] downloadingCourses] objectAtIndex:indexPath.row];       
        NSString *downloadId =[courseInfo objectForKey:@"downloadId"];
        
        //cancel the download
        [[AppPackageInstaller sharedInstaller] cancelDownload:downloadId];
        
        [self.tableView reloadData];
        [self updateBadge];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
     if([[AppPackageInstaller sharedInstaller] downloadingCourses].count > indexPath.row)
     {
        NSDictionary *courseInfo = [[[AppPackageInstaller sharedInstaller] downloadingCourses] objectAtIndex:indexPath.row];
         NSDictionary *course = [courseInfo objectForKey:@"course"];
        PackageState state = [[AppPackageInstaller sharedInstaller] getPackageState:course];
        
        if(state == PackageDownloading || state == PackageQueued || state == PackageFailed)
        {
            return YES;
        }
     }
    return NO;

}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
   /* UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UIProgressView *progressView = (UIProgressView *)[cell.contentView viewWithTag:PROGRESS_VALUE_TAG];
    UILabel *title = (UILabel *)[cell.contentView viewWithTag:TITLE_TAG];
    
    title.frame = CGRectMake(XOFFSET + 2, 2, ROW_DETAIL_WIDTH_COMPRESSED - XOFFSET, 20);
    progressView.frame = CGRectMake(XOFFSET + 2, 23, ROW_DETAIL_WIDTH_COMPRESSED - XOFFSET, 10);*/
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
  /*  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UIProgressView *progressView = (UIProgressView *)[cell.contentView viewWithTag:PROGRESS_VALUE_TAG];
    UILabel *title = (UILabel *)[cell.contentView viewWithTag:TITLE_TAG];
    
    title.frame = CGRectMake(XOFFSET + 2, 2, ROW_DETAIL_WIDTH - XOFFSET, 20);
    progressView.frame = CGRectMake(XOFFSET + 2, 23, ROW_DETAIL_WIDTH - XOFFSET, 10);*/
}

@end
