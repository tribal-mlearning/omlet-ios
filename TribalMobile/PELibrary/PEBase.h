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

/** @file PEBase.h */

#import <Foundation/Foundation.h>
#import "APXML.h"

@class FinderPackage;

/** PEBase.
 * The PEBase class is a base class for package contents
 */
@interface PEBase : NSObject {
    NSNumber *enabled;  ///< enabled
    NSMutableArray *children;  ///< children
    PEBase *parent;  ///< parent
}

@property (nonatomic, retain) NSString *icon;  ///< icon
@property (nonatomic, retain) NSString *title;   ///< title
@property (nonatomic, retain) NSString *elementId;  ///< element id

/** isEnabled.
 *  @return BOOL
 */
-(BOOL)isEnabled;

/** getChildren.
 *  @return NSArray
 */
-(NSArray *)getChildren;

/** getChildren.
 *  @param[in] _children
 */
-(void)addChild:(PEBase *)_children;

/** buildByAPElement.
 *  @param[in] element
 *  @param[in] parent
 */
-(void)buildByAPElement:(APElement *)element andParent:(PEBase *)parent;

/** childCount.
 *  @return int
 */
-(int)childCount;

/** getChildByKey.
 *  @param[in] key
 *  @return PEBase
 */
-(PEBase *)getChildByKey:(NSString *)key;

/** getFullId.
 *  @return NSString
 */
-(NSString *)getFullId;

@end