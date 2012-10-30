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

#import "CourseController.h"
#import "FinderPackage.h"
#import "Framework.h"
#import "PackageInstaller.h"
#import "CustomTableViewCell.h"
#import "EmptyDataCell.h"
#import "AppPackageInstaller.h"
#import "SettingsTable.h"

@interface CourseController ()

@end

@implementation CourseController
@synthesize infoView;
@synthesize versionInfo;
@synthesize cnView;
@synthesize delegate, mainMenu, tabGradient;

+ (BOOL) copyJSFiles:(NSString *)packagePath
{
    BOOL success = NO;
    
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *sourcePath = [bundlePath stringByAppendingString:@"/www"];
    
    NSError *error = nil;    
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sourcePath error:&error];
    
    if (files)
    {  
        NSString *file;    
        
        for (file in files) {
            if ([[file pathExtension] isEqualToString: @"js"]) {
                
                NSString *destinationPath = [packagePath stringByAppendingFormat:@"/%@", file];
                
                if ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath])
                {
                    BOOL deleted = [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:&error];
                    
                    if (!deleted)
                    {
                        success = NO;
                        break;
                    }
                    else
                        NSLog(@"File %@ deleted, it already existed.", file);
                }
                
                BOOL copied = [[NSFileManager defaultManager] copyItemAtPath:[sourcePath stringByAppendingFormat:@"/%@", file]
                                                                      toPath:destinationPath
                                                                       error:&error];
                
                if (copied) { 
                    success = YES;
                    error = nil;
                } else {
                    success = NO;
                    break;
                }
            }
        }
    }
    
    return success;  
}

+(void) installPackage:(NSString *)source {
            
    NSString *packageName = [source lastPathComponent];
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
    NSString *destinationPath = [documentsDirectory stringByAppendingFormat:@"/packages/downloads/%@", packageName];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:[documentsDirectory stringByAppendingPathComponent:@"/packages/downloads"]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *sourcePath = [bundlePath stringByAppendingFormat:@"/www/preInstalledPackages/%@", packageName];
    
    BOOL success = NO;    
    BOOL isInstalled = NO;
    
    NSArray *packageList = [PackageInstaller getPackageList];
    
    for (NSDictionary *package in packageList) {
        if ([[package objectForKey:@"package_id"] isEqualToString:packageName])
        {
            isInstalled = YES;
            success = TRUE;
            break;
        }
            
    }
    
    if (!isInstalled)
    {           
        NSError *error = nil;
        
        // COPY DIR
        error = nil;
        success = [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:& error];

        if (success)
        {
            success = [CourseController copyJSFiles:destinationPath];
            
            if (success)
            { 
                NSString *imageUrl = [NSString stringWithFormat:@"http://jpreInstalled/%@.png", packageName];
                
                NSDictionary *course = [NSDictionary dictionaryWithObjectsAndKeys:        
                                        @"For Tribal testing only.", @"description",
                                        packageName, @"uniqueId",
                                        @"Tribal", @"organisation",
                                        packageName, @"package_id",
                                        destinationPath, @"path",
                                        @"10", @"size",
                                        imageUrl, @"thumbnailUrl",
                                        [@"TRIBAL " stringByAppendingString:packageName], @"title",
                                        @"tribal", @"username",
                                        nil];
                
                [PackageInstaller savePackage:course];
                
                NSLog(@"package installed:%@", packageName); 
            }
        }
        else
            NSLog(@"Error: %@", error);
        
    }
}

+(void) installPreInstalledPackages{
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *www = [bundlePath stringByAppendingFormat:@"/www/preInstalledPackages"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:www] == NO) return;
    
    NSError *error;
    
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:www error:&error];
    
    if (files)
    {
        for (NSString *file in files) {
            
            BOOL isDir;
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:[www stringByAppendingFormat:@"/%@", file] isDirectory:&isDir])
            {
                if (isDir)
                    [self installPackage:file];
            }
        }       
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithNibName:@"CourseController" bundle:nil];
    if (self) {
        self.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Courses" image:
                            [UIImage imageNamed:@"mycourses.png"] tag:1] autorelease];
        self.title = @"On Device";
        downloadsLocation = [[[[UIApplication sharedApplication].delegate class] performSelector:@selector(wwwFolderName)] copy];
        
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Menu" style:
                                                  UIBarButtonItemStylePlain target:self action:@selector(showMenu:)] autorelease];
        
             
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(downloadItemStatusChanged:)
                                                     name:@"DownloadStatusChanged"
                                                   object:nil ];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(downloadQueueChanged:) 
                                                     name:@"DownloadQueueChanged" 
                                                   object:nil];
    }
    return self;
}

- (void)showMenu:(id)sender {
    if (mainMenu && mainMenu.view.window == nil) { 
        [self.view.window addSubview:mainMenu.view];
        [self.view.window bringSubviewToFront:self.tabBarController.view];
    }
    [UIView animateWithDuration:0.5 animations:^() {
        CGRect rect = self.tabBarController.view.frame;
        if (rect.origin.x == 0) { 
            rect.origin.x = 240;
            tabGradient.hidden = NO;
        } else rect.origin.x = 0;
        self.tabBarController.view.frame = rect;
    } completion:^(BOOL finished) {
        if (finished && self.tabBarController.view.frame.origin.x == 0) {
            tabGradient.hidden = YES;
            if (mainMenu.view.window) [mainMenu.view removeFromSuperview];
        }
    }];
}


- (void) updateBadge{
    
    if ([[[AppPackageInstaller sharedInstaller] downloadingCourses] count] > 0)
        self.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", [[[AppPackageInstaller sharedInstaller] downloadingCourses] count]];
    else
        self.tabBarItem.badgeValue = nil;
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

-(void)downloadItemStatusChanged: (NSNotification *) notification
{
    NSDictionary *courseInf = (NSDictionary*)notification.object;
    NSDictionary *course = [courseInf objectForKey:@"course"];
    
    PackageState pState = [[AppPackageInstaller sharedInstaller] getPackageState:course];
    if(pState == PackageQueued) 
    {
        if(self.isViewLoaded)
        {
            [self refresh];
        }
    }
    if(pState == PackageInstalled)
    {
        int index = NSNotFound;
        for (int i = 0; i < courses.count; i++){
            if([[[courses objectAtIndex:i] objectForKey:@"uniqueId"] isEqualToString:[course objectForKey:@"uniqueId"]])
            {
                index = i;
                break;
            }
        }
        
        if(index != NSNotFound){
            [courses removeObjectAtIndex:index];
        }

        [courses addObject:course];
        
        if(self.isViewLoaded)
        {
            [self refresh];
        }
    }
    else
    {
        int downloadStatus = [[courseInf objectForKey:@"status"] intValue];
        bool installed = [[courseInf objectForKey:@"installed"] boolValue];
        NSNumber *downloadPercentage = [courseInf objectForKey:@"percentage"];
        
        NSUInteger index = [[[AppPackageInstaller sharedInstaller] downloadingCourses] indexOfObject:courseInf];
        
        CustomTableViewCell *cell = (CustomTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        
        if (downloadStatus == Failed)
            NSLog(@"download Failed");
        else if (downloadStatus == Cancelled)
            NSLog(@"download Cancelled");
        
        if ([cell isKindOfClass:[CustomTableViewCell class]])
        {        
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
        
        [self updateBadge];
    }
    
    
}

-(void)downloadQueueChanged:(NSNotification *) notification
{
    [self refresh];
}   

- (id)getPackageList {
    NSString *packageList = [downloadsLocation stringByAppendingPathComponent:@"/packages.plist"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:packageList]) {
        NSPropertyListFormat format;
        NSString *error;
        
        id plist = [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfFile:packageList]
                                                    mutabilityOption:NSPropertyListMutableContainers
                                                              format:&format
                                                    errorDescription:&error];
        return plist;
    }
    return nil;
}

- (void)dealloc {
    [downloadsLocation release];
    [images release];
    [courses release];
    [infoView release];
    [versionInfo release];
    [cnView release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    versionInfo.text = [@"Version " stringByAppendingFormat:@"%@", [info objectForKey:@"CFBundleVersion"]];
    
    infoView.frame = [UIScreen mainScreen].applicationFrame;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = infoView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0 green:0.0 blue:0.498 alpha:1.0] CGColor], 
                       (id)[[UIColor colorWithRed:0.0 green:0.0 blue:0.737 alpha:1.0] CGColor], nil];
    [infoView.layer insertSublayer:gradient atIndex:0];
    
    UITextView *tv = (UITextView *) [cnView viewWithTag:10];
    tv.text = @"Application and source code distributed and licensed under the following BSD-style license:\n\nCopyright 2012 TATRC and Tribal.\nhttp://www.tatrc.org/\nhttp://www.tribalgroup.com/\n\nRedistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:\n\n1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.\n\n2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.\n\n3. The name of the author may not be used to endorse or promote products derived from this software without specific prior written permission.\n\nTHIS SOFTWARE IS PROVIDED BY TATRC AND TRIBAL \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.";
    
    CGRect rect = tv.frame;
    rect.size.height = tv.contentSize.height;
    tv.frame = rect;
    
    UILabel *lbl = (UILabel *)[cnView viewWithTag:15];
    rect = lbl.frame;
    rect.origin.y = tv.frame.origin.y + tv.frame.size.height;
    lbl.frame = rect;
    
    tv = (UITextView *) [cnView viewWithTag:20];
    tv.text = @"PhoneGap library v1.3\nhttp://www.phonegap.com/\nLicensed under the Apache License, Version 2.0.\n\nSimple XML Serialization framework\nhttp://simple.sourceforge.net/\nLicensed under the Apache License, Version 2.0.\n\nGoogle-GSON JSON library\nhttp://code.google.com/p/google-gson/\nLicensed under the Apache License, Version 2.0.\n\nAndroid v4 support library\nhttp://developer.android.com/tools/extras/support-library.html\nLicensed under the Apache License, Version 2.0.\n\nActionBarSherlock library\nCopyright 2012 Jake Wharton\nhttp://actionbarsherlock.com/\nLicensed under the Apache License, Version 2.0.\n\nAndroid-related icons shared by Google\nLicensed under the Creative Commons 3.0 Attribution License\nhttp://creativecommons.org/license/by/3.0/";
    
    rect = tv.frame;
    rect.origin.y = lbl.frame.origin.y + lbl.frame.size.height;
    rect.size.height = tv.contentSize.height;
    tv.frame = rect;
    
    lbl = (UILabel *)[cnView viewWithTag:25];
    rect = lbl.frame;
    rect.origin.y = tv.frame.origin.y + tv.frame.size.height;
    lbl.frame = rect;
    
    tv = (UITextView *) [cnView viewWithTag:30];
    tv.text = @"Version 2.0, January 2004\n\nhttp://www.apache.org/licenses/\n\nTERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION\n\n1. Definitions\n\"License\" shall mean the terms and conditions for use, reproduction, and distribution as defined by Sections 1 through 9 of this document.\n\n\"Licensor\" shall mean the copyright owner or entity authorized by the copyright owner that is granting the License.\n\n\"Legal Entity\" shall mean the union of the acting entity and all other entities that control, are controlled by, or are under common control with that entity. For the purposes of this definition, \"control\" means (i) the power, direct or indirect, to cause the direction or management of such entity, whether by contract or otherwise, or (ii) ownership of fifty percent (50%) or more of the outstanding shares, or (iii) beneficial ownership of such entity.\n\n\"You\" (or \"Your\") shall mean an individual or Legal Entity exercising permissions granted by this License.\n\n\"Source\" form shall mean the preferred form for making modifications, including but not limited to software source code, documentation source, and configuration files.\n\n\"Object\" form shall mean any form resulting from mechanical transformation or translation of a Source form, including but not limited to compiled object code, generated documentation, and conversions to other media types.\n\n\"Work\" shall mean the work of authorship, whether in Source or Object form, made available under the License, as indicated by a copyright notice that is included in or attached to the work (an example is provided in the Appendix below).\n\n\"Derivative Works\" shall mean any work, whether in Source or Object form, that is based on (or derived from) the Work and for which the editorial revisions, annotations, elaborations, or other modifications represent, as a whole, an original work of authorship. For the purposes of this License, Derivative Works shall not include works that remain separable from, or merely link (or bind by name) to the interfaces of, the Work and Derivative Works thereof.\n\n\"Contribution\" shall mean any work of authorship, including the original version of the Work and any modifications or additions to that Work or Derivative Works thereof, that is intentionally submitted to Licensor for inclusion in the Work by the copyright owner or by an individual or Legal Entity authorized to submit on behalf of the copyright owner. For the purposes of this definition, \"submitted\" means any form of electronic, verbal, or written communication sent to the Licensor or its representatives, including but not limited to communication on electronic mailing lists, source code control systems, and issue tracking systems that are managed by, or on behalf of, the Licensor for the purpose of discussing and improving the Work, but excluding communication that is conspicuously marked or otherwise designated in writing by the copyright owner as \"Not a Contribution.\"\n\n\"Contributor\" shall mean Licensor and any individual or Legal Entity on behalf of whom a Contribution has been received by Licensor and subsequently incorporated within the Work.\n\n2. Grant of Copyright License\nSubject to the terms and conditions of this License, each Contributor hereby grants to You a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable copyright license to reproduce, prepare Derivative Works of, publicly display, publicly perform, sublicense, and distribute the Work and such Derivative Works in Source or Object form.\n\n3. Grant of Patent License\nSubject to the terms and conditions of this License, each Contributor hereby grants to You a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable (except as stated in this section) patent license to make, have made, use, offer to sell, sell, import, and otherwise transfer the Work, where such license applies only to those patent claims licensable by such Contributor that are necessarily infringed by their Contribution(s) alone or by combination of their Contribution(s) with the Work to which such Contribution(s) was submitted. If You institute patent litigation against any entity (including a cross-claim or counterclaim in a lawsuit) alleging that the Work or a Contribution incorporated within the Work constitutes direct or contributory patent infringement, then any patent licenses granted to You under this License for that Work shall terminate as of the date such litigation is filed.\n\n4. Redistribution\nYou may reproduce and distribute copies of the Work or Derivative Works thereof in any medium, with or without modifications, and in Source or Object form, provided that You meet the following conditions:\n\nYou must give any other recipients of the Work or Derivative Works a copy of this License; and\nYou must cause any modified files to carry prominent notices stating that You changed the files; and\nYou must retain, in the Source form of any Derivative Works that You distribute, all copyright, patent, trademark, and attribution notices from the Source form of the Work, excluding those notices that do not pertain to any part of the Derivative Works; and\nIf the Work includes a \"NOTICE\" text file as part of its distribution, then any Derivative Works that You distribute must include a readable copy of the attribution notices contained within such NOTICE file, excluding those notices that do not pertain to any part of the Derivative Works, in at least one of the following places: within a NOTICE text file distributed as part of the Derivative Works; within the Source form or documentation, if provided along with the Derivative Works; or, within a display generated by the Derivative Works, if and wherever such third-party notices normally appear. The contents of the NOTICE file are for informational purposes only and do not modify the License. You may add Your own attribution notices within Derivative Works that You distribute, alongside or as an addendum to the NOTICE text from the Work, provided that such additional attribution notices cannot be construed as modifying the License. You may add Your own copyright statement to Your modifications and may provide additional or different license terms and conditions for use, reproduction, or distribution of Your modifications, or for any such Derivative Works as a whole, provided Your use, reproduction, and distribution of the Work otherwise complies with the conditions stated in this License.\n\n5. Submission of Contributions\nUnless You explicitly state otherwise, any Contribution intentionally submitted for inclusion in the Work by You to the Licensor shall be under the terms and conditions of this License, without any additional terms or conditions. Notwithstanding the above, nothing herein shall supersede or modify the terms of any separate license agreement you may have executed with Licensor regarding such Contributions.\n\n6. Trademarks\nThis License does not grant permission to use the trade names, trademarks, service marks, or product names of the Licensor, except as required for reasonable and customary use in describing the origin of the Work and reproducing the content of the NOTICE file.\n\n7. Disclaimer of Warranty\nUnless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an \"AS IS\" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including, without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR PURPOSE. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License.\n\n8. Limitation of Liability\nIn no event and under no legal theory, whether in tort (including negligence), contract, or otherwise, unless required by applicable law (such as deliberate and grossly negligent acts) or agreed to in writing, shall any Contributor be liable to You for damages, including any direct, indirect, special, incidental, or consequential damages of any character arising as a result of this License or out of the use or inability to use the Work (including but not limited to damages for loss of goodwill, work stoppage, computer failure or malfunction, or any and all other commercial damages or losses), even if such Contributor has been advised of the possibility of such damages.\n\n9. Accepting Warranty or Additional Liability\nWhile redistributing the Work or Derivative Works thereof, You may choose to offer, and charge a fee for, acceptance of support, warranty, indemnity, or other liability obligations and/or rights consistent with this License. However, in accepting such obligations, You may act only on Your own behalf and on Your sole responsibility, not on behalf of any other Contributor, and only if You agree to indemnify, defend, and hold each Contributor harmless for any liability incurred by, or claims asserted against, such Contributor by reason of your accepting any such warranty or additional liability.\n\nEND OF TERMS AND CONDITIONS";
    
    rect = tv.frame;
    rect.origin.y = lbl.frame.origin.y + lbl.frame.size.height;
    rect.size.height = tv.contentSize.height;
    tv.frame = rect;
    
    CGSize cSize = cnView.contentSize;
    cSize.height = tv.frame.origin.y + tv.frame.size.height;
    cnView.contentSize = cSize;

}

- (void) filterCourses
{
    for (int i = 0; i < courses.count; i++) {
        for (NSDictionary*downloadingCourseInfo in [[AppPackageInstaller sharedInstaller] downloadingCourses]) {
            
            NSDictionary* installedCourse = [courses objectAtIndex:i];
            NSDictionary* downloadingCourse = [downloadingCourseInfo valueForKey:@"course"];
            
            if([[installedCourse objectForKey:@"uniqueId"] isEqualToString:[downloadingCourse objectForKey:@"uniqueId"]])
            {
                [courses removeObject:installedCourse];
                i--;
                break;
            }
        }
    }
}

- (void) refresh
{
    if (courses) {
        [courses release];
        courses = nil;
    }
    
    courses = [[NSMutableArray alloc] initWithArray:[self getPackageList]];    
    [self filterCourses];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:TRUE selector:@selector(caseInsensitiveCompare:)];
    [courses sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    
    if (images)
    {
        [images release]; 
        images = nil;
    }
    
    images = [[NSMutableArray alloc] initWithCapacity:[courses count]];
    
    for (NSDictionary *course in courses) {
        
        NSString *thumbUrl = [course objectForKey:@"thumbnailUrl"]; 
        NSString *thumbFileName = [thumbUrl lastPathComponent];
        NSString *uniqueId = [course objectForKey:@"uniqueId"];
        NSString *thumbPath = [downloadsLocation stringByAppendingFormat:@"/thumbs/%@_%@", uniqueId, thumbFileName];
        
        if (thumbPath && [[NSFileManager defaultManager] fileExistsAtPath:thumbPath])
            [images addObject:[UIImage imageWithContentsOfFile:thumbPath]];
        else
            [images addObject:[NSNull null]];
    }
    
    [self.tableView reloadData];
    [self updateBadge];
}



- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
        
    [self refresh];
}

- (void)viewDidUnload
{
    [self setInfoView:nil];
    [self setVersionInfo:nil];
    [self setCnView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSUInteger) itemCount{
    return [[[AppPackageInstaller sharedInstaller] downloadingCourses] count] + [courses count];   
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if([self itemCount] == 0){
        tableView.scrollEnabled = NO;
        return 1; //Allow generation of empty data message
    }
    else {
        tableView.scrollEnabled = YES;
        return [self itemCount];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([self itemCount] !=0)
    {
        static NSString *CellIdentifier = @"Cell";
        CustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[[CustomTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        }
        
        if ((indexPath.row % 2) == 0)
            cell.customStyle = CustomTableViewCellBasicStyle;
        else
            cell.customStyle = CustomTableViewCellAltStyle;
        
        BOOL installedCourse = indexPath.row >= [[[AppPackageInstaller sharedInstaller] downloadingCourses] count];
        
        if (installedCourse)
        {            
            NSInteger row = indexPath.row - [[[AppPackageInstaller sharedInstaller] downloadingCourses] count];
            
            cell.headerLabel.text = [[courses objectAtIndex:row] objectForKey:@"title"];
                        
            NSString *courseCode = [[courses objectAtIndex:row] objectForKey:@"courseCode"];
            
            if (courseCode && [courseCode isKindOfClass:[NSString class]])
                cell.subHeaderLabel.text = courseCode;
            else
                 cell.subHeaderLabel.text = @"";
                        
            id image = [images objectAtIndex:row];
            
            if ([image isKindOfClass:[UIImage class]])
                cell.leftImageView.image = image;
            else
                cell.leftImageView.image = nil;
            
            cell.progressLabel.hidden = YES;
            cell.progressView.hidden = YES;
            [cell.activityIndicator stopAnimating];
            
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
        else
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            NSMutableDictionary *courseInfo = [[[AppPackageInstaller sharedInstaller] downloadingCourses] objectAtIndex:indexPath.row];
            NSDictionary *downloadingCourse = [courseInfo objectForKey:@"course"];
            
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
            
            cell.headerLabel.text = [downloadingCourse objectForKey:@"title"];
            
            NSString *courseCode = [downloadingCourse objectForKey:@"courseCode"];
            
            if (courseCode && [courseCode isKindOfClass:[NSString class]])
                cell.subHeaderLabel.text = courseCode;            
            else
                cell.subHeaderLabel.text = @"";
            
            if ([downloadingCourse objectForKey:@"thumbImg"] != nil)
            {
                NSData *imgData = [downloadingCourse objectForKey:@"thumbImg"];
                cell.leftImageView.image = [UIImage imageWithData:imgData];
            }
            else
            {
                cell.leftImageView.image = nil;
            }
        }
        
        return cell;
    }
    else {
        EmptyDataCell *cell = [[[EmptyDataCell alloc] init] autorelease];
        
        cell.message.text = NSLocalizedString(@"NoCoursesDownloaded", @""); 
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row - [[[AppPackageInstaller sharedInstaller] downloadingCourses] count];
    
    if (row <= -1)
    {
        NSDictionary *download = [[[AppPackageInstaller sharedInstaller] downloadingCourses] objectAtIndex:indexPath.row];
        
        if ([[AppPackageInstaller sharedInstaller] getPackageState:[download objectForKey:@"course"]] == PackageFailed)
        {
            NSString *error = [download objectForKey:@"downloadError"];
            
            if (error)
                error = [@"Unable to download course. " stringByAppendingString:error];
            else
                error = @"Unable to download course";
            
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Download Failed" 
                                                             message:error 
                                                            delegate:nil
                                                   cancelButtonTitle:NSLocalizedString(@"DialogOK", @"")
                                                   otherButtonTitles:nil] autorelease];
            [alert show];
        }
        
        return;
    }
    
    NSString *path =[[courses objectAtIndex:row] objectForKey:@"path"];
    
    PEBase *entryPoint = [((Framework *)[Framework client]) entryPointForCourseWithPath:path];
    
    if (entryPoint == nil) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"No package found" message:
                               @"Error no Package.xml found" delegate:nil cancelButtonTitle:
                               NSLocalizedString(@"DialogOK", @"") otherButtonTitles:nil] autorelease];
        [alert show];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    [[Framework client] setCurrentPackageTitle:[[courses objectAtIndex:row] objectForKey:@"title"]];
    
    //((Framework *)[Framework client]).packagePath = path;
    
    if ([entryPoint isKindOfClass:[PEResource class]])
    {        
        //For backwards compatiability, ensure that the entry point used is prepended by the unique course id, 
        //(may be differnet from the id in the package.xml)
        NSArray *strComp = [path pathComponents];
        [[Framework client] openResource:
         [[strComp objectAtIndex:strComp.count -1] stringByAppendingFormat:@".%@",entryPoint.elementId]];
    }
    else if ([entryPoint isKindOfClass:[PEMenu class]])
    {       
        //For backwards compatiability, ensure that the entry point used is prepended by the unique course id, 
        //(may be differnet from the id in the package.xml)
        NSArray *strComp = [path pathComponents];
        [[Framework client] openMenu:[[strComp objectAtIndex:strComp.count -1] stringByAppendingFormat:@".%@",entryPoint.elementId]];
    }
}

-(void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath {
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSInteger courseRow = indexPath.row - [[[AppPackageInstaller sharedInstaller] downloadingCourses] count];
        
        if (courseRow <= -1)
        {       
            //get the relevant course info
            NSDictionary *courseInfo = [[[AppPackageInstaller sharedInstaller] downloadingCourses] objectAtIndex:indexPath.row];       
            NSString *downloadId =[courseInfo objectForKey:@"downloadId"];
            
            //cancel the download
            [[AppPackageInstaller sharedInstaller] cancelDownload:downloadId];                        
        }
        else
        {                
            id packageId = [[courses objectAtIndex:courseRow] objectForKey:@"package_id"];
            
            if (delegate)
                [delegate removeCourseData:packageId];   
            
            [PackageInstaller removePackage:packageId];
            
            SettingsTable *st = [SettingsTable new];
            [st deleteRowsWithPackageId:packageId];
            [st release];
            
            [courses removeObjectAtIndex:courseRow];                 
        }
        
        [self refresh];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger courseRow = indexPath.row - [[[AppPackageInstaller sharedInstaller] downloadingCourses] count];
    
    if (courseRow <= -1)
        return @"Cancel";
    else
        return @"Delete";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger courseRow = indexPath.row - [[[AppPackageInstaller sharedInstaller] downloadingCourses] count];
    
    if (courseRow <= -1)
    {
        NSDictionary *courseInfo = [[[AppPackageInstaller sharedInstaller] downloadingCourses] objectAtIndex:indexPath.row];
        NSDictionary *course = [courseInfo objectForKey:@"course"];
        PackageState state = [[AppPackageInstaller sharedInstaller] getPackageState:course];
        
        if(state == PackageDownloading || state == PackageQueued || state == PackageFailed)
        {
            return YES;
        }
        else
            return NO;
    }
    
    if (courseRow >= courses.count)
        return NO;
    
    NSDictionary *course = [courses objectAtIndex:courseRow];
    
    NSString *packageId = [course objectForKey:@"package_id"];
    
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *www = [bundlePath stringByAppendingFormat:@"/www/preInstalledPackages"];
    
    NSError *error;
    
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:www error:&error];
    
    if (files)
    {
        for (NSString *file in files) {
            if ([file isEqualToString:packageId])
                return NO;
        }
    }
    
    return YES;
}

- (void)showInfo {
    [self.view.window addSubview:infoView];
}

- (IBAction)closeInfo:(id)sender {
    [infoView removeFromSuperview];
}

@end
