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

/** @file Framework.h */

#import <Foundation/Foundation.h>

#import "AuthHttpConnection.h"
#import "Server.h"
#import "Client.h"
#import "FinderPackage.h"
#import "PEMenu.h"
#import "PEResource.h"

#ifdef PHONEGAP_FRAMEWORK
#import <PhoneGap/Reachability.h>
#else
#import "PhoneGap/Reachability.h"
#endif

@protocol FrameworkDelegate <NSObject>

-(BOOL)isOnlineModeActive;
- (void) openMenu:(PEMenu *)_menu;
- (void) openResource:(PEResource *)resource;
- (FinderPackage*) finderPacakgeFor:(NSString*)packageId;
- (void) determineActionForNotDownloadedPackage:(NSString*)packageId pacakgeName:(NSString*)packageName;
- (void)showIndicator:(UIActivityIndicatorViewStyle)style location:(CGPoint)point;
- (void)hideIndicator;

@optional
- (void)packageChanged:(NSString*)packageId;
@end

/** Framework.
 * Main class for connecting to the Tribal servers and communicating
 * with the main controller
 */
@interface Framework : NSObject<Server, Client, HttpConnectionDelegate> {
@private
    NSString *userId;
    NSString *username;
    NSString *password;
    NSInteger serverDelta;
    BOOL syncing;
    BOOL delayedSyncing;
    TrackEngine *trackEngine;
    PEBase* element;
    long long counter;
    NSTimer *session;
    NSArray *categories;
    NSArray *packages;
    
    NSString *packageCataloguePath;
    NSString *packageCategoriesPath; 
}

@property (nonatomic, copy) NSString *serverURL; ///< URL webservice
@property (nonatomic, assign) HttpConnectionDataType connectionType; ///< Data type sent to server
@property (nonatomic, copy) NSString *packagePath;
@property (nonatomic, retain) FinderPackage *finderPackage;
@property (nonatomic, assign) id<FrameworkDelegate> delegate;
@property (nonatomic, copy) NSString *currentPackageTitle;
@property (nonatomic, assign) BOOL useDiskCache;

/** setServer.
 *  set the common server class
 *  @param[in] server
 */
+ (void)setServer:(id<Server>)server;

/** server.
 *  get the common server class
 *  @return server
 */
+ (id<Server>)server;

/** setClient.
 *  set the common client class
 *  @param[in] client
 */
+ (void)setClient:(id<Client>)client;

/** client.
 *  get the common client class
 *  @return client
 */
+ (id<Client>)client;


- (PEBase*)entryPointForCourseWithPath:(NSString*)coursePath;

-(BOOL) setCurrentPacakge:(NSString*)resourcePath;

-(void)cachePackagesToDisk:(NSArray*)_packages;
-(NSArray*)loadPackagesFromDisk;
-(void)cachePackageCategoriesToDisk:(NSArray*)_categories;
-(NSArray*)loadCategoriesFromDisk;

-(void)clearCachedData;

@end
