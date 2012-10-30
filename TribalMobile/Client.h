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

/** @file Client.h */

#import <Foundation/Foundation.h>
#import "TrackEngine.h"

typedef enum {
    PackageOpenRequestFailed,
    PackageOpenRequestSuccess,
    PackageOpenRequestNoConnectivity,
    PackageOpenRequestNoPackage,
    PackageOpenRequestResourceMissing,
    
    PackageOpenRequestNotDownloaded
} PackageOpenRequestState;

typedef void (^PackageOpenRequestCompleted)(PackageOpenRequestState state, NSString* callbackId);

/** SyncCallback.
 *  Callback block called when sync has completed
 *  @param[in] success
 */
typedef void (^SyncCallback)(bool success);

/** Client.
 *  The client protocol contains all the methods for communicating
 *  with the main controller
 */
@protocol Client <NSObject>

@property (nonatomic, copy) NSString *currentPackageTitle;  ///< Sets and Gets the current package title

/** getUserId.
 *  Provides the ID of the current user. In case the application doesn't have authentication, a static ID must be defined.
 *  @return string
 */
- (NSString *)getUserId;

/** getUserUsername.
 *  Provides the username of the current user. In case the application doesn't have authentication, a static ID must be defined.
 *  @return string
 */
- (NSString *)getUserUsername;

/** getUserUsername.
 *  Provides the password of the current user. In case the application doesn't have authentication, a static password must be defined.
 *  @return string
 */
- (NSString *)getUserPassword; 

/** getCourseLocalPathRoot:.
 *  Retrieves the local path root for a particular course.
 *  @param[in] packageId
 *  @return string
 */
- (NSString *)getCourseLocalPathRoot:(NSString *)packageId;

/** getCurrentPackageId.
 *  Retrieves the current package ID
 *  @return string
 */
- (NSString *)getCurrentPackageId;

/** setCurrentElement:.
 *  Sets the current element visible to the user
 *  @param[in] _element
 */
- (void)setCurrentElement:(PEBase *)_element;

/** getCurrentElement.
 *  Retrieves the current element on visible to the user
 *  @return PEBase
 */
- (PEBase *)getCurrentElement;

/** getCurrentPackageElementId.
 *  Retrieves the current package element ID
 *  @return string
 */
- (NSString *)getCurrentPackageElementId;

/** getTrackEngine.
 *  Retrieves the tracking engine object
 *  @return TrackEngine
 */
- (TrackEngine *)getTrackEngine;

/** initialize.
 *  Initialize the session timer.
 */
- (void)initialize;

/** terminate.
 *  Terminate the session timer and store the total time.
 */
- (void)terminate;

/** getValueForKey:storeType:.
 *  Retrieves the value with a specific stored key of a store type.
 *  @param[in] key
 *  @param[in] sType
 *  @return string
 */
- (NSString *)getValueForKey:(NSString *)key storeType:(NSString *)sType;

/** setValue:forKey:storeType:.
 *  Stores the value with a specific key of a store type
 *  @param[in] val
 *  @param[in] key
 *  @param[in] sType
 *  @return string
 */
- (void)setValue:(NSString *)val forKey:(NSString *)key storeType:(NSString *)sType;

/** setCurrentPacakge:.
 *  Sets the current package.
 *  @param[in] resourcePath
 *  @return BOOL
 */
- (BOOL)setCurrentPacakge:(NSString*)resourcePath;

/** updateUserId:username:password:.
 *  Updates the current user credentials.
 *  @param[in] _userId
 *  @param[in] _username
 *  @param[in] _password
 */
- (void)updateUserId:(NSString *)_userId username:(NSString *)_username password:(NSString *)_password;

@optional

/** openMenu:.
 *  Provides the ability to open a native menu.
 *  @param[in] menuPath
 */
- (void)openMenu:(NSString *)menuPath;

/** openResource:.
 *  Provides the ability to open a resource.
 *  @param[in] resourcePath
 */
- (void)openResource:(NSString *)resourcePath;

/** addCheckListItemView.
 *  Displays a dialog box entry to add items to a checklist
 */
- (void)addCheckListItemView;

/** dialogCheckListItemView:.
 *  Displays a dialog with the contents of details for a checklist
 *  @param[in] details
 */
- (void)dialogCheckListItemView:(NSDictionary *)details;

/** notify:.
 *  Displays a status message on screen
 *  @param[in] msg
 */
- (void)notify:(NSString *)msg;

/** track:addInfo:.
 *  Tracks a content-specific thing. This method must be called by content developers to track anything they want. Everything tracked 
 *  by this method will be connected to the current object id (resource or menu-item).
 *  @param[in] sender
 *  @param[in] addInfo
 */
- (void)track:(NSString *)sender addInfo:(NSString *)addInfo;

/** sync:.
 *  Forces sync
 *  @param[in] callback
 */
- (void)sync:(SyncCallback)callback;

/** logout.
 *  Provides the ability to clear the user ID, username and user password.
 */
- (void)logout;

/** tryOpenPackageItem:callbackId:path:completed:.
 * Determine if a package can be downloaded from the server or already installed to be opened.
 * param[in] pacakgeId
 * param[in] callbackId
 * param[in] path
 * param[in] completed
 */
- (void) tryOpenPackageItem:(NSString *)packageId callbackId:(NSString*)callbackId path:(NSString*)path completed:(PackageOpenRequestCompleted)completed;

@end
