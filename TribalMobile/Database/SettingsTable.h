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

/** @file SettingsTable.h */

#import <Foundation/Foundation.h>

/** SettingsTable.
 * The SettingsTable class stores key / value pairs associated with a user in the database 
 */

@interface SettingsTable : NSObject
{
    NSString *userId; //< current user ID
    NSString *key; //< key name  
    NSString *value; //< value setting
    NSString *objectId; //< current object ID
}

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) NSString *objectId;

/** loadValueByKey:andUserId:.
 *  Load the value stored for the key name and user ID
 *  @param[in] key
 *  @param[in] userId
 */
- (void)loadValueByKey:(NSString *)key andUserId:(NSString *)userId;

/** loadValueByKey:andUserId:andObjectId.
 *  Load the value stored for the key name and user ID and object ID
 *  @param[in] key
 *  @param[in] userId
 *  @param[in] _objectId
 */
- (void)loadValueByKey:(NSString *)key andUserId:(NSString *)userId andObjectId:(NSString *)_objectId;

/** setValue:forKey:andUserId:.
*  Store the given value for the key name and user ID
*  @param[in] value
*  @param[in] key
*  @param[in] userId
*/
- (void)setValue:(NSString *)value forKey:(NSString *)key andUserId:(NSString *)userId;

/** setValue:forKey:andUserId:andObjectId:.
 *  Store the given value for the key name and user ID and object ID
 *  @param[in] value
 *  @param[in] key
 *  @param[in] userId
 *  @param[in] _objectId
 */
- (void)setValue:(NSString *)value forKey:(NSString *)key andUserId:(NSString *)userId andObjectId:(NSString *)_objectId;

/** deleteRowsWithPackageId:.
 *  Delete all setting associated with the package ID
 *  @param[in] _packageId
 */
- (void)deleteRowsWithPackageId:(NSString *)_packageId;

/** deleteAllSettings.
 *  Remove all settings from the the settings table
 */
- (void)deleteAllSettings;
@end