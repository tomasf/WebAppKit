//
//  WSRequest.h
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-08.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WAHTTPSupport.h"
@class GCDAsyncSocket, WACookie, WAUploadedFile, WAMultipartReader;

@interface WARequest : NSObject
@property(readonly, copy) NSString *HTTPVersion;
@property(readonly, copy) NSString *method;
@property(readonly, copy) NSString *path;
@property(readonly, copy) NSData *body;

@property(readonly, copy) NSString *query;
@property(readonly, nonatomic, copy) NSDictionary *headerFields;
@property(readonly, copy) NSDictionary *queryParameters;
@property(readonly, copy) NSDictionary *bodyParameters;
@property(readonly, nonatomic) NSSet *uploadedFiles;
@property(readonly, nonatomic) NSString *host;
@property(readonly, nonatomic) NSURL *URL;
@property(readonly, nonatomic) NSURL *referrer;
@property(readonly, nonatomic) NSSet *origins; // Origin header
@property(readonly, nonatomic) NSString *mediaType;

@property(readonly, copy) NSDictionary *cookies;
@property(readonly, nonatomic) NSDate *conditionalModificationDate;
@property(readonly, nonatomic) NSArray *acceptedMediaTypes;
@property(readonly, nonatomic) WAAuthenticationScheme authenticationScheme;

@property(readonly, copy) NSArray *byteRanges; // NSValue-wrapped WAByteRanges

@property(readonly, copy) NSString *clientAddress;
@property(readonly, nonatomic) BOOL wantsPersistentConnection;


- (NSString*)valueForQueryParameter:(NSString*)name;
- (NSString*)valueForHeaderField:(NSString*)fieldName;
- (NSString*)valueForBodyParameter:(NSString*)name;
- (WACookie*)cookieForName:(NSString*)name;
- (WAUploadedFile*)uploadedFileForName:(NSString*)name;

- (BOOL)acceptsMediaType:(NSString*)type;

- (BOOL)getAuthenticationUser:(NSString**)outUser password:(NSString**)outPassword;
- (BOOL)hasValidAuthenticationForUsername:(NSString*)name password:(NSString*)password;
- (BOOL)hasValidAuthenticationForCredentialHash:(NSString*)hash;
+ (NSString*)credentialHashForUsername:(NSString*)user password:(NSString*)password realm:(NSString*)realm;

// Sorted array of absolute combined ranges
- (NSArray*)canonicalByteRangesForDataLength:(uint64_t)length;
- (void)enumerateCanonicalByteRangesForDataLength:(uint64_t)length usingBlock:(void(^)(WAByteRange range, BOOL *stop))block;
@end