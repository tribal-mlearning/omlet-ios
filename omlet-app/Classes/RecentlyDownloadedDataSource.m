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

#import "RecentlyDownloadedDataSource.h"
#import "FinderPackage.h"
#import "Framework.h"
#import "PackageInstaller.h"
#import "CustomTableViewCell.h"

@implementation RecentlyDownloadedDataSource

@synthesize courses;
@synthesize tabBarController;

- (void)dealloc {
    self.courses = nil;
    [imageCache release];
    [super dealloc];
}

-(void)setCourses:(NSArray *)_courses
{
    [courses release];
    courses = [_courses retain];
    [imageCache release];
    imageCache = [[NSMutableArray alloc] initWithCapacity:[courses count]];
    downloadsLocation = [[[[UIApplication sharedApplication].delegate class] performSelector:@selector(wwwFolderName)] copy];
    
    for (NSDictionary *course in courses) {
        
        NSString *thumbUrl = [course objectForKey:@"thumbnailUrl"]; 
        NSString *thumbFileName = [thumbUrl lastPathComponent];
        NSString *uniqueId = [course objectForKey:@"uniqueId"];
        NSString *thumbPath = [downloadsLocation stringByAppendingFormat:@"/thumbs/%@_%@", uniqueId, thumbFileName];
        
        if (thumbPath && [[NSFileManager defaultManager] fileExistsAtPath:thumbPath])
            [imageCache addObject:[UIImage imageWithContentsOfFile:thumbPath]];
        else
            [imageCache addObject:[NSNull null]];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger c = [courses count];
    return c;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"Cell";
    
    CustomTableViewCell *cell = (CustomTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[CustomTableViewCell alloc] init] autorelease];
        cell.customStyle = CustomTableViewCellAltStyle;
        cell.headerLabel.font = [UIFont systemFontOfSize:13];
    }
    
    NSDictionary *course = [courses objectAtIndex:indexPath.row];
    
    cell.headerLabel.text = [course objectForKey:@"title"];
    
    NSString *courseCode = [course objectForKey:@"courseCode"];
    
    if (courseCode && [courseCode isKindOfClass:[NSString class]])
        cell.subHeaderLabel.text = courseCode;
    else
        cell.subHeaderLabel.text = @"";
    
    id image = [imageCache objectAtIndex:indexPath.row];
    
    if ([image isKindOfClass:[UIImage class]])
        cell.leftImageView.image = image;
    
    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *path =[[courses objectAtIndex:indexPath.row] objectForKey:@"path"];

    PEBase *entryPoint = [((Framework *)[Framework client]) entryPointForCourseWithPath:path];
    
    [[Framework client] setCurrentPackageTitle:[[courses objectAtIndex:indexPath.row] objectForKey:@"title"]];
    
    //((Framework *)[Framework client]).packagePath = path;
    
    [self.tabBarController setSelectedIndex:1];
    if ([entryPoint isKindOfClass:[PEResource class]])
    {
        //For backwards compatiability, ensure that the entry point used is prepended by the unique course id, 
        //(may be differnet from the id in the package.xml)
        NSArray *strComp = [path pathComponents];
        [[Framework client] openResource:[[strComp objectAtIndex:strComp.count -1] stringByAppendingFormat:@".%@",entryPoint.elementId]];
//        [[Framework client] openResource:[entryPoint getFullId]];
    }
    else if ([entryPoint isKindOfClass:[PEMenu class]])
    {
        //For backwards compatiability, ensure that the entry point used is prepended by the unique course id, 
        //(may be differnet from the id in the package.xml)
        NSArray *strComp = [path pathComponents];
        [[Framework client] openMenu:[[strComp objectAtIndex:strComp.count -1] stringByAppendingFormat:@".%@",entryPoint.elementId]];
//        PEMenu* menu = (PEMenu *)entryPoint;
//        [[Framework client] openMenu:[menu getFullId]];
    }

}

@end
