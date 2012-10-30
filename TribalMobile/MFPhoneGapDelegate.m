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

#import "MFPhoneGapDelegate.h"
#import "CDVBackupInfo.h"

#define IsAtLeastiOSVersion(X) ([[[UIDevice currentDevice] systemVersion] compare:X options:NSNumericSearch] != NSOrderedAscending)

@interface MFPhoneGapDelegate ()

- (void) restoreCurrentContext;

@property (nonatomic) BOOL restoreRequired;
@property (nonatomic, copy) NSString* webStorageContext;
@property (nonatomic, readwrite, retain) NSMutableArray* backupInfo;  // array of CDVBackupInfo objects

@end


@implementation MFPhoneGapDelegate

@synthesize backupInfo;
@synthesize restoreRequired;

+ (NSString *)getBackupPath
{
    NSString* appDocumentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [appDocumentsFolder stringByAppendingPathComponent:@"Backups"];
}

- (NSString *)webStorageContext
{
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastWebStorageContext"];
    
    if (value != nil && [value isKindOfClass:[NSString class]])
        return value;
    else 
        return nil;
}

- (void)setWebStorageContext:(NSString *)_webStorageContext
{    
    [[NSUserDefaults standardUserDefaults] setObject:_webStorageContext forKey:@"lastWebStorageContext"];
}

- (id)init
{	
    if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onResignActive)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onResignActive) 
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        NSString *original, *backup;
        self.backupInfo = [NSMutableArray arrayWithCapacity:3];
        
        // set up common folders
        NSString* appLibraryFolder = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)objectAtIndex:0];
        NSString *backupsFolder = [[MFPhoneGapDelegate getBackupPath] stringByAppendingString:@"/{webStorageContext}"];
        
        //////////// LOCALSTORAGE
        
        original = [[appLibraryFolder stringByAppendingPathComponent:
                     (IsAtLeastiOSVersion(@"5.1")) ? @"Caches" : @"WebKit/LocalStorage"]
                    stringByAppendingPathComponent:@"file__0.localstorage"]; 
        
        backup = [backupsFolder stringByAppendingPathComponent:@"localstorage.appdata.db"];
        
        CDVBackupInfo* backupItem = [[[CDVBackupInfo alloc] init] autorelease];
        backupItem.backup = backup;
        backupItem.original = original;
        backupItem.label = @"localStorage database";
        
        [self.backupInfo addObject:backupItem];
        
        //////////// WEBSQL MAIN DB
        
        original = [[appLibraryFolder stringByAppendingPathComponent:
                     (IsAtLeastiOSVersion(@"5.1")) ? @"Caches" : @"WebKit/Databases"]
                    stringByAppendingPathComponent:@"Databases.db"]; 
        
        backup = [backupsFolder stringByAppendingPathComponent:@"websqlmain.appdata.db"];
        
        backupItem = [[[CDVBackupInfo alloc] init] autorelease];
        backupItem.backup = backup;
        backupItem.original = original;
        backupItem.label = @"websql main database";
        
        [self.backupInfo addObject:backupItem];
        
        //////////// WEBSQL DATABASES
        
        original = [[appLibraryFolder stringByAppendingPathComponent:
                     (IsAtLeastiOSVersion(@"5.1")) ? @"Caches" : @"WebKit/Databases"]
                    stringByAppendingPathComponent:@"file__0"]; 
        
        backup = [backupsFolder stringByAppendingPathComponent:@"websqldbs.appdata.db"];
        
        backupItem = [[[CDVBackupInfo alloc] init] autorelease];
        backupItem.backup = backup;
        backupItem.original = original;
        backupItem.label = @"websql databases";
        
        [self.backupInfo addObject:backupItem];
        
        // verify the and fix the iOS 5.1 database locations once
        [self verifyAndFixDatabaseLocations:nil withDict:nil];
                
        [self backupCurrentContext:YES];
    }
    return self;
}

-(void)backupToNewStorageContext:(NSString *)context
{
    if ((self.webStorageContext == nil && context != nil)
    || (self.webStorageContext != nil && context == nil)
    || (![self.webStorageContext isEqualToString:context]))
    {    
        [self backupCurrentContext:NO];        
        self.webStorageContext = context;
        
        if (context != nil)
            self.restoreRequired = YES;
    }
}

#pragma mark -
#pragma mark Plugin interface methods

- (BOOL) copyFrom:(NSString*)src to:(NSString*)dest error:(NSError**)error
{    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    
    if ([fileManager fileExistsAtPath:dest])
    {
        if (![fileManager removeItemAtPath:dest error:error])
            return NO;
    }
    
    if ([fileManager fileExistsAtPath:src])
    {
        NSString *directory = [dest stringByDeletingLastPathComponent];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:directory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        
        return [fileManager copyItemAtPath:src toPath:dest error:error];
    }
    
    return NO;
}

- (void) clearWebCacheInternal
{
    for (CDVBackupInfo* info in self.backupInfo)
    {
        [[NSFileManager defaultManager] removeItemAtPath:info.original error:nil];
    }
}

- (void) clearWebCache
{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"lastWebStorageContext"];    
    [self clearWebCacheInternal];
}

/* copy from webkitDbLocation to persistentDbLocation */
- (void) backupCurrentContext:(BOOL)onlyNewerFiles
{
    if (self.webStorageContext == nil)
        return;
    
    NSError* error = nil;
    NSString* message = nil;
    
    for (CDVBackupInfo* info in self.backupInfo)
    {        
        NSString *oldPath = [info.backup copy];
        
        info.backup = [info.backup stringByReplacingOccurrencesOfString:@"{webStorageContext}" withString:self.webStorageContext];
        
        if (onlyNewerFiles == NO || [info shouldBackup])
        {
            BOOL moved = [self copyFrom:info.original to:info.backup error:&error];
            
            if (error != nil)
            {
                message = [NSString stringWithFormat:@"Error in CDVLocalStorage (%@) backup: %@", info.label, [error localizedDescription]];
                NSLog(@"%@", message);
            }
            else if (moved)
            {
                message = [NSString stringWithFormat:@"Backed up: %@", info.label];
                NSLog(@"%@", message);
            }
        }
        
        info.backup = oldPath;
        [oldPath release];
    }
}

/* copy from persistentDbLocation to webkitDbLocation */
- (void) restoreCurrentContext
{
    if (self.webStorageContext == nil)
        return;
        
    [self clearWebCacheInternal];
    
    NSError* error = nil;
    NSString* message = nil;
    
    for (CDVBackupInfo* info in self.backupInfo)
    {        
        NSString *backupPath = [info.backup stringByReplacingOccurrencesOfString:@"{webStorageContext}" withString:self.webStorageContext];
        
        BOOL moved = [self copyFrom:backupPath to:info.original error:&error];
        
        if (error != nil)
        {
            message = [NSString stringWithFormat:@"Error in CDVLocalStorage (%@) backup: %@", info.label, [error localizedDescription]];
            NSLog(@"%@", message);
        }
        else if (moved)
        {
            message = [NSString stringWithFormat:@"Restored: %@", info.label];
            NSLog(@"%@", message);
        }
    }
}

- (void) verifyAndFixDatabaseLocations:(NSArray*)arguments withDict:(NSMutableDictionary*)options
{
    NSString* libraryCaches = @"Library/Caches";
    NSString* libraryWebKit = @"Library/WebKit";
    NSString* libraryPreferences = @"Library/Preferences";
    
    NSUserDefaults* appPreferences = [NSUserDefaults standardUserDefaults];
    NSBundle* mainBundle = [NSBundle mainBundle];
    
    NSString* bundlePath = [[mainBundle bundlePath] stringByDeletingLastPathComponent];
    NSString* bundleIdentifier = [[mainBundle infoDictionary] objectForKey:@"CFBundleIdentifier"];
    
    NSString* appPlistPath = [[bundlePath stringByAppendingPathComponent:libraryPreferences] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", bundleIdentifier]];
    NSMutableDictionary* appPlistDict = [NSMutableDictionary dictionaryWithContentsOfFile:appPlistPath];
    
    NSArray* keysToCheck = [NSArray arrayWithObjects:
                            @"WebKitLocalStorageDatabasePathPreferenceKey", 
                            @"WebDatabaseDirectory", 
                            nil];
    
    BOOL dirty = NO;
    
    for (NSString* key in keysToCheck) 
    {
        NSString* value = [appPlistDict objectForKey:key];
        // verify key exists, and path is in app bundle, if not - fix
        if (value != nil && ![value hasPrefix:bundlePath]) 
        {
            // the pathSuffix to use may be wrong - OTA upgrades from < 5.1 to 5.1 do keep the old path Library/WebKit, 
            // while Xcode synced ones do change the storage location to Library/Caches
            NSString* newBundlePath = [bundlePath stringByAppendingPathComponent:libraryCaches];
            if (![[NSFileManager defaultManager] fileExistsAtPath:newBundlePath]) {
                newBundlePath = [bundlePath stringByAppendingPathComponent:libraryWebKit];
            }
            [appPlistDict setValue:newBundlePath forKey:key];
            dirty = YES;
        }
    }
    
    if (dirty) 
    {
        BOOL ok = [appPlistDict writeToFile:appPlistPath atomically:YES];
        NSLog(@"Fix applied for database locations?: %@", ok? @"YES":@"NO");
        
        [appPreferences synchronize];        
    }
}

#pragma mark -
#pragma mark Notification handlers

- (void) onResignActive
{
    NSLog(@"onResignActive");
    if ([[UIDevice currentDevice] isMultitaskingSupported]) 
    {
        __block UIBackgroundTaskIdentifier backgroundTaskID = UIBackgroundTaskInvalid;
        
        backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"Background task to backup WebSQL/LocalStorage expired.");
        }];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [self backupCurrentContext:NO];
            
            [[UIApplication sharedApplication] endBackgroundTask: backgroundTaskID];
            backgroundTaskID = UIBackgroundTaskInvalid;
        });
    }
}

#pragma mark -
#pragma mark UIWebviewDelegate implementation and forwarding

- (void) webViewDidStartLoad:(UIWebView*)theWebView
{
    if (self.restoreRequired)
    {
        self.restoreRequired = NO;         
        [self restoreCurrentContext];
    }       
    
    return [super webViewDidStartLoad:theWebView];
}

- (void) webViewDidFinishLoad:(UIWebView*)theWebView 
{
    return [super webViewDidFinishLoad:theWebView];
}

- (void) webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error 
{
    return [super webView:theWebView didFailLoadWithError:error];
}

- (BOOL) webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    return [super webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType];
}

#pragma mark -
#pragma mark Over-rides

- (void) dealloc
{
    self.webStorageContext = nil;
    self.backupInfo = nil;    
    [super dealloc];
}

@end
