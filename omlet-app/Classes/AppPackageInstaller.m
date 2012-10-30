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

#import "AppPackageInstaller.h"

@implementation AppPackageInstaller

static AppPackageInstaller *sharedInstance = nil;

+ (AppPackageInstaller *)sharedInstaller
{
    @synchronized (self) {
        if (sharedInstance == nil) {
            [[self alloc] init];
        }
    }
    
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;
        }
    }
    
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (oneway void)release
{
    // do nothing
}

- (id)autorelease
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax; // This is sooo not zero
}


//Overridden to perform project-specific processing of course files
//after they are unpacked
-(BOOL)processCourseFilesAfterUnpacking:(NSDictionary *)course
{
    // copy image
    NSData *imageData = [course objectForKey:@"thumbImg"];
    
    NSString *thumbUrl = [course objectForKey:@"thumbnailUrl"]; 
    NSString *thumbFileName = [thumbUrl lastPathComponent];
    
    NSString *packageFolderName = [course objectForKey:@"uniqueId"];
    
    NSString *thumbPath = [[self getThumbPath] stringByAppendingFormat:@"/%@_%@", packageFolderName, thumbFileName];
    [imageData writeToFile:thumbPath atomically:YES];
    
    // copy .js files             
    NSString *packagePath = [self getPackagePath:course];
    //[[self getRootPackagePath] stringByAppendingFormat:@"/%@", packageFolderName];
    
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *sourcePath = [bundlePath stringByAppendingString:@"/www"];
    
    NSError *error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sourcePath error:&error];
    BOOL success = NO;
    
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
    
    if(!success)
    {
        NSLog(@"install failed: %@", error);
    }
    
    return success;
}

-(NSDictionary*)getFileDataForCourse:(NSDictionary *)course
{
    NSArray *files = [course objectForKey:@"files"];
    NSDictionary *selectedFile = nil;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    if (files && files.count > 0)
    {
        selectedFile = [files objectAtIndex:0];
    }
    
    NSInteger previousWidth = 0;
    NSInteger previousHeight =0;
    for(NSDictionary *file in files)
    {
        NSDictionary *size = [file objectForKey:@"metadata"];
        int minWidth = 0;
        int minHeight = 0;
        
        if([size count] > 0)
        {
            minWidth = [[NSString stringWithFormat:@"%d",[size objectForKey:@"deviceMinWidth"]] intValue];
            minHeight = [[NSString stringWithFormat:@"%d",[size objectForKey:@"deviceMinHeight"]] intValue];
            
            if (minWidth <= screenSize.width && minWidth > previousWidth
                && minHeight <= screenSize.height && minHeight > previousHeight) {
                
                previousWidth = minWidth;
                previousHeight = minHeight;
                selectedFile = file;
            }
        }
        else {
            previousWidth = minWidth;
            previousHeight = minHeight;
            selectedFile = file;
        }
    }
    
    return selectedFile;
}


-(float)getFreeDiskspace {
    
    float freeSpaceInKB = 0;
    NSError *error = nil;  
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);  
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];  
    
    if (dictionary) {  
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];  
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        float totalSpace = [fileSystemSizeInBytes floatValue];
        
        
        float totalFreeSpace = [freeFileSystemSizeInBytes floatValue];
        NSLog(@"Memory Capacity of %f MiB with %f MiB Free memory available.", ((totalSpace/1024.0f)/1024.0f), ((totalFreeSpace/1024.0f)/1024.0f));
        
        freeSpaceInKB = totalFreeSpace / 1024;
        
    } else {  
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %@", [error domain], [error code]);  
    }  
    
    return freeSpaceInKB;
}

- (float)estimateCourseSpace:(NSDictionary *)course{
    id size = [course objectForKey:@"size"];
    
    if (size)
        return [size floatValue] * 2.1;
    else
        return 0;
}

- (void) canDownloadCourse:(NSDictionary *) course callback:(CheckDownloadCallback)callback
{
    NSString *message = @"";
    
    float freeSpace = [self getFreeDiskspace];
    if (freeSpace > 0 && freeSpace < [self estimateCourseSpace:course])
    {
        message = @"There is not enough space on the device to download this file.";
    }
    
    float sizeInKb = [self getSizeOfCourse:course];
    
    if (sizeInKb > 0)
    {
        float sizeInMb = sizeInKb / 1024;
        
        if (self.netStatus == ReachableViaWiFi && sizeInMb > 10)
        {
            if (message.length > 0)
                message = [message stringByAppendingString:@"\n\n"];
            
            message = [message stringByAppendingString:@"The course is over 10MB and will be downloaded over WiFi."];
        }
        else if (self.netStatus == ReachableViaWWAN & sizeInMb > 5)
        {
            if (message.length > 0)
                message = [message stringByAppendingString:@"\n\n"];
            
            message = [message stringByAppendingString:@"The course is over 5MB and will be downloaded over 3G."];
        }
        
        if (sizeInMb > 50)
        {
            if (message.length > 0)
                message = [message stringByAppendingString:@"\n\n"];
            
            message = [message stringByAppendingString:@"The course is over the recommended size (50MB)."];
        }
    }
    
    if (message.length > 0)
    {
        if (canDownloadCallback)
        {
            [canDownloadCallback release];
            canDownloadCallback = nil;
        }
        
        canDownloadCallback = [callback copy];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Download Warning" 
                                                        message:message
                                                       delegate:self 
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Continue", nil];
        [alert show];
        [alert release];
        
    }
    else
    {
        callback(YES);
    }       
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (canDownloadCallback)
    {
        if (buttonIndex == 0)
            canDownloadCallback(NO);
        else
            canDownloadCallback(YES);
        
        [canDownloadCallback release];
        canDownloadCallback = nil;
    }
}

- (void) clearFailedDownloads{
    
    for (int i=0; i< [self downloadingCourses].count; i++)
    {
        NSDictionary *course = [[self downloadingCourses] objectAtIndex:i];
        
        if ([self getPackageState:course] == PackageFailed)
        {
            [[self downloadingCourses] removeObject:course];
            i--;
        }  
    }
}

@end
