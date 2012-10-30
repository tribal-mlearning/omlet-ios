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

#import "TrackingTable.h"
#import "DatabaseHandler.h"

@implementation TrackingTable

+ (void)track:(NSString *)userId objectId:(NSString *)objectId sender:(NSString *)sender addInfo:(NSString *)addInfo
{
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO tracking(userId, objectId, sender, addInfo) VALUES('%@', '%@', '%@', '%@')", userId, objectId, sender, addInfo];    
    [[DatabaseHandler shared] runSQL:sql];     
}

+ (NSMutableDictionary *)popTrack:(NSString *)userId
{
    NSString *sql = [NSString stringWithFormat:@"SELECT _id, objectId, sender, strftime('%%s', deviceTimestamp), addInfo FROM tracking WHERE userId = '%@' ORDER BY deviceTimestamp ASC LIMIT 1", userId];    

    NSMutableDictionary *result = nil;
    
    sqlite3_stmt *sqlres = [[DatabaseHandler shared] runSQL:sql];
    if (sqlite3_step(sqlres) == SQLITE_ROW) {
        
        NSString *_id = [[[NSString alloc] initWithUTF8String:
                          (const char *) sqlite3_column_text(sqlres, 0)] autorelease];
        NSString *objectId = [[[NSString alloc] initWithUTF8String:
                               (const char *) sqlite3_column_text(sqlres, 1)] autorelease];
        NSString *sender = [[[NSString alloc] initWithUTF8String:
                             (const char *) sqlite3_column_text(sqlres, 2)] autorelease];
        NSNumber *deviceTimestamp = [NSNumber numberWithInt:sqlite3_column_int(sqlres, 3)];
        NSString *addInfo = [[[NSString alloc] initWithUTF8String:
                              (const char *) sqlite3_column_text(sqlres, 4)] autorelease];
        
        result = [[NSMutableDictionary new] autorelease];

        [result setValue:_id forKey:@"_id"];
        [result setValue:objectId forKey:@"objectId"];
        [result setValue:sender forKey:@"sender"];
        [result setValue:deviceTimestamp forKey:@"deviceTimestamp"];
        [result setValue:addInfo forKey:@"addInfo"];
        
        NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM tracking WHERE _id='%@'", _id];
        [[DatabaseHandler shared] runSQL:sql];
    }
    
    return result;
}

+ (NSMutableArray *)getAllTracks:(NSString *)userId
{
    NSString *sql = [NSString stringWithFormat:@"SELECT _id, objectId, sender, addInfo FROM tracking WHERE userId = '%@'", userId];    
    
    NSMutableArray *result = [[NSMutableArray new] autorelease];
    sqlite3_stmt *sqlres = [[DatabaseHandler shared] runSQL:sql];
    while (sqlite3_step(sqlres) == SQLITE_ROW) {
        NSMutableDictionary *track = [[NSMutableDictionary new] autorelease];
        
        NSString *_id = [[[NSString alloc] initWithUTF8String:
                          (const char *) sqlite3_column_text(sqlres, 0)] autorelease];
        NSString *objectId = [[[NSString alloc] initWithUTF8String:
                          (const char *) sqlite3_column_text(sqlres, 1)] autorelease];
        NSString *sender = [[[NSString alloc] initWithUTF8String:
                          (const char *) sqlite3_column_text(sqlres, 2)] autorelease];
        NSString *addInfo = [[[NSString alloc] initWithUTF8String:
                          (const char *) sqlite3_column_text(sqlres, 3)] autorelease];

        [track setValue:_id forKey:@"_id"];
        [track setValue:objectId forKey:@"objectId"];
        [track setValue:sender forKey:@"sender"];
        [track setValue:addInfo forKey:@"addInfo"];
        
        [result addObject:track];
    }
    
    return result;
}

+ (void)remove:(NSString *)trackId
{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM tracking WHERE _id='%@'", trackId];
    NSLog(@"Removing Track: %@",sql);
    [[DatabaseHandler shared] runSQL:sql];
}

+ (NSMutableDictionary *)fetchTrack:(NSString *)userId
{
    NSString *sql = [NSString stringWithFormat:@"SELECT _id, objectId, sender, strftime('%%s', deviceTimestamp), addInfo FROM tracking WHERE userId = '%@' ORDER BY deviceTimestamp ASC LIMIT 1", userId];    
    
    NSMutableDictionary *result = nil;
    
    sqlite3_stmt *sqlres = [[DatabaseHandler shared] runSQL:sql];
    if (sqlite3_step(sqlres) == SQLITE_ROW) {
        
        NSString *_id = [[[NSString alloc] initWithUTF8String:
                          (const char *) sqlite3_column_text(sqlres, 0)] autorelease];
        NSString *objectId = [[[NSString alloc] initWithUTF8String:
                               (const char *) sqlite3_column_text(sqlres, 1)] autorelease];
        NSString *sender = [[[NSString alloc] initWithUTF8String:
                             (const char *) sqlite3_column_text(sqlres, 2)] autorelease];
        NSNumber *deviceTimestamp = [NSNumber numberWithInt:sqlite3_column_int(sqlres, 3)];
        NSString *addInfo = [[[NSString alloc] initWithUTF8String:
                              (const char *) sqlite3_column_text(sqlres, 4)] autorelease];
        
        result = [[NSMutableDictionary new] autorelease];
        
        [result setValue:_id forKey:@"_id"];
        [result setValue:objectId forKey:@"objectId"];
        [result setValue:sender forKey:@"sender"];
        [result setValue:deviceTimestamp forKey:@"deviceTimestamp"];
        [result setValue:addInfo forKey:@"addInfo"];
    }
    
    return result;
}

@end
