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

/** @file Download.h */

#import <Foundation/Foundation.h>
#import "AuthHttpConnection.h"

typedef enum {
    NotStarted,
    Queued,    
    Connecting,    
    Downloading,
    Finished,
    Failed,
    Cancelled    
} DownloadStatus;

@class Download;

/** DownloadOnProgressChanged. 
 *  param[in] download
 *  param[in] status
 *  param[in] percentage
 */
typedef void (^DownloadOnProgressChanged)(Download *download, DownloadStatus status, NSNumber * percentage);

/** DownloadCompleted. 
 *  param[in] download
 *  param[in] data
 */
typedef void (^DownloadCompleted)(Download *download, NSData *data);

/** Download.
 * The Download class is used to download files from a url
 */
@interface Download : NSObject
{
    NSString *url; ///< url to download
    NSString *destination; ///< path to the downloaded file
    NSFileHandle *fileHandle; ///< handle for the downloaded file
    NSMutableData *cache;  ///< downloaded data
    
    NSURLConnection *connection; ///< connection
    
    DownloadStatus status; ///< status of the download
    
    NSNumber *percentage;  ///< percentage of the download  
    NSNumber *currentSize; ///< amount of the file downloaded
    NSNumber *size; ///< total size of the file
        
    DownloadOnProgressChanged progressChanged;
    DownloadCompleted downloadCompleted;
}

@property (nonatomic) BOOL useAuthentication;
@property (nonatomic) float expectedSize;
@property (nonatomic, copy) NSString * identifier;
@property (nonatomic, copy) NSString* errorDescription;

/** initWithUrl.
 *  @param[in] URL
 *  @param[in] downloadCompleted
 *  @return Download
 */
- (id)initWithUrl:(NSString *)url downloadCompleted:(DownloadCompleted) downloadCompleted;

/** initWithUrl.
 *  @param[in] URL
 *  @param[in] destination path
 *  @return Download
 */
- (id)initWithUrl:(NSString *)url destination:(NSString *)destination progressChanged:(DownloadOnProgressChanged) progressChanged;

/** start.
 *  Starts the download
 */
- (void)start;

/** cancel.
 *  Cancels the download if started
 */
- (void)cancel;

@end


