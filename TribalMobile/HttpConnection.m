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

#import "HttpConnection.h"
#import "NativeSettings.h"

@interface HttpConnection()
    -(BOOL)allowUntrustedSSL;
@end

@implementation HttpConnection
@synthesize connectionDataType, delegate;

- (id)initWithMethod:(NSString *)_method url:(NSString *)_url data:(id)_data 
             onStart:(HttpConnectionOnStart)_onStart 
           onSuccess:(HttpConnectionOnSuccess)_onSuccess
             onError:(HttpConnectionOnError)_onError;
{
    self = [super init];
    if (self) {
        url = [_url retain];
        method = [_method retain];
        userData = [_data retain];
        receivedData = [NSMutableString new];
        onStart = Block_copy(_onStart);
        onSuccess = Block_copy(_onSuccess);
        onError = Block_copy(_onError);
    }
    return self;
}

- (void)start
{
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [req setHTTPShouldHandleCookies:NO];
    [req setHTTPMethod:method];
    
    NSString *dataStr = nil;
    id currentData = [self data];
    if (connectionDataType == HttpConnectionDataTypeHeaders && currentData) {
        NSDictionary *headerData = [currentData objectForKey:@"header"];
        
        [req setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        
        [req setValue:[headerData objectForKey:@"HashId"] forHTTPHeaderField:@"X-AUTH"];
        [req addValue:[@" " stringByAppendingString:[headerData objectForKey:@"accessToken"]] forHTTPHeaderField:@"X-AUTH"];
        [req addValue:[@" " stringByAppendingString:[headerData objectForKey:@"nonce"]] forHTTPHeaderField:@"X-AUTH"];
        [req addValue:[@" " stringByAppendingString:[headerData objectForKey:@"created"]] forHTTPHeaderField:@"X-AUTH"];
        [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        if ([currentData objectForKey:@"content"] != nil) {
            dataStr = [NSString stringWithFormat:@"%@", [currentData objectForKey:@"content"]];
            NSData *content = [dataStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
            [req setHTTPBody:content];
        }
    } else {
        
        if (currentData != nil) {
            dataStr = [NSString stringWithFormat:@"%@", currentData];
        }
        NSData *content = [dataStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        [req setHTTPBody:content];
    }
    [req setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    NSURLConnection *conn = [[NSURLConnection connectionWithRequest:req delegate:self] retain];
    [conn start];
}

- (id)data
{
    return userData;
}

- (void)dealloc 
{
    Block_release(onStart);
    Block_release(onSuccess);
    Block_release(onError);
    [HTTPResponse release];
    [url release];
    [method release];
    [userData release];
    [receivedData release];
    [super dealloc];
}

/* NSURLConnection delegate methods */

-(BOOL)allowUntrustedSSL
{
    return [[NativeSettings userPreferences] allowSelfSignedSSL];  
}

// iOS 5
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    SecTrustResultType result;
    SecTrustEvaluate(challenge.protectionSpace.serverTrust, &result);
    
    if ([self allowUntrustedSSL])
    {
        [challenge.sender useCredential:
         [NSURLCredential credentialForTrust: challenge.protectionSpace.serverTrust] 
             forAuthenticationChallenge: challenge];
    }
    //Check certificate credentials
    else if(result == kSecTrustResultProceed || result == kSecTrustResultConfirm ||  result == kSecTrustResultUnspecified){
        [challenge.sender useCredential:
         [NSURLCredential credentialForTrust: challenge.protectionSpace.serverTrust] 
             forAuthenticationChallenge: challenge];
    }
    //If not accepting trusted SSL certs and cert trust not recognised, cancel
    else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

// iOS 4
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {   
    /*
     Apple's default logic is to return NO if using client cert or server trust, else YES.
     
     https://developer.apple.com/library/ios/#documentation/Foundation/Reference/NSURLConnectionDelegate_Protocol/Reference/Reference.html#//apple_ref/occ/intf/NSURLConnectionDelegate
     */
    return YES;
}

// iOS 4
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    SecTrustResultType result;
    SecTrustEvaluate(challenge.protectionSpace.serverTrust, &result);
    
    if ([self allowUntrustedSSL])
    {
        [challenge.sender useCredential:
         [NSURLCredential credentialForTrust: challenge.protectionSpace.serverTrust] 
             forAuthenticationChallenge: challenge];
    }
    else if(result == kSecTrustResultProceed || result == kSecTrustResultConfirm ||  result == kSecTrustResultUnspecified){
        [challenge.sender useCredential:
         [NSURLCredential credentialForTrust: challenge.protectionSpace.serverTrust] 
             forAuthenticationChallenge: challenge];
    }
    else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        if (HTTPResponse) [HTTPResponse release];
        HTTPResponse = (NSHTTPURLResponse *) response;
        [HTTPResponse retain];
    }
    onStart();
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSString *str = [[NSString alloc ] initWithData:data encoding:NSUTF8StringEncoding];
    [receivedData appendString:str];
    [str release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    onError(error);
    [connection release];
    if ([self.delegate respondsToSelector:@selector(connection:completed:)])
        [self.delegate connection:self completed:NO];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [connection release];
    if (HTTPResponse && [HTTPResponse statusCode] > 199 && [HTTPResponse statusCode] < 202) onSuccess(receivedData);
    else onError([NSError errorWithDomain:@"" code:0 userInfo:nil]);
    if ([self.delegate respondsToSelector:@selector(connection:completed:)])
        [self.delegate connection:self completed:YES];

}

/* static methods */

+ (id)getUrl:(NSString *)url data:(id)data
       onStart:(HttpConnectionOnStart)onStart 
     onSuccess:(HttpConnectionOnSuccess)onSuccess
       onError:(HttpConnectionOnError)onError
{
    return [[[HttpConnection alloc] initWithMethod:@"GET" url:url data:data onStart:onStart onSuccess:onSuccess onError:onError] autorelease];
}

+ (id)postUrl:(NSString *)url data:(id)data
        onStart:(HttpConnectionOnStart)onStart 
      onSuccess:(HttpConnectionOnSuccess)onSuccess
        onError:(HttpConnectionOnError)onError
{
    return [[[HttpConnection alloc] initWithMethod:@"POST" url:url data:data onStart:onStart onSuccess:onSuccess onError:onError] autorelease];
}

@end
