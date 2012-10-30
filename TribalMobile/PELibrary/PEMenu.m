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

#import "PEMenu.h"

@implementation PEMenu
@synthesize layout, header, desc;


- (id)init
{
    self = [super init];
    if (self) {
        layout = @"list";
    }
    return self;
}

-(void)buildByAPElement:(APElement *)element andParent:(PEBase *)_parent
{
    if ([element valueForAttributeNamed:@"layout"] != nil)
        layout = [[NSString alloc] initWithString: [element valueForAttributeNamed:@"layout"]];
    
    if ([element valueForAttributeNamed:@"header-background"] != nil) {
        header = [[NSString alloc] initWithString: [element valueForAttributeNamed:@"header-background"]];
    } else {
        if (_parent && [_parent isKindOfClass:[PEMenu class]] && ![((PEMenu *)_parent).header isEqualToString:@""]) {
            header = ((PEMenu *)_parent).header;
        }
    }
    
    if ([element valueForAttributeNamed:@"description"] != nil) {
        self.desc = [element valueForAttributeNamed:@"description"];
    }
    [super buildByAPElement:element andParent:_parent];
}

-(NSString *)description
{
    NSMutableString *outPut = [NSMutableString stringWithString:[super description]];
    [outPut appendFormat:@" [layout: %@]", layout];
    [outPut appendFormat:@" [header: %@]", header];
    return outPut;
}

- (void)dealloc {
    [layout release];
    [header release];
    [desc release];
    [super dealloc];
}
@end
