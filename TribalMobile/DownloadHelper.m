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

#import "DownloadHelper.h"
#import "Framework.h"
#import "AuthHttpConnection.h"
#import <CommonCrypto/CommonDigest.h>
#import <PhoneGap/JSONKit.h>
#import <PhoneGap/NSData+Base64.h>

@implementation DownloadHelper

+ (NSString *)createNonce 
{
    NSMutableString *nonce = [NSMutableString stringWithString:@""];
    
    for (int index = 0; index < 128; index++) {
        [nonce appendFormat:@"%i", arc4random() % 10];
    }
    return nonce;
}

+ (NSInteger)createCreated
{
    return round([[NSDate date] timeIntervalSince1970] - (/*serverDelta*/ 0 / 1000));
}

+ (NSString *)base64String:(NSString *)data
{
    return [[data dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] base64EncodedString];
}

+ (NSString *)createAccessToken:(NSString *)nonce time:(NSInteger)created password:(NSString *)password
{
    return [self base64String:[AuthHttpConnection sha512:[NSString stringWithFormat:@"%@%i%@", nonce, created, password]]];
}

static NSString *const SALT = @"{a0fk04383ruaf98b7a7afg76523}";

+(NSURLRequest *)createRequest:(NSString *)url connectionType:(HttpConnectionDataType)connectionDataType {
    NSString *_username = [[[Framework client] getUserUsername] stringByAppendingString:SALT];
    NSString * username = [AuthHttpConnection sha512:_username];
    
    NSString *_password = [[[Framework client] getUserPassword] stringByAppendingString:SALT];
    NSString * password = [AuthHttpConnection sha512:_password];
    
    
    NSMutableDictionary *credentials = [NSMutableDictionary dictionary];
    NSString *nonce = [self createNonce];
    NSInteger created = [self createCreated];
    NSString *accessToken = [self createAccessToken:nonce time:created password:password];
    
    [credentials setValue:[NSString stringWithFormat:@"AuthToken HashId=\"%@\"", username] forKey:@"HashId"];
    [credentials setValue:[NSString stringWithFormat:@"AccessToken=\"%@\"", accessToken] forKey:@"accessToken"];
    [credentials setValue:[NSString stringWithFormat:@"Nonce=\"%@\"", [self base64String:nonce]] forKey:@"nonce"];
    [credentials setValue:[NSString stringWithFormat:@"Created=\"%i\"", created] forKey:@"created"];    
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setValue:credentials forKey:@"header"];
    [data setValue:nil forKey:@"content"];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [req setHTTPMethod:@"GET"];
    [req setHTTPShouldHandleCookies:NO];
    
      
    data = [data objectForKey:@"header"];
    [req setValue:[data objectForKey:@"HashId"] forHTTPHeaderField:@"X-AUTH"];
    [req addValue:[@" " stringByAppendingString:[data objectForKey:@"accessToken"]] forHTTPHeaderField:@"X-AUTH"];
    [req addValue:[@" " stringByAppendingString:[data objectForKey:@"nonce"]] forHTTPHeaderField:@"X-AUTH"];
    [req addValue:[@" " stringByAppendingString:[data objectForKey:@"created"]] forHTTPHeaderField:@"X-AUTH"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];    
    [req setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    
    return [[req copy] autorelease];   
}

@end
