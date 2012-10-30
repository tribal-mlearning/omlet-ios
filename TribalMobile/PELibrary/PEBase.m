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

#import "PEBase.h"

@implementation PEBase
@synthesize icon,
            elementId,
            title;

- (id)init
{
    if (self = [super init]) {
        parent = nil;
        enabled = [[NSNumber numberWithBool:YES] retain];
        icon = @"default-icon.png";
        title = @"";
        elementId = @"";
        children = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [parent release];
    [enabled release];
    [elementId release];
    [children release];
    [icon release];
    [title release];
    [super dealloc];
}

-(BOOL)isEnabled {
    return [enabled boolValue];
}

-(NSArray *)getChildren {
    return children;
}

-(void)addChild:(PEBase *)_child {
    [children addObject:_child];
}

-(void)buildByAPElement:(APElement *)element andParent:(PEBase *)_parent
{
    parent = [_parent retain];
    if ([element valueForAttributeNamed:@"id"] != NULL)
        elementId   = [[NSString alloc] initWithString: [element valueForAttributeNamed:@"id"]];
    
    if ([element valueForAttributeNamed:@"icon"] != NULL)
        icon      = [[NSString alloc] initWithString: [element valueForAttributeNamed:@"icon"]];
    
    if ([element valueForAttributeNamed:@"title"] != NULL)
        title     = [[NSString alloc] initWithString: [element valueForAttributeNamed:@"title"]];
    
    if ([element valueForAttributeNamed:@"enabled"] != NULL) {
        [enabled release];
        enabled = [[NSNumber numberWithBool:[[element valueForAttributeNamed:@"enabled"] isEqualToString:@"true"]] retain];
    }
}

-(int)childCount {
    return [children count];
}

-(PEBase *)getChildByKey:(NSString *)key {
    if ([self childCount] == 0) {
        return nil;
    }
    
    for (PEBase *element in children) {
        if ([element.elementId isEqualToString:key]) {
            return element;
        }
    }
    
    return nil;
}

-(NSString *)description {
    NSMutableString *outPut = [NSMutableString stringWithString:@""];
    [outPut appendFormat:@" [elementId: %@]", elementId];
    [outPut appendFormat:@" [icon: %@]", icon];
    [outPut appendFormat:@" [title: %@]", title];
    [outPut appendFormat:@" [enable: %d]", [enabled boolValue]];
    return outPut;
}

-(NSString *)getFullId
{
    if (parent) {
        return [NSString stringWithFormat:@"%@.%@", [parent getFullId], elementId];
    } else {
        return [NSString stringWithString:elementId];
    }
}

@end
