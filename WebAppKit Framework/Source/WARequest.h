//
//  WSRequest.h
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-08.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WAHTTPSupport.h"
@class AsyncSocket, WACookie, WAUploadedFile, WAMultipartReader;

@interface WARequest : NSObject {
	NSString *HTTPVersion;
	NSString *method;
	NSString *path;
	NSString *clientAddress;
	NSDictionary *headerFields;
	NSString *query;
	NSDictionary *queryParameters;
	NSDictionary *POSTParameters;
	NSDictionary *uploadedFiles;
	NSDictionary *cookies;
	NSArray *byteRanges;
	
	WAMultipartReader *multipartReader;
	
	void(^completionHandler)(BOOL validity);
}


@property(readonly) NSString *HTTPVersion;
@property(readonly) NSString *method;
@property(readonly) NSString *path;

@property(readonly) NSString *query;
@property(readonly) NSDictionary *headerFields;
@property(readonly) NSDictionary *queryParameters;
@property(readonly) NSDictionary *POSTParameters;
@property(readonly) NSSet *uploadedFiles;
@property(readonly) NSString *host;
@property(readonly) NSURL *URL;

@property(readonly) NSDictionary *cookies;
@property(readonly) NSDate *conditionalModificationDate;
@property(readonly) NSArray *acceptedMediaTypes;
@property(readonly) WAAuthenticationScheme authenticationScheme;

@property(readonly) NSArray *byteRanges; // NSValue-wrapped WAByteRanges

@property(readonly) NSString *clientAddress;

@property(readonly) BOOL wantsPersistentConnection;


- (NSString*)valueForQueryParameter:(NSString*)name;
- (NSString*)valueForHeaderField:(NSString*)fieldName;
- (NSString*)valueForPOSTParameter:(NSString*)name;
- (WACookie*)cookieForName:(NSString*)name;
- (WAUploadedFile*)uploadedFileForName:(NSString*)name;

- (BOOL)acceptsMediaType:(NSString*)type;

- (BOOL)getAuthenticationUser:(NSString**)outUser password:(NSString**)outPassword;
- (BOOL)hasValidAuthenticationForUsername:(NSString*)name password:(NSString*)password;
- (BOOL)hasValidAuthenticationForCredentialHash:(NSString*)hash;
+ (NSString*)credentialHashForUsername:(NSString*)user password:(NSString*)password realm:(NSString*)realm;

// Nice sorted array of absolute combined ranges
- (NSArray*)canonicalByteRangesForDataLength:(uint64_t)length;
- (void)enumerateCanonicalByteRangesForDataLength:(uint64_t)length usingBlock:(void(^)(WAByteRange range, BOOL *stop))block;
@end