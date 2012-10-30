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

#import <CommonCrypto/CommonDigest.h>
#import <PhoneGap/JSONKit.h>
#import <PhoneGap/NSData+Base64.h>

#import "AuthHttpConnection.h"
#import "Framework.h"

static NSString *const SALT = @"{a0fk04383ruaf98b7a7afg76523}";

@implementation AuthHttpConnection

- (void)dealloc 
{
    [username release];
    [password release];
    [super dealloc];
}

- (NSString *)createNonce 
{
    NSMutableString *nonce = [NSMutableString stringWithString:@""];
    
    for (int index = 0; index < 128; index++) {
        [nonce appendFormat:@"%i", arc4random() % 10];
    }
    return nonce;
}

- (NSInteger)createCreated
{
    return round([[NSDate date] timeIntervalSince1970] - (serverDelta / 1000));
}

- (NSString *)base64String:(NSString *)data
{
    return [[data dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] base64EncodedString];
}

- (NSString *)createAccessToken:(NSString *)nonce time:(NSInteger)created
{
    return [self base64String:[AuthHttpConnection sha512:[NSString stringWithFormat:@"%@%i%@", nonce, created, password]]];
}

- (NSDictionary *)credentials
{
    NSMutableDictionary *finalResult = [NSMutableDictionary dictionary];
    NSString *nonce = [self createNonce];
    NSInteger created = [self createCreated];
    NSString *accessToken = [self createAccessToken:nonce time:created];
    
    if (self.connectionDataType == HttpConnectionDataTypeHeaders) {
        [finalResult setValue:[NSString stringWithFormat:
                               @"AuthToken HashId=\"%@\"", username] forKey:@"HashId"];
        [finalResult setValue:[NSString stringWithFormat:
                               @"AccessToken=\"%@\"", accessToken] forKey:@"accessToken"];
        [finalResult setValue:[NSString stringWithFormat:
                               @"Nonce=\"%@\"", [self base64String:nonce]] forKey:@"nonce"];
        [finalResult setValue:[NSString stringWithFormat:
                               @"Created=\"%i\"", created] forKey:@"created"];
    } else {
        
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        [result setValue:username forKey:@"hashId"];
        [result setValue:accessToken forKey:@"accessToken"];
        
        [result setValue:[self base64String:nonce] forKey:@"nonce"];
        [result setValue:[NSNumber numberWithInteger:created] forKey:@"created"];
        
       
        [finalResult setValue:result forKey:@"j-wsse"];
        
    }
    
    return finalResult;
}

- (void)start
{
    [[Framework server] getServerDelta:^(NSInteger _serverDelta) {
        serverDelta = _serverDelta;
        
        NSString *_username = [[[Framework client] getUserUsername] stringByAppendingString:SALT];
        username = [[AuthHttpConnection sha512:_username] retain];
        
        NSString *_password = [[[Framework client] getUserPassword] stringByAppendingString:SALT];
        password = [[AuthHttpConnection sha512:_password] retain];
        
        [super start];
    }];
}

- (id)data
{
    NSMutableDictionary *finalData = [NSMutableDictionary dictionary];
    [finalData setValue:[self credentials] forKey:@"header"];
    if ([super data]) {
        NSString *content = [[NSDictionary dictionaryWithObject:[super data] forKey:@"content"] JSONString];
        if (content) [finalData setValue:content forKey:@"content"];
    }
    if (self.connectionDataType == HttpConnectionDataTypeJSON) 
        return [finalData JSONString];
    else return finalData;
}

/* static methods */

+ (id)getUrl:(NSString *)url data:(NSString *)data
       onStart:(HttpConnectionOnStart)onStart 
     onSuccess:(HttpConnectionOnSuccess)onSuccess
       onError:(HttpConnectionOnError)onError
{
    return [[[AuthHttpConnection alloc] initWithMethod:@"GET" url:url data:data onStart:onStart onSuccess:onSuccess onError:onError] autorelease];
}

+ (id)postUrl:(NSString *)url data:(NSString *)data
        onStart:(HttpConnectionOnStart)onStart 
      onSuccess:(HttpConnectionOnSuccess)onSuccess
        onError:(HttpConnectionOnError)onError
{
    return [[[AuthHttpConnection alloc] initWithMethod:@"POST" url:url data:data onStart:onStart onSuccess:onSuccess onError:onError] autorelease];
}

+ (NSString *)sha512:(NSString *)input {
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
    uint8_t digest[CC_SHA512_DIGEST_LENGTH];
    
    CC_SHA512(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA512_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA512_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

@end
