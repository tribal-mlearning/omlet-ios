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

#import "DatabaseHandler.h"
#import "SettingsTable.h"

@implementation SettingsTable

@synthesize key;
@synthesize value;
@synthesize userId;
@synthesize objectId;

-(void)loadValueByKey:(NSString *)_key andUserId:(NSString *)_userId
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *sql =[NSString stringWithFormat:@"SELECT userId, key, value, objectId FROM settings WHERE key ='%@' AND userId='%@';", _key, _userId];

    sqlite3_stmt *result = [[DatabaseHandler shared] runSQL:sql];
    if(sqlite3_step(result)  == SQLITE_ROW) {
        const char *textColumn;
        
        textColumn = (const char*) sqlite3_column_text(result, 0);
        self.userId = [NSString stringWithCString:textColumn encoding:NSUTF8StringEncoding];

        textColumn = (const char*) sqlite3_column_text(result, 1);
        self.key = [NSString stringWithCString:textColumn encoding:NSUTF8StringEncoding];

        textColumn = (const char*) sqlite3_column_text(result, 2);
        self.value = [NSString stringWithCString:textColumn encoding:NSUTF8StringEncoding];
        
        textColumn = (const char*) sqlite3_column_text(result, 3);
        if (textColumn) self.objectId = [NSString stringWithCString:textColumn encoding:NSUTF8StringEncoding];
        else self.objectId = nil;
    }
    [pool release];
}

-(void)loadValueByKey:(NSString *)_key andUserId:(NSString *)_userId andObjectId:(NSString *)_objectId
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *sql =[NSString stringWithFormat:@"SELECT userId, key, value, objectId FROM settings WHERE key ='%@' AND userId='%@' and objectId='%@';", _key, _userId, _objectId];
    
    sqlite3_stmt *result = [[DatabaseHandler shared] runSQL:sql];
    if(sqlite3_step(result)  == SQLITE_ROW) {
        const char *textColumn;
        
        textColumn = (const char*) sqlite3_column_text(result, 0);
        self.userId = [NSString stringWithCString:textColumn encoding:NSUTF8StringEncoding];
        
        textColumn = (const char*) sqlite3_column_text(result, 1);
        self.key = [NSString stringWithCString:textColumn encoding:NSUTF8StringEncoding];
        
        textColumn = (const char*) sqlite3_column_text(result, 2);
        self.value = [NSString stringWithCString:textColumn encoding:NSUTF8StringEncoding];
        
        textColumn = (const char*) sqlite3_column_text(result, 3);
        self.objectId = [NSString stringWithCString:textColumn encoding:NSUTF8StringEncoding];
    }
    [pool release];
}

-(void)setValue:(NSString *)_value forKey:(NSString *)_key andUserId:(NSString *)_userId
{
    self.value = _value;
    self.key = _key;
    self.userId = _userId;
                    
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM settings WHERE userId='%@' AND key='%@'", userId, key];
    [[DatabaseHandler shared] runSQL:sql];
                    
    sql = [NSMutableString stringWithFormat:@"INSERT INTO settings(userId, key, value) VALUES('%@', '%@', '%@')", userId, key, value];    
    [[DatabaseHandler shared] runSQL:sql];

}

-(void)setValue:(NSString *)_value forKey:(NSString *)_key andUserId:(NSString *)_userId andObjectId:(NSString *)_objectId
{
    self.value = _value;
    self.key = _key;
    self.userId = _userId;
    self.objectId = _objectId;
    
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM settings WHERE userId='%@' AND key='%@' and objectId='%@'", userId, key, objectId];
    [[DatabaseHandler shared] runSQL:sql];
    
    sql = [NSMutableString stringWithFormat:@"INSERT INTO settings(userId, key, value, objectId) VALUES('%@', '%@', '%@', '%@')", userId, key, value, objectId];    
    [[DatabaseHandler shared] runSQL:sql];
    
}

- (void)deleteRowsWithPackageId:(NSString *)_packageId {
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM settings WHERE objectId like '%@.%%'", _packageId];
    [[DatabaseHandler shared] runSQL:sql];
}

- (void)deleteAllSettings {
    [[DatabaseHandler shared] runSQL:@"DELETE FROM settings"];
}

-(NSString *)description
{
    NSMutableString *outPut = [NSMutableString stringWithString:@""];
    [outPut appendFormat:@"[userId: %@]", userId];
    [outPut appendFormat:@" [key: %@]", key];
    [outPut appendFormat:@" [value: %@]", value];
    [outPut appendFormat:@" [objectId: %@]", objectId];

    return outPut;
}

- (void)dealloc {
    [value release];
    [key release];
    [userId release];
    [objectId release];
    [super dealloc];
}
@end
