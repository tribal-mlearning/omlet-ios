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

#import "DownloadManager.h"
#import "Download.h"

@implementation DownloadManager

@synthesize activeDownloadCapacity;

- (id)initWithCapacity:(NSInteger)capacity {
    self = [super init];
    if (self) {
        self.activeDownloadCapacity = capacity;
        queue = [[NSMutableArray alloc] initWithCapacity:10];
        activeDownloads = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSInteger)activeDownloadCount {
    return [activeDownloads count];
}

- (void) cancelAllDownloads{
    for (Download *download in activeDownloads) {
        [download cancel];
    }
    [activeDownloads removeAllObjects];
    [queue removeAllObjects];
}

- (void) tryStartDownload {
    
    while ([self activeDownloadCount] < self.activeDownloadCapacity && queue.count > 0)
    {
        Download *download = [queue objectAtIndex:0];
        [activeDownloads addObject:download];
        [queue removeObjectAtIndex:0];        
        [download start];
    }
}

- (void) cancelDownload:(NSString *)downloadId
{
    Download *download = NULL;
    bool activeDownload = false;
    for (Download *d in activeDownloads) {
        if([d.identifier isEqualToString:downloadId]){
            download = d;
            activeDownload=true;
            break;
        }
    }   
    
    if (download == NULL) {
        for(Download *d in queue){
            if([d.identifier isEqualToString:downloadId]){
                download = d;
                break;
            }
        }
    }
    
    [download cancel];
    if(activeDownload){
        [activeDownloads removeObject:download];
    }
    else{
        [queue removeObject:download];
    }
    [self tryStartDownload];
}

- (void)dealloc
{
    [queue release];
    [activeDownloads release];
    [super dealloc];
}

- (NSString*)enqueueDownload:(NSString *)url withAuth:(BOOL)useAuth expectedSize:(float)expectedSize downloadComplete:(DownloadCompleted) downloadCompleted {
    
    DownloadCompleted callback = ^(Download *_download, NSData *data) {
        
        if(downloadCompleted)
            downloadCompleted(_download, data);     
        [activeDownloads removeObject:_download]; 
        [self tryStartDownload];
    };
    
    CFUUIDRef uuid =CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    
    Download *download = [[[Download alloc] initWithUrl:url downloadCompleted:callback] autorelease]; 
    download.useAuthentication = useAuth;
    download.expectedSize = expectedSize;
    download.identifier = uuidString;
    [uuidString release];
    [queue addObject:download];    
    [self tryStartDownload];
    return download.identifier;
}

- (NSString*)enqueueDownload:(NSString *)url withAuth:(BOOL)useAuth expectedSize:(float)expectedSize destination:(NSString *)destination progressChanged:(DownloadOnProgressChanged) progressChanged {
    
    DownloadOnProgressChanged callback = ^(Download *_download, DownloadStatus status, NSNumber *percentage) {
        
        if(progressChanged)
            progressChanged(_download, status, percentage);
        
        if (status == Failed || status == Finished) {     
            [activeDownloads removeObject:_download]; 
            [self tryStartDownload];
        }
    };
        
    CFUUIDRef uuid =CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    [uuidString autorelease];
    CFRelease(uuid);
    
    Download *download = [[[Download alloc] initWithUrl:url destination:destination progressChanged:callback] autorelease];
    download.useAuthentication = useAuth;
    download.expectedSize = expectedSize;
    download.identifier = uuidString;
    [queue addObject:download];    
    
    if(progressChanged)
        progressChanged(download, Queued, nil);
    
       
    [self tryStartDownload];
    return download.identifier;
}

@end
