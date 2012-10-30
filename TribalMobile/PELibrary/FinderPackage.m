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

#import "FinderPackage.h"

#define FILENAME @"package.xml"

@implementation FinderPackage
@synthesize pacakgeId;
@synthesize packagePath;

- (id)initWithXML:(NSString *)path {
    //Store package id from the path
    NSArray *strComp = [path pathComponents];
    self.pacakgeId = [strComp objectAtIndex:strComp.count -2];
    
    self.packagePath = [path stringByDeletingLastPathComponent];
    
    if (self = [super init]) {
        packages = [[NSMutableArray alloc] init];
        files = [[NSMutableArray alloc] init];
        [files addObject:path];
        [self load];
    }
    return self;
}

- (id)initWithPath:(NSString *)rootPath 
{
    self.packagePath = [rootPath stringByDeletingLastPathComponent];
    self.pacakgeId = [rootPath lastPathComponent];
    if (self = [super init]) {
        packages = [[NSMutableArray alloc] init];
        
        //NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        //rootPath = [documentsDirectory stringByAppendingPathComponent: rootPath];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSMutableSet *contents = [[[NSMutableSet alloc] init] autorelease];
        
        BOOL isDir;
        files = [[NSMutableArray alloc] init];
        if (rootPath && ([fileManager fileExistsAtPath:rootPath isDirectory:&isDir] && isDir))
        {
            if (![rootPath hasSuffix:@"/"]) 
            {
                rootPath = [rootPath stringByAppendingString:@"/"];
            }
            
            NSDirectoryEnumerator *de = [fileManager enumeratorAtPath:rootPath];
            NSString *f;
            NSString *fqn;
            while ((f = [de nextObject]))
            {                
                fqn = [rootPath stringByAppendingString:f];
                if ([fileManager fileExistsAtPath:fqn isDirectory:&isDir] && isDir)
                {
                    fqn = [fqn stringByAppendingString:@"/"];
                }
                [contents addObject:fqn];
            }
            
            NSString *fn;
            for ( fn in [[contents allObjects] sortedArrayUsingSelector:@selector(compare:)] )
            {
                if ([fn hasSuffix:FILENAME]) {
                    [files addObject:fn];
                }    
            }
        }
        [pool release];
        [self load];
    }
    return self;
}

- (void)dealloc
{
    [files release];
    [packages release];
    [super dealloc];
}

- (PEBase *)getElementByPath:(NSString *)path 
{
    PEBase *outPut = nil;
    
    NSArray *keys = [path componentsSeparatedByString:@"."];
    //If there is no . in path, look through all the packages, 
    //if there is a ., this will be the package id. Is the later needed?
    if(keys.count > 1)
    {
        for (int i = 0; i < [keys count]; i++) {
            if (i == 0) {
                for (PEPackage *packageTemp in packages) {
                    if ([packageTemp.elementId isEqualToString:[keys objectAtIndex:i]]) {
                        outPut = packageTemp;
                        break;
                    }
                }
            } else {
                outPut = [outPut getChildByKey:[keys objectAtIndex:i]];
            }
            if (outPut == nil) break;
        }
    }
    else if(packages.count == 1)
    {
        for(PEPackage *packageTemp in packages)
        {
            outPut = [packageTemp getChildByKey:[keys objectAtIndex:0]];
            if(outPut != nil) break;
        }
    }
    return outPut;
}

-(void)expandLinkFor:(PEBase *)base
{
    NSArray *children = [base getChildren];
    for (PEBase *child in children) {
        if ([child isKindOfClass:[PEMenuLink class]]) {
            [((PEMenuLink *)child) loadLink];
        } else {
            [self expandLinkFor:child];
        }
    }
}

-(void)load
{
    PEBase *package;
    for (NSString *path in files) {
        NSString *xmlContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        APDocument *doc = [APDocument documentWithXMLString:xmlContent];
        APElement *root = [doc rootElement];
        // add basepath to loadElement method
        if (root)  
        {
            package = [self loadElement:root withParent:nil];
            [packages addObject:package];
        }
        //[package release];
    }
    for (PEBase *package in packages) {
        /* expanding links */
        [self expandLinkFor:package];
    }
}


-(PEBase *)loadElement: (APElement *)element withParent:(PEBase *)parent {
    PEBase *obj;
    if ([[element name] isEqualToString:PE_ELEMENT_PACKAGE]) {
        obj = [PEPackage new];
    } else if ([[element name] isEqualToString:PE_ELEMENT_HTML]) {
        obj = [PEHtmlResource new];
    } else if ([[element name] isEqualToString:PE_ELEMENT_CHECKLIST]) {
        obj = [PEChecklistResource new];
    } else if ([[element name] isEqualToString:PE_ELEMENT_VIDEO]) {
        obj = [PEVideoResource new];
    } else if ([[element name] isEqualToString:PE_ELEMENT_BOOK]) {
        obj = [PEBookResource new];
    } else if ([[element name] isEqualToString:PE_ELEMENT_NATIVE_CODE]) {
        obj = [PENativeCodeResource new];
    } else if ([[element name] isEqualToString:PE_ELEMENT_MENU]) {
        NSString *type = [element valueForAttributeNamed:@"type"];
        if ([type isEqualToString:@"link"]) {
            obj = [[PEMenuLink alloc] initWithFinder:self];
        } else {
            obj = [PEMenu new];
        }
    } else {
        obj = [PEBase new];
    }
    
    [obj buildByAPElement:element andParent:parent];
    
    if ([element childCount] > 0) {
        for (APElement *entry in [element childElements]){
            [self loadElement:entry withParent:obj];
        }    
    }
    
    if (parent != nil) {
        [parent addChild:obj];
    }
    
    return [obj autorelease]; 
}

-(NSArray *)getAllResources
{
    return [self getAllResources:nil];
}

-(NSString *)getIdForPackage:(NSUInteger)packageIndex{
    
    PEPackage *package = [packages objectAtIndex:packageIndex];
    return [package elementId];
}

-(PEBase *)getEntryPointForPackage:(NSUInteger)packageIndex{
    
    PEPackage *package = [packages objectAtIndex:packageIndex];
    PEBase *result = nil;
        for (PEBase *child in [package getChildren]) {
            if ([[child elementId] isEqualToString:[package entryPoint]]){
            result = child;
            break;
        }
    }       
    
    return result;
}

-(NSArray *)getAllResources:(NSString *)label
{
    NSMutableArray *result = [[NSMutableArray new] autorelease];
    for (PEPackage *package in packages) {
        for (PEBase *child in [package getChildren]) {
            
            if ([child isKindOfClass:[PEResource class]]) {
                PEResource *res = (PEResource *) child;
                if (label) {
                    NSArray *labels = [res.label componentsSeparatedByString:@" "];
                    for (NSString *l in labels)
                        if ([label isEqualToString:l]) { 
                            [result addObject:res];
                            break;
                        }
                } else [result addObject:res];
            }
        }
    }
    return [[result copy] autorelease];
}

@end
