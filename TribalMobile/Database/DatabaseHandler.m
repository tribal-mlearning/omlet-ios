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

@implementation DatabaseHandler

static DatabaseHandler *_shared = nil;

+ (DatabaseHandler *)shared
{
	@synchronized([DatabaseHandler class]) {
		if (!_shared) {
			_shared = [[self alloc] init];
		}
	}
	return _shared;
}

- (id)init
{
    if (self = [super init]) {
		[self open];
    }
    return self;
}

- (sqlite3_stmt *)runSQL:(NSString*)isql
{
	// alloc
	sqlite3_stmt *stmt;
	char *errmsg;
	const char *sql = [isql cStringUsingEncoding:NSUTF8StringEncoding];
	
	// prepare
	if (sqlite3_prepare_v2(database, sql, -1, &stmt, NULL) != SQLITE_OK) {
		NSLog(@"SQL Warning: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
		return nil;
	}
	
	// execute
	if(sqlite3_exec(database, sql, nil, &stmt, &errmsg) == SQLITE_OK){
		return stmt;
	}else {
		NSLog(@"SQL Warning: '%s'.", sqlite3_errmsg(database));
		return nil;
	}
}

- (NSString *)path:(NSString *)filename
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0], *filepath;
	if (filename != nil) {
		filepath = [documentsDirectory stringByAppendingPathComponent:filename];
	}else{
		filepath = documentsDirectory;
	}
	return filepath;
}

- (void)runScript:(NSString *)path
{
	NSError *err;
	NSString *script_path = [self resourcesFilePath:path] ;
	NSString *script = [[NSString alloc] initWithContentsOfFile:script_path encoding:NSUTF8StringEncoding error:&err];
	if(script != nil) [self runSQL:script];
	else NSLog(@"erro: %@", [err description]);
	[script release];
}

-(NSString *)resourcesFilePath:(NSString *)filename
{
	return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
}

- (BOOL)open
{
	const char *path = [[self path:@"db.sql"] cStringUsingEncoding:NSUTF8StringEncoding];
	return (sqlite3_open(path, &database) == SQLITE_OK) ? YES	: NO ;
}

- (void)dealloc
{
    [super dealloc];
}

@end
