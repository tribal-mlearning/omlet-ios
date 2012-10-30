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

#import "Framework.h"
#import <PhoneGap/JSONKit.h>
#import "PackageInstaller.h"
#import "PEResource.h"
#import "FinderPackage.h"
#import "Client.h"
#import "SettingsTable.h"

@implementation Framework
@synthesize connectionType, serverURL, finderPackage;
@synthesize packagePath;
@synthesize delegate;
@synthesize currentPackageTitle;
@synthesize useDiskCache;

id<Server> _server;
id<Client> _client;

- (id)init {
    if (self = [super init]) {
        [Framework setServer:self];
        [Framework setClient:self];
        self.serverURL = @"";
        serverDelta = NSIntegerMax;
        connectionType = HttpConnectionDataTypeJSON;
        syncing = NO;
        counter = 0;
        useDiskCache = NO;
        
        packageCataloguePath = [[[PackageInstaller getRootPackagePath] stringByAppendingPathComponent:@"/packagecatalogue.plist"] retain];
        packageCategoriesPath = [[[PackageInstaller getRootPackagePath] stringByAppendingPathComponent:@"/packagecategories.plist"] retain];
        
    }
    return self;
}

+ (void)setServer:(id<Server>)server
{
    _server = server;
}

+ (id<Server>)server
{
    return _server;
}

+ (void)setClient:(id<Client>)client
{
    _client = client;
}

+ (id<Client>)client
{
    return _client;
}

- (NSString *)getUserId {
    return userId;
}

- (NSString *)getUserUsername
{
    return username;
}

- (NSString *)getUserPassword
{
    return password;
}

- (NSString *)getCurrentPackageId{
    return [[packagePath lastPathComponent] stringByDeletingPathExtension];
}

- (NSString *)getCourseLocalPathRoot:(NSString *)packageId{
    
    NSString *result = nil;
    
    if (packageId == nil)
        result = packagePath;
    else
    {
        // not sure what this package id will retain to now. have changed it to the unique id of the package, but its just a guess...
        
        id packageList = [PackageInstaller getPackageList];
        
        for (NSDictionary* package in packageList) {
            if ([[package objectForKey:@"uniqueId"] isEqualToString:packageId]) {                
                result = [package objectForKey:@"path"]; 
                break;
            }
        } 
        
        /*for (NSDictionary* package in packageList) {
            if ([[[[package objectForKey:@"fileUrl"] lastPathComponent] stringByDeletingPathExtension] isEqualToString:packageId]) {                
                result = [package objectForKey:@"path"]; 
                break;
            }
        }*/
    }
    
    return result;
}

- (void)login:(NSString *)_username password:(NSString *)_password
        onAuthenticationCompleted:(OnAuthenticationCompleted)onAuthenticationCompleted
{
    username = [_username retain];
    password = [_password retain];
    
    NSString *url = [serverURL stringByAppendingPathComponent:@"/user-layer/validate"];
    
    HttpConnectionOnSuccess succ = ^(NSString *data) {
        NSDictionary *result = [data objectFromJSONString];
        NSNumber *success = [result objectForKey:@"success"];
        bool authenticated = [success boolValue];
        if (authenticated) {
            NSNumber *userInt = [result objectForKey:@"userId"];
            userId = [[userInt stringValue] copy];
        }
        onAuthenticationCompleted(authenticated, nil);
    };
    
    HttpConnectionOnError err = ^(NSError *error) {
        NSLog(@"Framework.login onError(%@)", error);
        
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[error code]], @"error",nil];
        
        
        onAuthenticationCompleted(false, [result JSONString]);
    };
    AuthHttpConnection *conn = [AuthHttpConnection postUrl:url  data:nil onStart:^{} onSuccess:succ onError:err];
    conn.connectionDataType = connectionType;
    [conn start];
}

//- (void)connection:(HttpConnection *)conn completed:(BOOL)sucessful {
//    [conn release];
//}

- (void)dealloc
{
    self.currentPackageTitle = nil;
    if (userId) [userId release];
    if (username) [username release];
    if (password) [password release];
    if (finderPackage) [finderPackage release];
    if (element) [element release];
    if (categories) {[categories release]; categories = nil;}
    if(packages) [packages release];
    [serverURL release];
    if (session.isValid) [session invalidate];
    [session release];
    [packageCataloguePath release];
    [packageCategoriesPath release];
    [super dealloc];
}

- (void)getServerDelta:(OnServerDelta)onServerDelta
{
    if (serverDelta == NSIntegerMax) {
        NSString *url = [serverURL stringByAppendingPathComponent:@"/time-layer/time"];
        HttpConnection *conn = [HttpConnection getUrl:url data:nil onStart:^{
        } onSuccess:^(NSString *data) {
            NSDictionary *result = [data objectFromJSONString];
            NSNumber *time = [result objectForKey:@"time"];
            serverDelta = [time integerValue];
            serverDelta = [[NSDate date] timeIntervalSince1970] - serverDelta;
            serverDelta = serverDelta * 1000;
            onServerDelta(serverDelta);
        } onError:^(NSError *error) {
            NSLog(@"Framework.getServerDelta(): %@", error);
            onServerDelta(0);
        }];
        [conn start];
    } else {
        onServerDelta(serverDelta);
    }    
}

- (void)notify:(NSString *)msg {
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"OMLET" message:msg delegate:nil cancelButtonTitle:NSLocalizedString(@"DialogOK", @"") otherButtonTitles:nil];
    [av show];
}

- (void)updateUserId:(NSString *)_userId username:(NSString *)_username password:(NSString *)_password {
    if (userId) [userId release];
    if (username) [username release];
    if (password) [password release];
    
    if (_userId) userId = [_userId copy]; 
    else userId = nil;
    if (_username) username = [_username copy];
    else username = nil;
    if (_password) password = [_password copy];
    else password = nil;
}


- (void)getPackages:(OnAuthenticationCompleted)onAuthenticationCompleted {
    
    if(useDiskCache)
    {
        if(!packages){
            packages = [[self loadPackagesFromDisk] retain];
        }
        
        if(packages){
            onAuthenticationCompleted(true,packages);
            return;
        }
    }
    
    NSString *url = [serverURL stringByAppendingPathComponent:@"/package-layer/packages"];
    
    HttpConnectionOnSuccess succ = ^(NSString *jsondata) {
        if ([jsondata isEqualToString:@""] == NO && [jsondata rangeOfString:@"failed"].location == NSNotFound){
            
            NSMutableArray *mCourses;
            id data = [jsondata objectFromJSONString]; 
            if([data isKindOfClass:[NSDictionary class]])
            {
                //Service has returned packages along with category data
                
                NSDictionary *dict = [NSDictionary dictionaryWithDictionary:data];
                mCourses = [NSMutableArray arrayWithArray:[dict objectForKey:@"packages"]];
                
                if(categories){
                    [categories release];
                    categories = nil;
                }
                categories = [[NSMutableArray arrayWithArray:[dict objectForKey:@"categories"]] retain];
                if(useDiskCache){
                    [self cachePackageCategoriesToDisk:[NSArray arrayWithArray:categories]];
                }
            }
            else {
                mCourses = [NSMutableArray arrayWithArray:data];
            }
            
            if(useDiskCache){
                if(packages){
                    [packages release];
                    packages = nil;
                }
                packages = [[NSArray arrayWithArray:mCourses] retain];
                [self cachePackagesToDisk:packages];
            }
            
            onAuthenticationCompleted(true, mCourses);
        }
        else onAuthenticationCompleted(false, nil);
    };
    
    HttpConnectionOnError err = ^(NSError *error) {
        NSLog(@"Framework.getPackages onError(%@)", error);
        onAuthenticationCompleted(false, nil);
    };
    AuthHttpConnection *conn = [AuthHttpConnection getUrl:url  data:nil onStart:^{} onSuccess:succ onError:err];
    conn.connectionDataType = connectionType;
    [conn start];
}

-(void)getCategories:(OnAuthenticationCompleted)onAuthenticationCompleted
{
    if(useDiskCache){
        if(!categories){
            categories = [[self loadCategoriesFromDisk] retain];
        }
//        [categories retain];
        if(categories){
            onAuthenticationCompleted(true,categories);
            return;
        }
    }
    
    [self getPackages:^(bool authenticated, id data) {
                onAuthenticationCompleted(authenticated,categories);}];
    
}

-(void) getNews:(OnAuthenticationCompleted)onAuthenticationCompleted{
    NSString *url = [serverURL stringByAppendingPathComponent:@"/news-layer/news"];
    
    HttpConnectionOnSuccess succ = ^(NSString *data) {
        if ([data isEqualToString:@""] == NO && [data rangeOfString:@"failed"].location == NSNotFound)
            onAuthenticationCompleted(true, [data objectFromJSONString]);
        else onAuthenticationCompleted(false, nil);
    };
    
    HttpConnectionOnError err = ^(NSError *error) {
        NSLog(@"Framework.getNews onError(%@)", error);
        onAuthenticationCompleted(false, nil);
    };
    AuthHttpConnection *conn = [AuthHttpConnection getUrl:url  data:nil onStart:^{} onSuccess:succ onError:err];
    conn.connectionDataType = connectionType;
    [conn start];
}


-(BOOL) setCurrentPacakge:(NSString*)resourcePath
{
    NSRange seperatorLocation = [resourcePath rangeOfString:@"."];

    if(seperatorLocation.location != NSNotFound)
    {
        NSString *packageId = [resourcePath substringToIndex:seperatorLocation.location];
        
        NSLog(@"current package: %@ new: %@", self.finderPackage.pacakgeId, packageId);
        
        if(!([self.finderPackage.pacakgeId isEqualToString:packageId]))
        {            
            self.finderPackage = [delegate finderPacakgeFor:packageId];
            self.packagePath = self.finderPackage.packagePath;
            
            if ([self.delegate respondsToSelector:@selector(packageChanged:)])
            {
                [self.delegate packageChanged:packageId];
            }
        }
    }
    return true;
}


-(void) openMenu:(NSString *)menuPath{

    if([self setCurrentPacakge:menuPath])
    {
        if (finderPackage && delegate)
        {    
            PEBase *base = nil; 
            NSRange seperatorLocation = [menuPath rangeOfString:@"."];
            if(seperatorLocation.location != NSNotFound)
            {
                NSString *pElementId = [menuPath substringFromIndex:seperatorLocation.location + 1];
                base = [finderPackage getElementByPath:[[finderPackage getIdForPackage:0] stringByAppendingFormat:@".%@",pElementId]];
            }
            //PEBase *base = [finderPackage getElementByPath:menuPath];
            
            if ([base isKindOfClass:[PEMenu class]])
                [delegate openMenu:(PEMenu *)base];
        }
    }
}

- (void)openResource:(NSString *)resourcePath{
    if([self setCurrentPacakge:resourcePath])
    {
        if (finderPackage && delegate)
        {
            PEBase *base = nil; 
            NSRange seperatorLocation = [resourcePath rangeOfString:@"."];
            if(seperatorLocation.location != NSNotFound)
            {
                NSString *pElementId = [resourcePath substringFromIndex:seperatorLocation.location + 1];
                base = [finderPackage getElementByPath:[[finderPackage getIdForPackage:0] stringByAppendingFormat:@".%@",pElementId]];
            }
            else {
                base = [finderPackage getElementByPath:resourcePath];
            }
            
            if ([base isKindOfClass:[PEResource class]])
                [delegate openResource:(PEResource *)base];
        }
    }
}

-(void)openItem:(NSString*)resourcePath
{
    if([self setCurrentPacakge:resourcePath])
    {
        if(finderPackage && delegate)
        {
            PEBase *base = [finderPackage getElementByPath:resourcePath];
            if([base isKindOfClass:[PEResource class]]){
                [delegate openResource:(PEResource *)base];
            }
            else if([base isKindOfClass:[PEMenu class]]){
                [delegate openMenu:(PEMenu *)base];
            }
        }
    }
}

- (NSString *)getCurrentPackageElementId
{
    if (finderPackage)
        return [finderPackage getIdForPackage:0];
    else
        return nil;
}


- (PEBase*)entryPointForCourseWithPath:(NSString*)coursePath
{
    NSString *package = [coursePath stringByAppendingPathComponent:@"/package.xml"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:package] == NO) return nil;
    
    FinderPackage *finder = [[[FinderPackage alloc] initWithXML:package] autorelease];
    //((Framework *)[Framework client]).finderPackage = finder;
    return [finder getEntryPointForPackage:0];
}

- (void) tryOpenPackageItem:(NSString *)packageId callbackId:(NSString*)callbackId path:(NSString*)path completed:(PackageOpenRequestCompleted)completed;
{
    [delegate showIndicator:UIActivityIndicatorViewStyleGray location:CGPointMake(160, 240)];
    if(![PackageInstaller getPackage:packageId])
    { 
        if([delegate isOnlineModeActive])
        {
            id<Server> server = [Framework server];
            
            //Get the list of courses from the server, 
            [server getPackages:^(bool success, id data) {
                if (success) {
                    NSMutableArray *mCourses = [NSMutableArray arrayWithArray:data];
                    NSDictionary *foundCourse = nil;
                    for(NSDictionary *course in mCourses)
                    {
                        if([[course objectForKey:@"uniqueId"] isEqualToString:packageId])
                        {
                            foundCourse = course;
                            break;
                        }
                    }
                    if(foundCourse)
                    {
                        //Course found on server, check if user wants to download it
                        [delegate determineActionForNotDownloadedPackage:packageId pacakgeName:[foundCourse objectForKey:@"title"]];
                        completed(PackageOpenRequestNotDownloaded,callbackId);
                        [delegate hideIndicator];
                    }
                    else {
                        //Course not found on server
                        completed(PackageOpenRequestNoPackage,callbackId); 
                        [delegate hideIndicator];
                    }
                }
                //server didn't respond
                completed(PackageOpenRequestNoConnectivity,callbackId);
                [delegate hideIndicator];
            }];
        }
        else {
            //No connectivity, can't access coure list to perform checks
            completed(PackageOpenRequestNoConnectivity,callbackId);
            [delegate hideIndicator];
        }
    }
    else
    {
        //Package already exists locally, open it        
        FinderPackage *p = [delegate finderPacakgeFor:packageId];
        if([p getElementByPath:path])
        {
            [self openItem:path];
            completed(PackageOpenRequestSuccess,callbackId);
            [delegate hideIndicator];
        }
        else {
            //The requested resource is missing
            completed(PackageOpenRequestResourceMissing,callbackId);
            [delegate hideIndicator];
        }
    }
}

- (void)track:(NSString *)sender addInfo:(NSString *)addInfo
{
    [trackEngine track:sender addInfo:addInfo];
}

- (void)sendSyncData:(SyncCallback)callback
{
    NSMutableDictionary *track = [trackEngine fetchTrack];
    if (track == nil) return callback(true);
    
    NSString *trackId = [[track objectForKey:@"_id"] retain];
    
    [track removeObjectForKey:@"_id"];
    NSArray *content = [NSArray arrayWithObject:track];
    
    NSString *url = [serverURL stringByAppendingPathComponent:@"/track-layer/tracks"];
    
    AuthHttpConnection *conn = [AuthHttpConnection postUrl:url data:content onStart:^{
    } onSuccess:^(NSString *data) {
        [trackEngine removeTrack:trackId];
        [trackId release];
        [self sendSyncData:callback];
    } onError:^(NSError *error) {
        NSLog(@"*********** ERROR **************");
        [trackId release];
        callback(false);
    }];
    
    conn.connectionDataType = connectionType;
    [conn start];
}

- (TrackEngine *)getTrackEngine
{
    if (!trackEngine) {
        trackEngine = [TrackEngine new];
    }
    return trackEngine;
}

- (void)setCurrentElement:(PEBase *)_element {
    if (element != _element) {
        if (element) { 
            [element release];
            element = nil;
        }
        if (_element) element = [_element retain];
        [[self getTrackEngine] updateElement:element];
    }
}

- (PEBase *)getCurrentElement {
    return element;
}

- (void)sessionTimer:(NSTimer *)timer {
    counter++;
}

- (void)initialize {
    counter = 0;
    if (session == nil)
        session = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:
                    self selector:@selector(sessionTimer:) userInfo:nil repeats:YES] retain];
}

- (void)terminate {
    if (counter == 0) return;
    
    long long total = [[self getValueForKey:@"cmi.total_time" storeType:@"specific"] longLongValue];
    total += counter;
    [self setValue:[[NSNumber numberWithLongLong:total] stringValue] forKey:@"cmi.total_time" storeType:@"specific"];
    counter = 0;
    if (session) {
        if (session.isValid) [session invalidate];
        [session release];
        session = nil;
    }
}

- (NSString *)getValueForKey:(NSString *)key storeType:(NSString *)sType {
    SettingsTable *st = [SettingsTable new];
    if ([sType isEqualToString:@"global"])
         [st loadValueByKey:key andUserId:[self getUserUsername]];
    else { 
        if ([key isEqualToString:@"cmi.session_time"]) return [[NSNumber numberWithLongLong:counter] stringValue];
        [st loadValueByKey:key andUserId:[self getUserUsername] andObjectId:[[self getCurrentElement] getFullId]];
    }
    NSString *val = st.value;
    if ([sType isEqualToString:@"specific"] && [key isEqualToString:@"cmi.total_time"])
        val = [[NSNumber numberWithLongLong:[val longLongValue] + counter] stringValue];
    [val retain];
    [st release];
    return [val autorelease];
}

- (void)setValue:(NSString *)val forKey:(NSString *)key storeType:(NSString *)sType {
    SettingsTable *st = [SettingsTable new];
    if ([sType isEqualToString:@"global"])
        [st setValue:val forKey:key andUserId:[self getUserUsername]];
    else { 
        [st setValue:val forKey:key andUserId:[self getUserUsername] andObjectId:[[self getCurrentElement] getFullId]];
        
        if (([key isEqualToString:@"cmi.completion_status"] || [key isEqualToString:@"cmi.success_status"] 
             || [key isEqualToString:@"cmi.total_time"])) {
            NSDictionary *dict = [NSDictionary dictionaryWithObject:val forKey:key];
            [self track:@"mf" addInfo:[[NSArray arrayWithObject:
                                        [NSDictionary dictionaryWithObject:
                                         dict forKey:@"session"]] JSONString]];
            
            if (delayedSyncing == NO) {
                delayedSyncing = YES;
                [(NSObject *) delegate performSelector:@selector(syncTask:) withObject:nil afterDelay:15];
            }
        }
    }
    [st release];
}

- (void)sync:(SyncCallback)callback
{
//    if (syncing && callback) return callback(false);
    syncing = YES;
    [trackEngine trackSync];
    [self sendSyncData:^(bool success) {
        syncing = NO;
        delayedSyncing = NO;
        if (callback) callback(success);
    }];
}

-(void)cachePackagesToDisk:(NSArray*)_packages{
    
    NSString *error;
    
    NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:packages
                                                                 format:NSPropertyListBinaryFormat_v1_0
                                                       errorDescription:&error];
    
    if (xmlData) [xmlData writeToFile:packageCataloguePath atomically:YES];     
}

-(NSArray*)loadPackagesFromDisk{
    
    NSArray *diskPackages = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:packageCataloguePath]) {
        NSPropertyListFormat format;
        NSString *error;
        
        diskPackages = [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfFile:packageCataloguePath]
                                                           mutabilityOption:NSPropertyListMutableContainers
                                                                     format:&format
                                                           errorDescription:&error];
    } 
    return diskPackages;
}

-(void)cachePackageCategoriesToDisk:(NSArray*)_categories{
    
    NSString *error;
    
    NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:categories
                                                                 format:NSPropertyListBinaryFormat_v1_0
                                                       errorDescription:&error];
    
    if (xmlData) [xmlData writeToFile:packageCategoriesPath atomically:YES]; 
}

-(NSArray *)loadCategoriesFromDisk{
    NSArray *diskCategories = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:packageCategoriesPath]) {
        NSPropertyListFormat format;
        NSString *error;
        
        diskCategories = [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfFile:packageCategoriesPath]
                                                         mutabilityOption:NSPropertyListMutableContainers
                                                                   format:&format
                                                         errorDescription:&error];
    } 
    return diskCategories;
}

-(void)clearCachedData{
    [[NSFileManager defaultManager] removeItemAtPath:packageCataloguePath error:nil]; 
    [[NSFileManager defaultManager] removeItemAtPath:packageCategoriesPath error:nil];
}

@end
