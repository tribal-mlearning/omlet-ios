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

/** @file PackageInstaller.h */

#import <Foundation/Foundation.h>
#import "DownloadManager.h"

#ifdef PHONEGAP_FRAMEWORK
#import <PhoneGap/Reachability.h>
#else
#import "PhoneGap/Reachability.h"
#endif

typedef enum {
    PackageNotInstalled,
    PackageQueued,
    PackageDownloading,    
    PackageInstalling,    
    PackageInstalled,
    PackageFailed,
    PackageUpdateAvailable,
} PackageState;

typedef void (^CheckDownloadCallback)(bool success);
typedef void (^PackageStateChanged)(NSString *url, PackageState state);


/** PackageInstallProgressed. 
 *  param[in] packageRef
 *  param[in] downloadStatus
 *  param[in] downloadPercentage
 *  param[in] installed
 */
typedef void (^PackageInstallProgressed)(NSString* downloadId, DownloadStatus downloadStatus, NSNumber *downloadPercentage, BOOL installed);

/** PackageInstaller.
 * The PackageInstaller class is used to download and unzip packages / courses
 */
@interface PackageInstaller : NSObject{
    DownloadManager *downloadManager; ///< manager for downloading files
}

@property (nonatomic, retain) NSMutableArray* downloadingCourses;
@property (nonatomic) NetworkStatus netStatus;


/** downloadCourse
 * @param[in]course
 * @param[in]imageData
 */
- (void) downloadCourse:(NSDictionary *)course imageData:(NSData *)imageData;

/** downloadCourse.
 *  @param[in] course
 *  @param[in] destination
 *  @param[in] downloadTempFileLocation
 *  @param[in] cleanupTempFile
 *  @param[in] packageInstallProgressed
 */
- (void) downloadCourse:(NSMutableDictionary*)course
            destination:(NSString *)destination
downloadTempFileLocation:(NSString *)downloadTempFileLocation
        cleanupTempFile:(BOOL)cleanupTempFile;

/** savePackage.
 *  @param[in] package
 */
+ (void)savePackage:(NSDictionary *)package;

+ (void)removePackage:(NSString *)packageID;

/** getPackage
 * @param[in] packageId
 */
+ (NSDictionary*)getPackage:(NSString *)packageId;

/** getPackageList.
 *  @return package list
 */
+ (id)getPackageList;

/** clearPackageList
 */
+(void) clearPackageList;

/** getLatestPackageList
  * @return recently downloaded packages list
 */
+(id)getLatestPackageList;

/** getRootPackagePath
 */
+ (NSString *)getRootPackagePath;

/** cancelDownloads.
 */
-(void)cancelDownloads;

/** cancelDownload
 *  @param[in] downloadId
 */
-(void)cancelDownload:(NSString *)downloadId;

/** getFileDataForCourse
 *  @param[in] course
 */
-(NSDictionary*)getFileDataForCourse:(NSDictionary *)course;

/** processCourseFilesAfterUnpacking
 * @param[in]course
 */
-(BOOL)processCourseFilesAfterUnpacking:(NSDictionary *)course;

/** getThumbPath
 */
- (NSString *)getThumbPath;

/** getPackagePath
 * @param[in]course
 */
- (NSString *)getPackagePath:(NSDictionary*)course;

/** getPackageState
 * @param[in]course
 */
- (PackageState) getPackageState:(NSDictionary *)course;

/** canDownloadCourse
 * @param[in]course
 * @param[in]callback
 */
- (void) canDownloadCourse:(NSDictionary *) course callback:(CheckDownloadCallback)callback;

/** getSizeOfCourse
 * @param[in]course
 */
- (float) getSizeOfCourse:(NSDictionary *)course;


/** metaDataValueForKey
 *  key value to retrieve
 *  course to retrieve value from
 */
+(NSString*)metaDataValueForKey:(NSString*)key fromCourse:(NSDictionary*)course;

@end
