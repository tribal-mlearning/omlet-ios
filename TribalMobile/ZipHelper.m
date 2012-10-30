//
//  ZipHelper.m
//  TribalMobile
//
//  Created by Sean Brotherton on 03/05/2012.
//  Copyright (c) 2012 Tribal Group. All rights reserved.
//

#import "ZipHelper.h"
#import "ZipArchive.h"

@implementation ZipHelper

+ (void)unZipFile:(NSString *)filePath destination:(NSString *)destination onComplete:(ZipComplete)onComplete
{
    dispatch_queue_t zipQueue = dispatch_queue_create("zip queue", NULL);
    
    dispatch_async(zipQueue, ^{
        
         BOOL result = NO;
                
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            ZipArchive *za = [[ZipArchive new] autorelease];
            if ([za UnzipOpenFile:filePath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:destination withIntermediateDirectories:YES attributes:nil error:nil];
                result = [za UnzipFileTo:destination overWrite:YES];
                if (result == NO) {
                    NSLog(@"unexpected problem");
                }
                [za UnzipCloseFile];
            } else {
                NSLog(@"cannot open zip file");
            }
        } else {
            NSLog(@"file doesn't exist");
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            onComplete(result);
        });       
        
    });
    
    dispatch_release(zipQueue);
}

@end
