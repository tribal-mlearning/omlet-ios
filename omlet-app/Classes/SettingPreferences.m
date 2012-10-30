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

#import "SettingPreferences.h"
#import "Framework.h"

#define kSyncFreq   @"omlet_SyncFreq"
#define kVersion    @"omlet_Ver"
#define kDataUse    @"omlet_DataUse"

@implementation SettingPreferences

+ (SettingPreferences *)userPreferences {
    return [[SettingPreferences new] autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        id isSet = [[NSUserDefaults standardUserDefaults] objectForKey:kVersion];
        if (isSet == nil) { 
            
            NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
            [[NSUserDefaults standardUserDefaults] setObject:[info objectForKey:@"CFBundleVersion"] forKey:kVersion];
            [[NSUserDefaults standardUserDefaults] setObject:
             [[NSNumber numberWithInt:SettingsSync5Minutes] stringValue] forKey:kSyncFreq];
            [[NSUserDefaults standardUserDefaults] setObject:
             [[NSNumber numberWithInt:SettingsDataWifiAndCellular] stringValue] forKey:kDataUse];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
    return self;
}

- (void)setVersion:(NSString*)version
{
    [[NSUserDefaults standardUserDefaults] setObject:version forKey:kVersion];
}

- (BOOL)packageOpened {
    NSString *pid = [[Framework client] getCurrentPackageId];
    if (pid == nil || [pid isEqualToString:@""]) return NO;
    return [[NSUserDefaults standardUserDefaults] boolForKey:pid];
}

- (void)setPackageOpened:(BOOL)_packagedOpened {
    NSString *pid = [[Framework client] getCurrentPackageId];
    if (pid == nil || [pid isEqualToString:@""]) return;
    [[NSUserDefaults standardUserDefaults] setBool:_packagedOpened forKey:pid]; 
}

- (SettingsData)dataUse {
    NSInteger data = [[NSUserDefaults standardUserDefaults] integerForKey:kDataUse];
    switch (data) {
        case 1:
            return SettingsDataWifiOnly;
        case 2:
            return SettingsDataWifiAndCellular;
        case 3:
            return SettingsDataCellularOnly;
        default:
            return SettingsDataWifiAndCellular;
    }
}

- (SettingsSyncFreq)syncFrequency {
    NSInteger syncFreq = [[NSUserDefaults standardUserDefaults] integerForKey:kSyncFreq];
    switch (syncFreq) {
        case 1:
            return SettingsSync5Minutes;
        case 2:
            return SettingsSync10Minutes;
        case 3:
            return SettingsSync15Minutes;
        case 4:
            return SettingsSyncManual;
        default:
            return SettingsSync5Minutes;
    }
}


@end
