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

#import "PackageInstaller.h"
#import "DownloadManager.h"
#import "ZipHelper.h"

@interface PackageInstaller ()
//- (void) cancelDownloads;
- (void) clearFailedDownloads;
@end


@implementation PackageInstaller

@synthesize downloadingCourses;
@synthesize netStatus;

static NSMutableArray *packageList; ///< package list

- (id)init
{
    self = [super init];
    
    if (self) {
        downloadManager =  [[DownloadManager alloc] initWithCapacity:3]; 
        downloadingCourses = [[NSMutableArray alloc] init];
    }
    
    return self;
}

//should never be called, this class is singleton
- (void)dealloc{
    [downloadManager release];
    if(downloadingCourses != nil){
        [downloadingCourses release];
    }
    [super dealloc];
}

- (void)setNetStatus:(NetworkStatus)_netStatus
{
    if (netStatus != _netStatus)
    {
        netStatus = _netStatus;
        
        if (netStatus == 0) 
            [self cancelDownloads];
        else 
            [self clearFailedDownloads];        
    }
}

-(void)cancelDownloads{
    [downloadManager cancelAllDownloads];
    [downloadingCourses removeAllObjects];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadQueueChanged" object:nil];
}

-(void)cancelDownload:(NSString *)downloadId
{
    [downloadManager cancelDownload:downloadId];
    
    NSDictionary *course = nil;
    for(NSDictionary *c in downloadingCourses)
    {
        if([[c objectForKey:@"downloadId"] isEqualToString:downloadId])
        {
            course = c;
            break;
        }
    }
    
    if(course != nil)
    {
        [downloadingCourses removeObject:course];
    }
}

- (void) beginDownloadCourse:(NSDictionary *)course imageData:(NSData *)imageData {
    
    NSMutableDictionary *courseInfo = [NSMutableDictionary dictionaryWithDictionary:course];
    
    [courseInfo setObject:imageData forKey:@"thumbImg"];
    
    
    NSString *packageUId = [course objectForKey:@"uniqueId"];
    
    NSString *zipDestination = [[PackageInstaller getRootPackagePath] stringByAppendingFormat:@"/%@.zip", packageUId];
    NSString *folderDestination = [[PackageInstaller getRootPackagePath] stringByAppendingFormat:@"/%@/", packageUId];    
        
    [self downloadCourse:courseInfo
             destination:folderDestination 
downloadTempFileLocation:zipDestination 
         cleanupTempFile:TRUE];  
}

- (void) downloadCourse:(NSDictionary *)course imageData:(NSData *)imageData {
    
    NSMutableDictionary *courseInfo = [NSMutableDictionary dictionaryWithObject:course forKey:@"course"];
    [courseInfo setObject:[NSNumber numberWithInt:PackageQueued] forKey:@"packageState"];
    
    //Raise notification indicating that the download status has changed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadStatusChanged" object:courseInfo];
    
    if([course valueForKey:@"thumbnailUrl"] == nil)
    {
        [self beginDownloadCourse:course imageData:UIImageJPEGRepresentation([UIImage imageNamed:@"placeholder.png"], 1.0)];
    }
    else {
        if (imageData == nil)
        {
            [[[Download alloc] initWithUrl:[course valueForKey:@"thumbnailUrl"] downloadCompleted:^(Download *download, NSData *data) {
                
                if (data)
                    [self beginDownloadCourse:course imageData:data];
                else {
                    [self beginDownloadCourse:course imageData:UIImageJPEGRepresentation([UIImage imageNamed:@"placeholder.png"], 1.0)];
                }
                [download release];
            }] start];
        }
        else
        {
            [self beginDownloadCourse:course imageData:imageData];
        }
    }
}

- (void) downloadCourse:(NSMutableDictionary*)course
            destination:(NSString *)destination
downloadTempFileLocation:(NSString *)downloadTempFileLocation
        cleanupTempFile:(BOOL)cleanupTempFile
{
    //Choose the file that we want to download for this package
    NSDictionary *fileData = [self getFileDataForCourse:course];
    
    NSString *url = [fileData objectForKey:@"url"]; 
    float fileSize = [[fileData objectForKey:@"size"] floatValue] * 1024;

    [course setObject:[fileData objectForKey:@"version"] forKey:@"version"];
    
    NSMutableDictionary *courseInfo = [NSMutableDictionary dictionaryWithObject:course forKey:@"course"];
    [courseInfo setValue:0 forKey:@"percentage"];
    
    //Add the download to collection
    [self.downloadingCourses addObject:courseInfo];
       
    [downloadManager enqueueDownload:url withAuth:YES expectedSize:fileSize destination:downloadTempFileLocation progressChanged:^(Download *download, DownloadStatus status, NSNumber *percentage) {

        //Update download status
        [courseInfo setValue:download.identifier forKey:@"downloadId"];
        [courseInfo setValue:[NSNumber numberWithInt:status] forKey:@"status"];
        [courseInfo setValue:percentage forKey:@"percentage"];
        
        //Raise notification indicating that the download status has changed
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadStatusChanged" object:courseInfo];
        
        if (status == Failed)
        {
            [courseInfo setValue:download.errorDescription forKey:@"downloadError"];
        }        
        else if (status == Finished)
        {            
            NSMutableDictionary *crse = [courseInfo objectForKey:@"course"];
            
            //Check if the course already exists, and remove it (when updating pacakges)
            NSArray *existingPacakges = [PackageInstaller getPackageList];
            bool found = false;
            for (NSDictionary *exCourse in existingPacakges)
            {   
                if ([[exCourse objectForKey:@"uniqueId"] isEqualToString:[crse objectForKey:@"uniqueId"]]) {
                    found = YES;
                    break;
                }
            }
            
            if(found){
                [PackageInstaller removePackage:[crse objectForKey:@"uniqueId"]];
            }
            
            //unzip
            [ZipHelper unZipFile:downloadTempFileLocation destination:destination onComplete:^(BOOL unzipSuccesful) {
                
                if (unzipSuccesful)
                {                               
                    if (cleanupTempFile)
                    {
                        [[NSFileManager defaultManager] removeItemAtPath:downloadTempFileLocation error:nil];
                    }
                                        
                    BOOL success = [self processCourseFilesAfterUnpacking:crse];
                    
                    if(success){ 
                        
                        
                        [crse setObject:[self getPackagePath:crse] forKey:@"path"];
                        [crse setObject:[crse objectForKey:@"uniqueId"] forKey:@"package_id"];
                        [PackageInstaller savePackage:crse];
                        
                        for (NSDictionary *dc in downloadingCourses) {
                            NSDictionary *c = [dc objectForKey:@"course"];
                            if ([[c objectForKey:@"uniqueId"] isEqualToString:[crse objectForKey:@"uniqueId"]]) {
                                [downloadingCourses removeObject:dc];
                                break;
                            }
                        }
                        
                        [courseInfo setValue:[NSNumber numberWithInt:TRUE] forKey:@"installed"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadStatusChanged" object:courseInfo];
                    }
                    else {
                        [courseInfo setValue:[NSNumber numberWithInt:Failed] forKey:@"status"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadStatusChanged" object:courseInfo];
                    }
                }
            }];
        }
    }];
}

- (NSString *)getThumbPath {
    return [[PackageInstaller getRootPackagePath] stringByAppendingPathComponent:@"/thumbs"];
}

- (NSString *)getPackagePath:(NSDictionary*)course
{
    NSString *packageFolderName = [course objectForKey:@"uniqueId"];
    return [[PackageInstaller getRootPackagePath] stringByAppendingFormat:@"/%@", packageFolderName];
}


/*
 * Default implementation chooses the first file in the package
 */
-(NSDictionary*)getFileDataForCourse:(NSDictionary *)course
{
    NSArray *files = [course objectForKey:@"files"];
    NSDictionary *result = nil;
    
    if (files && files.count > 0)
    {
        NSDictionary *file = [files objectAtIndex:0];
        
        if (file)
            result = file;
    }
    
    return result;
}

/*
 * Default implementation does no post-processing on the files
 */
-(BOOL)processCourseFilesAfterUnpacking:(NSDictionary *)course
{
    return TRUE;
}


- (PackageState) getPackageState:(NSDictionary *)course{
    
    for (NSDictionary *c in downloadingCourses) {
        NSDictionary *downloadingCourse = [c objectForKey:@"course"];
        if ([[downloadingCourse objectForKey:@"uniqueId"] isEqualToString:[course objectForKey:@"uniqueId"]]) {
            
            BOOL installed = [[c objectForKey:@"installed"] boolValue];
            int state = [[c objectForKey:@"status"] intValue];
            
            if (installed == TRUE)
                return PackageInstalled;
            else if (state == Finished)
                return PackageInstalling;
            else if (state == Queued)
                return PackageQueued;
            else if (state == Cancelled 
                     || state == Failed)
                return PackageFailed;
            else
                return PackageDownloading;
            
        } 
    }
        
    NSDictionary *foundCourse = nil;
    
    for (NSDictionary *p in [PackageInstaller getPackageList])
        if ([[p objectForKey:@"uniqueId"] isEqualToString:[course objectForKey:@"uniqueId"]]) {
            foundCourse = p;
        }    
    
    //check the version for the course
    if(foundCourse)
    {        
        //Check the version that would now be chosen against the current version
        NSString *courseMd5 = [[self getFileDataForCourse:course] objectForKey:@"md5sum"];
        NSString *foundCourseMd5 = [[self getFileDataForCourse:foundCourse] objectForKey:@"md5sum"];
        
        if (courseMd5 == nil && foundCourseMd5 == nil)
            return PackageInstalled;
        else if(![courseMd5 isEqual:foundCourseMd5])
            return PackageUpdateAvailable;
        else
            return PackageInstalled;
    }
    else    
        return PackageNotInstalled;
}

- (void) canDownloadCourse:(NSDictionary *) course callback:(CheckDownloadCallback)callback
{
    callback(YES);
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

- (float) getSizeOfCourse:(NSDictionary *)course
{
    NSDictionary *fileData = [self getFileDataForCourse:course];
    
    if ([fileData objectForKey:@"size"])
        return [[fileData objectForKey:@"size"] floatValue];
    else
        return 0;
}

+(NSString*)metaDataValueForKey:(NSString*)key fromCourse:(NSDictionary*)course
{
    if([course objectForKey:@"metadata"]){
        if ([[course objectForKey:@"metadata"] count] > 0 && [[course objectForKey:@"metadata"] objectForKey:key]) {
            return [[course objectForKey:@"metadata"] objectForKey:key];
        }
    }
    return nil;
}

+ (NSDictionary*)getPackage:(NSString *)packageId
{
    NSMutableArray *packages = [self getPackageList];
    NSDictionary *package = nil;
    
    if(packages){
        for (package in packages) {
            if ([[package objectForKey:@"package_id"] isEqualToString:packageId]) {
                break;
            }
        }
    }
    return package;
}

+ (NSString *)getRootPackagePath
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *www = [documentsDirectory stringByAppendingPathComponent:@"/packages/downloads"];
    
    return www;
}

+ (id)getPackageList {
    
    if (packageList == nil)
    {
        
        NSString *packageListPath = [[self getRootPackagePath] stringByAppendingPathComponent:@"/packages.plist"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:packageListPath]) {
            NSPropertyListFormat format;
            NSString *error;
            
            packageList = [[NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfFile:packageListPath]
                                                            mutabilityOption:NSPropertyListMutableContainers
                                                                      format:&format
                                                            errorDescription:&error] mutableCopy];
            
            
        }        
    }
    
    return packageList;
}

+(void) clearPackageList
{
    [packageList release];packageList=nil;
}

+(id)getLatestPackageList{
    NSMutableArray *latestPackages = [[NSMutableArray alloc] init];
    
    NSArray *packageList = [PackageInstaller getPackageList];
    int count =1;
    for(int i = packageList.count -1; i >=0 && count <=2; i--){
        [latestPackages addObject:[packageList objectAtIndex:i]];
        count++;
    }
    NSMutableArray *retPackages = [NSArray arrayWithArray:latestPackages];
    [latestPackages release];
    return retPackages;
}

+ (void)cleanPackage:(NSDictionary *)package
{
    for (NSString* key in [package allKeys]) {
        id value = [package objectForKey:key];
        
        if ([value isKindOfClass:[NSNull class]])
        {
            [package setValue:nil forKey:key];
        }
    }

}

+ (void)savePackage:(NSDictionary *)package {
    NSString *error;
    NSString *packageListPath = [[self getRootPackagePath] stringByAppendingPathComponent:@"/packages.plist"];
    
    [self cleanPackage:package];
    
    NSMutableArray *packages;
    
    id plist = [self getPackageList];
    
    if (plist) {
        [plist addObject:package];
        packages = plist;
    } else packages = [NSMutableArray arrayWithObject:package];
    
    NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:packages
                                                                 format:NSPropertyListBinaryFormat_v1_0
                                                       errorDescription:&error];
    
    if (xmlData) [xmlData writeToFile:packageListPath atomically:YES];
}

+ (void)removePackage:(NSString *)packageID {
    NSMutableArray *packages = [self getPackageList];
    
    if (packages) {
        NSDictionary *package = nil;
        BOOL found = NO;
        for (package in packages) {
            if ([[package objectForKey:@"package_id"] isEqualToString:packageID]) {
                found = YES;
                break;
            }
        }
        if (package && found) {
            NSError *err;
            [[NSFileManager defaultManager] removeItemAtPath:[package objectForKey:@"path"] error:&err];
            
            [packages removeObject:package];
            NSString *packageListPath = [[self getRootPackagePath] stringByAppendingPathComponent:@"/packages.plist"];
            NSString *error;
            
            NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:packages
                                                                         format:NSPropertyListBinaryFormat_v1_0
                                                               errorDescription:&error];
            
            if (xmlData) [xmlData writeToFile:packageListPath atomically:YES];
        }
    }
    
}


@end
