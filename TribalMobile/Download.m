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

#import "Download.h"
#import "DownloadHelper.h"
#import "NativeSettings.h"

@interface Download (PrivateMethods)
- (void)updateStatus;
- (void)stopDownload:(NSURLConnection *)connection;
- (BOOL)allowUntrustedSSL;
@end


@implementation Download

@synthesize useAuthentication;
@synthesize expectedSize;
@synthesize identifier;
@synthesize errorDescription;


- (id)initWithUrl:(NSString *)_url downloadCompleted:(DownloadCompleted) _downloadCompleted
{
    self = [super init];
    if (self) {
        url = [_url copy];
        downloadCompleted = [_downloadCompleted copy];        
        fileHandle = nil;
        
        status = Queued;        
        
        currentSize = [[NSNumber numberWithInt:0] retain];
        percentage = [[NSNumber numberWithFloat:0] retain]; 
    }
    
    return self;
}

- (id)initWithUrl:(NSString *)_url destination:(NSString *)_destination progressChanged:(DownloadOnProgressChanged) _progressChanged
{
    self = [super init];
    if (self) {
        url = [_url copy];
        progressChanged = [_progressChanged copy];
        destination = [_destination copy];
        
        fileHandle = nil;
        
        status = Queued;        
        
        currentSize = [[NSNumber numberWithInt:0] retain];
        percentage = [[NSNumber numberWithFloat:0] retain];  
    }
    
    return self;
}

- (void)start
{    
    NSURLRequest *req = nil;
    
    if (useAuthentication)
    {          
        req = [DownloadHelper createRequest:url connectionType:HttpConnectionDataTypeHeaders];
    }
    else
    {
        req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    }
    
    connection = [[NSURLConnection connectionWithRequest:req delegate:self] retain];
    
    if (destination)
    {
        [[NSFileManager defaultManager] createFileAtPath:destination contents:nil attributes:nil];
        fileHandle = [[NSFileHandle fileHandleForWritingAtPath:destination] retain];
    }
    else
    {
        cache = [[NSMutableData alloc] init];
    }
    
    [connection start];
    NSLog(@"download started: %@", url);
    
    status = Connecting;
    [self updateStatus];
    
    
}

- (void)cancel {
    
    if (status == Connecting || status == Downloading)
    {
        [connection cancel];
        status = Cancelled;  
        [self stopDownload:connection];
    }
}

- (void)dealloc {
    if (connection)
    {
        [connection release];
        connection = nil;
    }
    
    Block_release(progressChanged);
    Block_release(downloadCompleted);
    
    [currentSize release];
    [size release];
    [percentage release];
    [destination release];
    
    [cache release];
    cache = nil;
    [url release];
    [fileHandle release];
    [identifier release];
    
    [super dealloc];
}

/* NSURLConnection delegate methods */

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"download recieved response: %@", url);
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        NSInteger statusCode = [httpResponse statusCode];
        
        if (statusCode >= 400)
        {
            NSLog(@"Failed with status code: %i", statusCode);
            self.errorDescription = [NSString stringWithFormat:@"Download failed with status code %i", statusCode];
            
            [conn cancel];
            status = Failed; 
            [self stopDownload:conn]; 
        }
    }
    
    if (status != Failed)
    {
        /* the connection was started, this is the first response */
        size = [[NSNumber numberWithLongLong:[response expectedContentLength]] retain];   
        status = Downloading; 
    }
    
    
    [self updateStatus];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{    
    /* some data was received */
    if (fileHandle)
        [fileHandle writeData:data];
    else
        [cache appendData:data];
    
    float oldPercentage = [percentage floatValue];
    
    long oldSize = [currentSize longLongValue];
    
    [currentSize release];
    currentSize = [[NSNumber numberWithLongLong:(oldSize + [data length])] retain];    
    
    float newPercentage = 0;
    
    if ([size floatValue] > 0)
        newPercentage = [currentSize doubleValue] / [size longLongValue]; 
    else if (expectedSize > 0)
        newPercentage = [currentSize doubleValue] / expectedSize;
    
    if (oldPercentage != newPercentage) {
        [percentage release];
        percentage = [[NSNumber numberWithFloat:newPercentage] retain];
        [self updateStatus]; 
    }
}

-(BOOL)allowUntrustedSSL
{
    return [[NativeSettings userPreferences] allowSelfSignedSSL];  
}

// iOS 5
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([self allowUntrustedSSL])
    {
        NSURLProtectionSpace * protectionSpace = [challenge protectionSpace];
        NSURLCredential* credentail = [NSURLCredential credentialForTrust:[protectionSpace serverTrust]];
        [[challenge sender] useCredential:credentail forAuthenticationChallenge:challenge];
    }
    else
    {
        [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];        
    }
}

// iOS 4
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
        
    if ([self allowUntrustedSSL])
    {
        if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
            return YES;        
    }
    
    /*
     Apple's default logic is to return NO if using client cert or server trust, else YES.
     
     https://developer.apple.com/library/ios/#documentation/Foundation/Reference/NSURLConnectionDelegate_Protocol/Reference/Reference.html#//apple_ref/occ/intf/NSURLConnectionDelegate
     */
        
    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]
        || [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate])
        return NO;
    else
        return YES;
}

// iOS 4
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    if ([self allowUntrustedSSL])
    {
        NSURLProtectionSpace * protectionSpace = [challenge protectionSpace];
        NSURLCredential* credentail = [NSURLCredential credentialForTrust:[protectionSpace serverTrust]];
        [[challenge sender] useCredential:credentail forAuthenticationChallenge:challenge];
    }
    else
    {
        [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}
 

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    NSLog(@"download error: %@", error);
    
    /* there is a problem on the connection */
    status = Failed;  
    [self stopDownload:conn]; 
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
    NSLog(@"download finished: %@", url);
    
    /* download finished */
    [fileHandle closeFile];
    [fileHandle release];
    fileHandle = nil;
    
    [connection release];
    connection = nil;
    
    status = Finished;
    
    [self updateStatus];
    
    if (downloadCompleted)
        downloadCompleted(self, [[cache copy] autorelease]);
    
    [cache release];
    cache = nil;
} 

- (void)stopDownload:(NSURLConnection *)conn{
    
    [fileHandle closeFile];
    [fileHandle release];
    fileHandle = nil;
    
    [connection release];
    connection = nil;
    
    [cache release];
    cache = nil;
    
    [[NSFileManager defaultManager] removeItemAtPath:destination error:nil];
    
    [percentage release];
    percentage = [[NSNumber numberWithFloat:0] retain];
    
    [self updateStatus];
    
    if (downloadCompleted)
        downloadCompleted(self, nil);
}

- (void) updateStatus
{    
    if (progressChanged)
        progressChanged(self, status, percentage);
}

@end
