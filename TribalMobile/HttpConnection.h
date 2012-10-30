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

/** @file HttpConnection.h */

#import <Foundation/Foundation.h>

/** HttpConnectionOnStart. */
typedef void (^HttpConnectionOnStart)(void);
/** HttpConnectionOnError. 
 *  param[in] error
 */
typedef void (^HttpConnectionOnError)(NSError *error);
/** HttpConnectionOnSuccess.
 *  param[in] data
 */
typedef void (^HttpConnectionOnSuccess)(NSString *data);

/** HttpConnectionDataType.
 *  How data is transmitted to the server
 */
typedef enum {
    HttpConnectionDataTypeJSON,     ///< data sent through JSON body message
    HttpConnectionDataTypeHeaders,  ///< data sent through header message
} HttpConnectionDataType;


@protocol HttpConnectionDelegate;

/** HttpConnection.
 *  Basic http conection helper class
 */
@interface HttpConnection : NSObject 
{
    @private
    NSString *url;
    NSString *method;
    id userData;
    NSMutableString *receivedData;
    HttpConnectionOnStart onStart;
    HttpConnectionOnSuccess onSuccess;
    HttpConnectionOnError onError;
    NSHTTPURLResponse *HTTPResponse;
}
@property (nonatomic, assign) HttpConnectionDataType connectionDataType;
@property (nonatomic, assign) id<HttpConnectionDelegate> delegate;

/** initWithMethod: url: data
 *  @param[in] rest method GET/POST
 *  @param[in] URL
 *  @param[in] data body content sent to server
 *  @return HttpConnection
 */
- (id)initWithMethod:(NSString *)_method url:(NSString *)_url data:(id)_data 
             onStart:(HttpConnectionOnStart)_onStart 
           onSuccess:(HttpConnectionOnSuccess)_onSuccess
             onError:(HttpConnectionOnError)_onError;


/** start.
 *  Starts the connection the server
 */
- (void)start;

/** data.
 *  retreives the data sent / received
 *  @return object
 */
- (id)data;

/** getUrl:data:.
 *  Creates a HttpConnection setting the method to GET
 *  @param[in] URL
 *  @param[in] data
 *  @param[in] onStart callback
 *  @param[in] onSuccess callback
 *  @param[in] onError callback
 *  @return HttpConnection
 */
+ (id)getUrl:(NSString *)url data:(id)data
       onStart:(HttpConnectionOnStart)onStart 
     onSuccess:(HttpConnectionOnSuccess)onSuccess
       onError:(HttpConnectionOnError)onError;

/** postUrl:data:.
 *  Creates a HttpConnection setting the method to POST
 *  @param[in] URL
 *  @param[in] data
 *  @param[in] onStart callback
 *  @param[in] onSuccess callback
 *  @param[in] onError callback
 *  @return HttpConnection
 */
+ (id)postUrl:(NSString *)url data:(id)data
        onStart:(HttpConnectionOnStart)onStart 
      onSuccess:(HttpConnectionOnSuccess)onSuccess
        onError:(HttpConnectionOnError)onError;

@end


@protocol HttpConnectionDelegate <NSObject>

@optional
- (void)connection:(HttpConnection *)conn completed:(BOOL)sucessful;

@end
