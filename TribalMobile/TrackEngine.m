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

#import "TrackEngine.h"
#import "TrackingTable.h"
#import "Framework.h"
//#import "SettingPreferences.h"

#import <PhoneGap/JSONKit.h>


@interface TrackEngine (PrivateMethods)

- (void)trackObjectAccess;

@end

@implementation TrackEngine

- (id)init {
    self = [super init];
    if (self) {
        accessedAt = nil;
        element = nil;
    }
    return self;
}

- (void)dealloc {
    [accessedAt release];
    [element release];
    [super dealloc];
}

- (void)updateElement:(PEBase *)_element
{
    if (element) {
        [element release];
        [accessedAt release];
        element = nil;
        accessedAt = nil;
    }
    
    if (_element) {
        element = [_element retain];
        accessedAt = [[NSDate date] retain];
        [self trackObjectAccess];
    }
}

- (void)track:(NSString *)sender addInfo:(NSString *)addInfo
{
    BOOL isTracking = YES;//[SettingPreferences userPreferences].tracking;
    if (isTracking) {
        NSString *userId = [[Framework client] getUserUsername];
        NSLog(@"tracking user[%@] sender[%@] addInfo[%@]", userId, sender, addInfo);
        
        [TrackingTable track:userId objectId:[element getFullId] sender:sender addInfo:addInfo];
    }
}

- (void)trackSync
{
    UIDevice *device = [UIDevice currentDevice];
    NSString *deviceInfo = [NSString stringWithFormat:@"%@ %@", device.systemName, device.systemVersion];
    
    NSMutableDictionary *obj = [[NSMutableDictionary new] autorelease];
    [obj setValue:deviceInfo forKey:@"sync"];
    [obj setValue:device.systemName forKey:@"deviceType"];
    NSArray *addInfo = [NSArray arrayWithObject:obj];
    [self track:@"mf" addInfo:[addInfo JSONString]];
    
}

- (void)removeTrack:(NSString *)trackId
{
    [TrackingTable remove:trackId];
}

- (NSMutableDictionary *)fetchTrack
{
    NSString *userId = [[Framework client] getUserUsername];
    return [TrackingTable fetchTrack:userId];
}

/* PrivateMethods */

- (void)trackObjectAccess
{
//    double elapsed_s = [accessedAt timeIntervalSinceNow] * -1.0;
    if ([element isKindOfClass:[PEResource class]] == NO) return;
    
    NSMutableDictionary *obj = [NSMutableDictionary new];
    [obj setValue:[@"/" stringByAppendingString:[((PEResource *) element) path]] forKey:@"experienced"];
    NSArray *array = [NSArray arrayWithObject:obj];
    [obj release];
    
    NSString *json = [array JSONString];
    [self track:@"mf" addInfo:json];
}

@end