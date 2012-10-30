//
//  ZipHelper.h
//  TribalMobile
//
//  Created by Sean Brotherton on 03/05/2012.
//  Copyright (c) 2012 Tribal Group. All rights reserved.
//

/** @file ZipHelper.h */

#import <Foundation/Foundation.h>

/** ZipComplete. 
 *  param[in] success
 */
typedef void (^ZipComplete)(BOOL success);

/** ZipHelper.
 * Helper class for zip archives
 */
@interface ZipHelper : NSObject

/** unZipFile.
 *  @param[in] filePath
 *  @param[in] destination
 *  @param[in] onComplete
 */
+ (void)unZipFile:(NSString *)filePath destination:(NSString *)destination onComplete:(ZipComplete) onComplete;
@end
