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

/** @file TrackingTable.h */

#import <Foundation/Foundation.h>

/** TrackingTable.
 * The TrackingTable class is used to store raw user tracking data
 */
@interface TrackingTable : NSObject

/** track:objectId:sender:addInfo:.
 *  Insert a row of tracking data associated with object ID with the sender and any addtional data
 *  @param[in] value
 *  @param[in] key
 *  @param[in] userId
 *  @param[in] _objectId
 */
+ (void)track:(NSString *)userId objectId:(NSString *)objectId sender:(NSString *)sender addInfo:(NSString *)addInfo;

/** remove:.
 *  Remove a row from the tracking table with a specific ID
 *  @param[in] trackId
 */
+ (void)remove:(NSString *)trackId;

/** fetchTrack:.
 *  Fetch all the tracking records associated with a user ID
 *  @param[in] userId
 *  @return NSMutableDictionary
 */
+ (NSMutableDictionary *)fetchTrack:(NSString *)userId;

@end
