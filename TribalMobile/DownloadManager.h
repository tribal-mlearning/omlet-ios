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

/** @file DownloadManager.h */

#import <Foundation/Foundation.h>
#import "Download.h"

/** DownloadManager.
 * The DownloadManager class is used to manage downloads
 */
@interface DownloadManager : NSObject
{
    NSMutableArray *queue;  ///< queue of current downloads
    NSMutableArray *activeDownloads;  ///< active downloads
    NSInteger activeDownloadCapacity;  ///< the maxmium number of active downloads
}

@property (nonatomic) NSInteger activeDownloadCapacity; ///< the maxmium number of active downloads

/** initWithCapacity.
 *  @param[in] capacity
 *  @return DownloadManager
 */
- (id)initWithCapacity:(NSInteger)capacity;

/** enqueueDownload.
 *  @param[in] url
 *  @param[in] destination
 *  @param[in] progressChanged
 */
- (NSString*)enqueueDownload:(NSString *)url withAuth:(BOOL)useAuth expectedSize:(float)expectedSize destination:(NSString *)destination progressChanged:(DownloadOnProgressChanged) progressChanged;

/** enqueueDownload.
 *  @param[in] url
 *  @param[in] downloadCompleted
 */
- (NSString*)enqueueDownload:(NSString *)url withAuth:(BOOL)useAuth expectedSize:(float)expectedSize downloadComplete:(DownloadCompleted) downloadCompleted;

/** cancelAllDownloads.
 */
- (void) cancelAllDownloads;

/** cancelDownload
 *  @param[in] downloadId
 */
- (void) cancelDownload:(NSString *)downloadId;

- (NSInteger)activeDownloadCount;

@end
