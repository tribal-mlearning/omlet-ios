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

#import "CDVBackupInfo.h"

@implementation CDVBackupInfo
@synthesize original, backup, label;

- (void)dealloc
{
    self.original = nil;
    self.backup = nil;
    self.label = nil;
    
    [super dealloc];
}

- (BOOL) file:(NSString*)aPath isNewerThanFile:(NSString*)bPath
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    
    NSDictionary* aPathAttribs = [fileManager attributesOfItemAtPath:aPath error:&error];
    NSDictionary* bPathAttribs = [fileManager attributesOfItemAtPath:bPath error:&error];
    
    NSDate* aPathModDate = [aPathAttribs objectForKey:NSFileModificationDate];
    NSDate* bPathModDate = [bPathAttribs objectForKey:NSFileModificationDate];
    
    if (nil == aPathModDate && nil == bPathModDate) {
        return NO;
    }
    
    return ([aPathModDate compare:bPathModDate] == NSOrderedDescending || bPathModDate == nil);
}

- (BOOL) item:(NSString*)aPath isNewerThanItem:(NSString*)bPath
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    BOOL aPathIsDir = NO, bPathIsDir = NO;
    BOOL aPathExists = [fileManager fileExistsAtPath:aPath isDirectory:&aPathIsDir];
    [fileManager fileExistsAtPath:bPath isDirectory:&bPathIsDir];
    
    if (!aPathExists) { 
        return NO;
    }
    
    if (!(aPathIsDir && bPathIsDir)){ // just a file
        return [self file:aPath isNewerThanFile:bPath];
    }
    
    // essentially we want rsync here, but have to settle for our poor man's implementation
    // we get the files in aPath, and see if it is newer than the file in bPath 
    // (it is newer if it doesn't exist in bPath) if we encounter the FIRST file that is newer,
    // we return YES
    NSDirectoryEnumerator* directoryEnumerator = [fileManager enumeratorAtPath:aPath];
    NSString* path;
    
    while ((path = [directoryEnumerator nextObject])) {
        NSString* aPathFile = [aPath stringByAppendingPathComponent:path];
        NSString* bPathFile = [bPath stringByAppendingPathComponent:path];
        
        BOOL isNewer = [self file:aPathFile isNewerThanFile:bPathFile];
        if (isNewer) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL) shouldBackup
{
    return [self item:self.original isNewerThanItem:self.backup];
}

- (BOOL) shouldRestore
{
    return [self item:self.backup isNewerThanItem:self.original];
}
@end
