//
//  WSResponse.h
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-09.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WARequest.h"
@class WARequest, WACookie, AsyncSocket;


@interface WAResponse : NSObject {
	WARequest *request;
	AsyncSocket *socket;
	void(^completionHandler)(BOOL keepAlive);
	
	NSMutableData *body;
	NSStringEncoding bodyEncoding;
	BOOL progressive;
	BOOL hasSentHeader;
	
	NSMutableDictionary *headerFields;
	NSUInteger statusCode;
	NSString *mediaType;
	NSMutableDictionary *cookies;
	NSDate *modificationDate;
}


@property NSUInteger statusCode;
@property NSStringEncoding bodyEncoding;
@property(getter=isProgressive) BOOL progressive; // Use chunked transfer encoding?

@property(copy) NSString *mediaType;
@property(copy) NSDate *modificationDate;
@property(copy) NSString *entityTag;


- (void)appendBodyData:(NSData*)data;
- (void)appendString:(NSString*)string;
- (void)appendFormat:(NSString*)format, ...;
- (void)finish;

- (NSString*)valueForHeaderField:(NSString*)fieldName;
- (void)setValue:(NSString*)value forHeaderField:(NSString*)fieldName;

- (void)redirectToURL:(NSURL*)URL;
- (void)redirectToURL:(NSURL*)URL withStatusCode:(NSUInteger)code;

- (void)addCookie:(WACookie*)cookie;
- (void)requestAuthenticationForRealm:(NSString*)realm scheme:(WAAuthenticationScheme)scheme;

@end