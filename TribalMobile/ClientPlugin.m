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

#import "ClientPlugin.h"

#import "Framework.h"
#import "Client.h"
#import <JSONKit.h>
#import "PackageInstaller.h"

@interface ClientPlugin()
- (void)packageDownloadCompletedCallback:(PackageOpenRequestState)state:(NSString*)callbackId;
@end

@implementation ClientPlugin

- (void)getCourseLocalPathRoot:(NSMutableArray *)args withDict:(NSMutableDictionary *)options{
        
    id<Client> framework = [Framework client];    
    NSString *packageId = [args objectAtIndex:1];    
    NSString *path =[framework getCourseLocalPathRoot:packageId];
    
     NSString *callbackId = [args objectAtIndex:0];
    
    if (path)
    {    
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:packageId, @"courseId",
                                                                      path, @"localPathRoot",
                                                                      nil];
    
        [self success:[PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:[result JSONString]] callbackId:callbackId];
    }
    else
    {   
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:packageId, @"courseId",
                                @"package not found", @"error",
                                nil];
        
        [self error:[PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:[result JSONString]] callbackId:callbackId];
    }
    
}

- (void)getCurrentCourseLocalPathRoot:(NSMutableArray *)args withDict:(NSMutableDictionary *)options{
   
    id<Client> framework = [Framework client];
    
    NSString *path =[framework getCourseLocalPathRoot:nil];    
    NSString *callbackId = [args objectAtIndex:0];  
    
    if (path)
    {
    
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:[framework getCurrentPackageId], @"courseId",
                                                                     path, @"localPathRoot",
                                                                    nil];
    
        [self success:[PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:[result JSONString]] callbackId:callbackId];
    }
    else
    {
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:@"package not found", @"error",nil];        
        [self error:[PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:[result JSONString]] callbackId:callbackId];
    }
}

- (void)initialiseCurrentCourseLocalTempFolder:(NSMutableArray *)args withDict:(NSMutableDictionary *)options{
    
    id<Client> framework = [Framework client];
    NSString *packagePath =[framework getCourseLocalPathRoot:nil];   
    NSString *callbackId = [args objectAtIndex:0];
    
    NSString *tempPath = [packagePath stringByAppendingString:@"/temp/"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error;
    
    if ([fileManager fileExistsAtPath:tempPath])
    {
        // get all files in this directory        
        NSArray *fileList = [fileManager contentsOfDirectoryAtPath:tempPath error:&error];
        
        if (!fileList)
        {
            NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:[error description], @"error",nil];        
            [self error:[PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:[result JSONString]] callbackId:callbackId];
            return;
        }
              
        for (NSString *file in fileList) {
            BOOL success = [fileManager removeItemAtPath:[tempPath stringByAppendingPathComponent:file] error: &error];
            
            if (!success)
            {
                NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:[error description], @"error",nil];        
                [self error:[PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:[result JSONString]] callbackId:callbackId];
                return;
            }
        }
    }
    else
    {
        [fileManager createDirectoryAtPath:tempPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
    }
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];     
    tempPath = [tempPath substringFromIndex:[documentsDirectory length]];    
    NSDictionary *result = [NSDictionary dictionaryWithObject:tempPath forKey:@"tempFolderPath"];     
    [self success:[PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:[result JSONString]] callbackId:callbackId];
}

- (void)clearCurrentCourseLocalTempFolder:(NSMutableArray *)args withDict:(NSMutableDictionary *)options{
        
    id<Client> framework = [Framework client];
    NSString *packagePath =[framework getCourseLocalPathRoot:nil];  
    
    NSString *tempPath = [packagePath stringByAppendingString:@"/temp/"];    
    NSFileManager *fileManager = [NSFileManager defaultManager]; 
    NSString *callbackId = [args objectAtIndex:0];
    
    NSError *error;
    
    if ([fileManager fileExistsAtPath:tempPath])
    {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:tempPath error:&error];
        
        if(success != YES)
        {
            NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:[error description], @"error",nil];        
            [self error:[PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:[result JSONString]] callbackId:callbackId];
            return;
        }
    }
    else
    { 
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:@"directory does not exit", @"error",nil];        
        [self error:[PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:[result JSONString]] callbackId:callbackId];
        return;
    }
        
    [self success:[PluginResult resultWithStatus:PGCommandStatus_OK] callbackId:callbackId];
}

- (void)packageDownloadCompletedCallback:(PackageOpenRequestState)state:(NSString*)callbackId
{
    switch (state) {
        case PackageOpenRequestNoConnectivity:
            [self error:[PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:NSLocalizedString(@"PackageOpenNoConnectivity", @"")] callbackId:callbackId];                    
            break;
            
        case PackageOpenRequestSuccess:
            [self success:[PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:@""] callbackId:callbackId];                    
            break;
        
        case PackageOpenRequestNoPackage:
            [self error:[PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:NSLocalizedString(@"PackageOpenNoSuchPackage", @"")] callbackId:callbackId];                    
  
        case PackageOpenRequestResourceMissing:
            [self error:[PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:NSLocalizedString(@"PackageOpenNoSuchResource", @"")] callbackId:callbackId];                    
        case PackageOpenRequestNotDownloaded:
            [self success:[PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:@""] callbackId:callbackId]; 

        default:
            [self error:[PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:NSLocalizedString(@"PackageOpenNoConnectivity", @"")] callbackId:callbackId];                    
            break;
    }
}


- (void)openMenuItem:(NSMutableArray *)args withDict:(NSMutableDictionary *)options
{

    NSUInteger argc = [args count];
    
    if (argc != 2) return;
    
    NSString *menuPath = [args objectAtIndex:1];
    NSString *callbackId = [args objectAtIndex:0];
    
    id<Client> client = [Framework client];
    
    NSRange seperatorLocation = [menuPath rangeOfString:@"."];
    NSString *packageId = nil;
    
    if(seperatorLocation.location != NSNotFound)
    {
        NSArray *strComp = [menuPath componentsSeparatedByString:@"."];
        
        packageId = [strComp objectAtIndex:0];
        
        [client tryOpenPackageItem:packageId callbackId:callbackId path:menuPath completed:^(PackageOpenRequestState state, NSString *callbackId){
            [self packageDownloadCompletedCallback:state :callbackId];
        }];
    }
    else {
        
        //the currently open package
        packageId = [client getCurrentPackageElementId];
        
        menuPath = [packageId stringByAppendingFormat:@".%@", menuPath];
        
        [self success:[PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:@""] callbackId:callbackId];
        
        [client openMenu:menuPath];
    }
}

- (void)openResource:(NSMutableArray *)args withDict:(NSMutableDictionary *)options
{
    
    NSUInteger argc = [args count];
    
    if (argc != 2) return;
    
    NSString *menuPath = [args objectAtIndex:1];
    NSString *callbackId = [args objectAtIndex:0];
    
    id<Client> client = [Framework client];
    
    NSRange seperatorLocation = [menuPath rangeOfString:@"."];
    NSString *packageId = nil;
    
    if(seperatorLocation.location != NSNotFound)
    {
        NSArray *strComp = [menuPath componentsSeparatedByString:@"."];
        
        packageId = [strComp objectAtIndex:0];
        
        [client tryOpenPackageItem:packageId callbackId:callbackId path:menuPath completed:^(PackageOpenRequestState state, NSString *callbackId){
            [self packageDownloadCompletedCallback:state :callbackId];
        }];
    }
    else {
        
        //the currently open package
        packageId = [client getCurrentPackageElementId];
        
        menuPath = [packageId stringByAppendingFormat:@".%@", menuPath];
        
        [self success:[PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:@""] callbackId:callbackId];
        
        [client openResource:menuPath];
    }
}

- (void)getUserUsername:(NSMutableArray *)args withDict:(NSMutableDictionary *)options
{
    NSUInteger argc = [args count];
    
    if (argc != 1) return;

    NSString *callbackId = [args objectAtIndex:0];
    
    id<Client> client = [Framework client];
    NSString *username = [client getUserUsername];

    [self success:[PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:username] callbackId:callbackId];
}

- (void)track:(NSMutableArray *)args withDict:(NSMutableDictionary *)options
{
    NSUInteger argc = [args count];
    
    if (argc != 3) return;
    
    NSString *callbackId = [args objectAtIndex:0];
    NSString *sender = [args objectAtIndex:1];
    NSString *addInfo = [args objectAtIndex:2];

    [[Framework client] track:sender addInfo:addInfo];
    
    [self success:[PluginResult resultWithStatus:PGCommandStatus_OK] callbackId:callbackId];
}

- (void)sync:(NSMutableArray *)args withDict:(NSMutableDictionary *)options
{
    NSUInteger argc = [args count];
    
    if (argc != 1) return;
    
    NSString *callbackId = [args objectAtIndex:0];
//    if ([SettingPreferences userPreferences].tracking == NO) {
//        [[Framework client] notify:NSLocalizedString(@"sync no tracking", @"")];
//        [self success:[PluginResult resultWithStatus:PGCommandStatus_OK messageAsInt:1] callbackId:callbackId];
//        return;
//    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [[Framework client] sync:^(bool success) {
        if (success == false) [[Framework client] notify:NSLocalizedString(@"sync error", @"")];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self success:[PluginResult resultWithStatus:PGCommandStatus_OK messageAsInt:success] callbackId:callbackId];
    }];
}

- (void)initialize:(NSMutableArray *)args withDict:(NSMutableDictionary *)options {
    if ([args count] != 1) return;
    [[Framework client] initialize];
    [self success:[PluginResult resultWithStatus:PGCommandStatus_OK] callbackId:[args objectAtIndex:0]];
}

- (void)terminate:(NSMutableArray *)args withDict:(NSMutableDictionary *)options {
    if ([args count] != 1) return;
    [[Framework client] terminate];
    [self success:[PluginResult resultWithStatus:PGCommandStatus_OK] callbackId:[args objectAtIndex:0]];
}

- (void)setValue:(NSMutableArray *)args withDict:(NSMutableDictionary *)options {
    NSUInteger argc = [args count];
    if (argc != 4) return;
    
    NSString *callbackId = [args objectAtIndex:0];
    NSString *storeType = [args objectAtIndex:1];
    NSString *key = [args objectAtIndex:2];
    NSString *val = [args objectAtIndex:3];
    
    if ([storeType isEqualToString:@"global"] == NO && [key isEqualToString:@"cmi.total_time"]) {
        [self error:[PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsInt:0] callbackId:callbackId];
        return;
    }
        
    [[Framework client] setValue:val forKey:key storeType:storeType];
    [self success:[PluginResult resultWithStatus:PGCommandStatus_OK messageAsInt:1] callbackId:callbackId];
}

- (void)getValue:(NSMutableArray *)args withDict:(NSMutableDictionary *)options {
    NSUInteger argc = [args count];
    if (argc != 3) return;
    
    NSString *callbackId = [args objectAtIndex:0];
    NSString *storeType = [args objectAtIndex:1];
    NSString *key = [args objectAtIndex:2];
    NSString *val = @"";
    
    val = [[Framework client] getValueForKey:key storeType:storeType];
    
    [self success:[PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:val] callbackId:callbackId];
}
//
//- (void)logout:(NSMutableArray *)args withDict:(NSMutableDictionary *)options
//{
//    NSUInteger argc = [args count];
//    
//    if (argc != 1) return;
//    
//    NSString *callbackId = [args objectAtIndex:0];
//
//    [self success:[PluginResult resultWithStatus:PGCommandStatus_OK] callbackId:callbackId];
//    
//    [[Framework client] logout];
//    
//}

@end
