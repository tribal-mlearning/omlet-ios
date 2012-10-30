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

/** @file Server.h */

#import <Foundation/Foundation.h>

/** OnServerDelta.
 *  ServerDelta callback
 *  @param[in] serverDelta
 */
typedef void (^OnServerDelta)(NSInteger serverDelta);

/** OnAuthenticationCompleted.
 *  Server authentication callback
 *  @param[in] authenticated
 */
typedef void (^OnAuthenticationCompleted)(bool authenticated, id data);


/** Server.
 *  The Server protocol contains all the methods for communicating
 *  with the web-services
 */
@protocol Server <NSObject>

@required

/** getServerDelta.
 *  serverDelta time check 
 *  @param[in] onServerDelta
 */
- (void)getServerDelta:(OnServerDelta)onServerDelta;

/** login: password: onAuthenticationCompleted.
 *  User login authenticating with web-service
 *  @param[in] username
 *  @param[in] password
 *  @param[in] onAuthenticationCompleted callBack
 */
- (void)login:(NSString *)username password:(NSString *)password onAuthenticationCompleted:(OnAuthenticationCompleted)onAuthenticationCompleted;


/** getPackages.
 *  Retrieve all packages assigned to user from the Tribal server
 *  @param[in] onAuthenticationCompleted callBack
 */
- (void)getPackages:(OnAuthenticationCompleted)onAuthenticationCompleted;

/** getPackages.
 *  Retrieve all news assined to user from the Tribal server
 *  @param[in] onAuthenticationCompleted callBack
 */
-(void)getNews:(OnAuthenticationCompleted)onAuthenticationCompleted;


/** getCategories
  * Retrieve categories from the trival server
 * @param[in] onAuthenticationCompleted callBack
 */
-(void)getCategories:(OnAuthenticationCompleted)onAuthenticationCompleted;
@end
