//
//  WSRequest.m
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-08.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WARequest.h"
#import "GCDAsyncSocket.h"
#import "WACookie.h"
#import "WAMultipartReader.h"
#import "WAUploadedFile.h"
#import "WAMultipartPart.h"
#import "WAUploadedFile.h"
#import "WAPrivate.h"

static const uint64_t WARequestMaxStaticBodyLength = 1000000;


@interface WARequest () <GCDAsyncSocketDelegate, WAMultipartReaderDelegate>
@property(readwrite, copy) NSString *HTTPVersion;
@property(readwrite, copy) NSString *method;
@property(readwrite, copy) NSString *path;
@property(readwrite, copy) NSString *clientAddress;
@property(readwrite, nonatomic, copy) NSDictionary *headerFields;
@property(readwrite, copy) NSString *query;
@property(readwrite, copy) NSDictionary *queryParameters;
@property(readwrite, copy) NSDictionary *bodyParameters;
@property(readwrite, copy) NSDictionary *uploadedFilesMapping;
@property(readwrite, copy) NSDictionary *cookies;
@property(readwrite, copy) NSArray *byteRanges;
@property(readwrite, copy) NSData *body;

@property(strong) WAMultipartReader *multipartReader;

@property(copy) void(^completionHandler)(BOOL validity);
@end



@implementation WARequest


+ (NSDictionary*)dictionaryFromQueryParameters:(NSString*)query encoding:(NSStringEncoding)enc {
	if(!query) return [NSDictionary dictionary];
	
	NSScanner *s = [NSScanner scannerWithString:query];
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	while(1) {
		NSString *name, *value;
		if(![s scanUpToString:@"=" intoString:&name]) break;
		if(![s scanString:@"=" intoString:NULL]) break;
		if(![s scanUpToString:@"&" intoString:&value])
			value = @"";
		
		name = [name stringByReplacingOccurrencesOfString:@"+" withString:@" "];
		name = [name stringByReplacingPercentEscapesUsingEncoding:enc];
		value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
		value = [value stringByReplacingPercentEscapesUsingEncoding:enc];
		
		if(!name || !value) {
			NSLog(@"Warning: WARequest failed to decode query parameter string.");
			continue;
		}
		
		[params setObject:value forKey:name];
		if(![s scanString:@"&" intoString:NULL]) break;
	}
	return params;
}


+ (NSArray*)byteRangesFromHeaderFieldValue:(NSString*)value {
	if(![value hasPrefix:@"bytes="]) return nil;
	NSString *string = [value substringFromIndex:6];
	NSArray *rangeStrings = [string componentsSeparatedByString:@","];
	NSMutableArray *ranges = [NSMutableArray array];
	for(NSString *spec in rangeStrings) {
		WAByteRange range = WAByteRangeFromRangeSpec(spec);
		if(WAByteRangeIsInvalid(range)) return nil;
		NSValue *value = [NSValue valueWithBytes:&range objCType:@encode(WAByteRange)];
		[ranges addObject:value];
	}
	return ranges;
}


- (void)setHeaderFields:(NSDictionary*)fields {
	NSMutableDictionary *newFields = [NSMutableDictionary dictionary];
	for(NSString *name in fields)
		[newFields setObject:[fields objectForKey:name] forKey:[name lowercaseString]];
	_headerFields = newFields;
	
}


- (id)initWithHTTPMessage:(id /*CFHTTPMessageRef*/)httpMessage {
	if(!(self = [super init])) return nil;
	
	CFHTTPMessageRef message = (__bridge CFHTTPMessageRef)httpMessage;
	
	self.method = (__bridge_transfer NSString*)CFHTTPMessageCopyRequestMethod(message);
	self.HTTPVersion = (__bridge_transfer NSString*)CFHTTPMessageCopyVersion(message);
	NSURL *requestURL = (__bridge_transfer NSURL*)CFHTTPMessageCopyRequestURL(message);
	self.path = [requestURL realPath];
	if(!self.path) return nil;
	
	self.queryParameters = [[self class] dictionaryFromQueryParameters:[requestURL query] encoding:NSUTF8StringEncoding];
	self.query = [requestURL query];
	
	[self setHeaderFields:(__bridge_transfer NSDictionary*)CFHTTPMessageCopyAllHeaderFields(message)];
	NSString *cookieString = [self valueForHeaderField:@"Cookie"];
	if(cookieString) {
		NSSet *cookieSet = [WACookie cookiesFromHeaderValue:cookieString];
		NSMutableDictionary *cookieDict = [NSMutableDictionary dictionary];
		for(WACookie *cookie in cookieSet)
			[cookieDict setObject:cookie forKey:cookie.name];
		self.cookies = [cookieDict copy];
	}
	
	NSString *rangeString = [self valueForHeaderField:@"Range"];
	if(rangeString) self.byteRanges = [[self class] byteRangesFromHeaderFieldValue:rangeString];
	
	return self;
}


- (id)initWithHeaderData:(NSData*)data {
	id message = (__bridge_transfer id)CFHTTPMessageCreateEmpty(NULL, true);
	CFHTTPMessageAppendBytes((__bridge CFHTTPMessageRef)message, [data bytes], [data length]);
	if(!CFHTTPMessageIsHeaderComplete((__bridge CFHTTPMessageRef)message))
		return nil;
	return [self initWithHTTPMessage:message];
}


- (NSString*)description {
	return [NSString stringWithFormat:@"<%@ %p: %@ %@>", [self class], self, self.method, self.path];
}


- (NSString*)valueForQueryParameter:(NSString*)name {
	return [self.queryParameters objectForKey:name];
}


- (NSString*)valueForHeaderField:(NSString*)fieldName {
	return [self.headerFields objectForKey:[fieldName lowercaseString]];
}


- (NSString*)valueForHeaderField:(NSString*)fieldName parameters:(NSDictionary**)outParams {
	NSString *value = [self valueForHeaderField:fieldName];
	if(!value) return nil;
	return WAExtractHeaderValueParameters(value, outParams);
}


- (NSString*)valueForBodyParameter:(NSString*)name {
	return [self.bodyParameters objectForKey:name];
}


- (WACookie*)cookieForName:(NSString*)name {
	return [self.cookies objectForKey:name];
}


- (NSString*)host {
	NSString *host = [self valueForHeaderField:@"Host"];
	if(host) return host;
	return @"localhost";
}


- (NSURL*)URL {
	NSString *scheme = NO ? @"https" : @"http";
	return [[NSURL alloc] initWithScheme:scheme host:self.host path:self.path];
}


- (NSURL*)referrer {
	NSString *URLString = [self valueForHeaderField:@"Referer"];
	if(!URLString) return nil;
	return [NSURL URLWithString:URLString relativeToURL:self.URL];
}


- (NSSet*)origins {
	NSArray *components = [[self valueForHeaderField:@"Origin"] componentsSeparatedByString:@" "];
	if(!components) return nil;
	return [NSSet setWithArray:components];
}


- (void)readBodyFromSocket:(GCDAsyncSocket*)socket completionHandler:(void(^)(BOOL validity))handler {
	self.clientAddress = socket.connectedHost;
	uint64_t contentLength = [[self valueForHeaderField:@"Content-Length"] longLongValue];
	BOOL hasBody = contentLength || [self valueForHeaderField:@"Transfer-Encoding"];
	
	if(!hasBody) {
		handler(YES);
		return;
	}
	
	NSDictionary *params = nil;
	NSString *contentType = [self valueForHeaderField:@"Content-Type" parameters:&params];
	
	if([contentType isEqual:@"multipart/form-data"]) {
		NSString *boundary = [params objectForKey:@"boundary"];
		if(!boundary) {
			handler(NO);
			return;
		}
		self.multipartReader = [[WAMultipartReader alloc] initWithSocket:socket boundary:boundary delegate:self];
	
	}else if([contentType isEqual:@"application/x-www-form-urlencoded"]) {
	
		if(contentLength > WARequestMaxStaticBodyLength) {
			handler(NO);
			return;
		}
		[socket setDelegate:self];
		if(contentLength == 0) {
			handler(YES);
			return;
		}
		[socket readDataToLength:contentLength withTimeout:-1 tag:0];
	
	}else{
		if(contentLength > WARequestMaxStaticBodyLength) {
			handler(NO);
			return;
		}
		[socket setDelegate:self];
		if(contentLength == 0) {
			self.body = [NSData data];
			handler(YES);
			return;
		}
		
		[socket readDataToLength:contentLength withTimeout:-1 tag:0];
		
	}
	self.completionHandler = [handler copy];
}


- (void)invalidate {
	for(WAUploadedFile *file in self.uploadedFiles)
		[file invalidate];
}


- (void)multipartReader:(WAMultipartReader *)reader finishedWithParts:(NSArray *)parts {
	NSMutableDictionary *files = [NSMutableDictionary dictionary];
	NSMutableDictionary *POSTValues = [NSMutableDictionary dictionary];
	
	for(WAMultipartPart *part in parts) {
		NSDictionary *params = nil;
		WAExtractHeaderValueParameters([part.headerFields objectForKey:@"Content-Disposition"]?:@"", &params);
		BOOL isFile = ([params objectForKey:@"filename"] != nil);
		NSString *paramName = [params objectForKey:@"name"];
		if(!paramName) continue;
		
		if(isFile) {
			WAUploadedFile *file = [[WAUploadedFile alloc] initWithPart:part];
			if(!file.parameterName) continue;
			[files setObject:file forKey:file.parameterName];
		}else if(part.data){
			NSString *string = [[NSString alloc] initWithData:part.data encoding:NSUTF8StringEncoding];
			if(!string) continue;
			[POSTValues setObject:string forKey:paramName];
		}
	}
	
	self.uploadedFilesMapping = files;
	self.bodyParameters = POSTValues;
	self.completionHandler(YES);
}


- (void)multipartReaderFailed:(WAMultipartReader *)reader {
	self.completionHandler(NO);
}


- (NSString*)mediaType {
	return [self valueForHeaderField:@"Content-Type" parameters:NULL];
}


- (void)handleBodyData:(NSData*)data {
	NSString *type = self.mediaType;
	if([type isCaseInsensitiveLike:@"application/x-www-form-urlencoded"]) {
		NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		self.bodyParameters = [[[self class] dictionaryFromQueryParameters:string encoding:NSUTF8StringEncoding] copy];
	}else{
		self.body = data;
	}
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {
	[self handleBodyData:data];
	self.completionHandler(YES);
	self.completionHandler = nil;
}


- (NSDate*)conditionalModificationDate {
	NSString *field = [self valueForHeaderField:@"If-Modified-Since"];
	if(!field) return nil;
	return [WAHTTPDateFormatter() dateFromString:field];
}


- (BOOL)wantsPersistentConnection {
	if([self.HTTPVersion isEqual:(id)kCFHTTPVersion1_0])
		return [[self valueForHeaderField:@"Connection"] isCaseInsensitiveLike:@"Keep-Alive"];
	else
		return ![[self valueForHeaderField:@"Connection"] isCaseInsensitiveLike:@"close"];
}



#pragma mark Acceped Media Types


- (NSArray*)acceptedMediaTypes {
	NSString *string = [self valueForHeaderField:@"Accept"];
	if(!string) return $array(@"*/*");
	
	NSMutableArray *types = [NSMutableArray array];
	NSScanner *scanner = [NSScanner scannerWithString:string];
	
	NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@";,"];
	NSMutableCharacterSet *nameSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
	[nameSet addCharactersInString:@"/*-+"];
	
	while(![scanner isAtEnd]) {
		NSString *value = nil;
		if(![scanner scanCharactersFromSet:nameSet intoString:&value]) break;
		[types addObject:value];
		NSString *separator = nil;
		if(![scanner scanCharactersFromSet:separatorSet intoString:&separator]) break;
		if([separator isEqual:@";"]) {
			[scanner scanUpToString:@"," intoString:NULL];
			[scanner scanString:@"," intoString:NULL];
		}		
	}
	
	return types;	
}


+ (BOOL)mediaType:(NSString*)type matchesType:(NSString*)pattern {
	if([pattern isEqual:@"*/*"] || [type isCaseInsensitiveLike:pattern]) return YES;
	
	NSArray *typeComponents = [type componentsSeparatedByString:@"/"];
	NSArray *patternComponents = [pattern componentsSeparatedByString:@"/"];
	if([typeComponents count] != 2 || [patternComponents count] != 2) return NO;
	return [[patternComponents objectAtIndex:1] isEqual:@"*"] && [[typeComponents objectAtIndex:0] isCaseInsensitiveLike:[patternComponents objectAtIndex:0]];
}


- (BOOL)acceptsMediaType:(NSString*)type {
	for(NSString *acceptedType in self.acceptedMediaTypes)
		if([[self class] mediaType:type matchesType:acceptedType]) return YES;
	return NO;
}


- (NSSet*)uploadedFiles {
	return [NSSet setWithArray:[self.uploadedFilesMapping allValues]];
}


- (WAUploadedFile*)uploadedFileForName:(NSString*)name {
	return [self.uploadedFilesMapping objectForKey:name];
}

#pragma mark Authentication


+ (NSString*)digestResponseFromCredentialHash:(NSString*)HA1 method:(NSString*)method authorizationData:(NSDictionary*)data {
	NSString *uri = [data objectForKey:@"uri"];
	NSString *nonce = [data objectForKey:@"nonce"];
	NSString *nonceCount = [data objectForKey:@"nc"];
	NSString *clientNonce = [data objectForKey:@"cnonce"];
	NSString *qop = [data objectForKey:@"qop"];
	
	NSString *clearHA2 = [NSString stringWithFormat:@"%@:%@", method, uri];
	NSString *HA2 = [clearHA2 hexMD5DigestUsingEncoding:NSUTF8StringEncoding];
	
	NSString *clearResponse = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@", HA1, nonce, nonceCount, clientNonce, qop, HA2];
	NSString *response = [clearResponse hexMD5DigestUsingEncoding:NSUTF8StringEncoding];
	return response;
}


+ (NSString*)credentialHashForUsername:(NSString*)user password:(NSString*)password realm:(NSString*)realm {
	return [[NSString stringWithFormat:@"%@:%@:%@", user, realm, password] hexMD5DigestUsingEncoding:NSUTF8StringEncoding];
}


- (NSDictionary *)authorizationValues {
	NSString *auth = [self valueForHeaderField:@"Authorization"];
	
	NSMutableDictionary *values = [NSMutableDictionary dictionary];
	NSString *key = nil;
	NSString *value = nil;
	NSScanner *scanner = [NSScanner scannerWithString:auth];
	
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
	
	while(![scanner isAtEnd]) {
		[scanner scanUpToString:@" " intoString:nil];
		[scanner scanString:@" " intoString:NULL];
		[scanner scanUpToString:@"=" intoString:&key];
		
		[scanner scanString:@"=" intoString:nil];
		[scanner scanUpToString:@"," intoString:&value];
		
		value = [value stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
		[values setObject:value forKey:key];
	}
	
	return values;
}


- (BOOL)getAuthenticationUser:(NSString**)outUser password:(NSString**)outPassword {
	if(self.authenticationScheme != WABasicAuthenticationScheme) return NO;
	NSArray *words = [[self valueForHeaderField:@"Authorization"] componentsSeparatedByString:@" "];
	if([words count] < 2) return NO;
	NSString *encodedCredentials = [words objectAtIndex:1];
	
	NSArray *parts = [[encodedCredentials stringByDecodingBase64UsingEncoding:NSUTF8StringEncoding] componentsSeparatedByString:@":"];
	if([parts count] != 2) return NO;
	if(outUser) *outUser = [parts objectAtIndex:0];
	if(outPassword) *outPassword = [parts objectAtIndex:1];
	return YES;
}


- (BOOL)hasValidAuthenticationForCredentialHash:(NSString*)hash {
	if(self.authenticationScheme != WADigestAuthenticationScheme) return NO;
	NSDictionary *data = [self authorizationValues];
	NSString *correctResponse = [[self class] digestResponseFromCredentialHash:hash method:self.method authorizationData:data];
	return [[data objectForKey:@"response"] isEqual:correctResponse];
}


- (NSString*)digestAuthenticationRealm {
	return [[self authorizationValues] objectForKey:@"realm"];
}


- (BOOL)hasValidAuthenticationForUsername:(NSString*)name password:(NSString*)password {
	switch(self.authenticationScheme) {
		case WABasicAuthenticationScheme: {
			NSString *authUser, *authPassword;
			if(![self getAuthenticationUser:&authUser password:&authPassword]) return NO;
			return [authUser isEqual:name] && [authPassword isEqual:password];
		}
		case WADigestAuthenticationScheme: {
			NSString *hash = [[self class] credentialHashForUsername:name password:password realm:[self digestAuthenticationRealm]];
			return [self hasValidAuthenticationForCredentialHash:hash];
		}
			
		default: return NO;
	}
}


- (WAAuthenticationScheme)authenticationScheme {
	NSString *auth = [self valueForHeaderField:@"Authorization"];
	if(!auth) return WANoneAuthenticationScheme;
	
	if([auth hasPrefix:@"Basic"]) return WABasicAuthenticationScheme;
	if([auth hasPrefix:@"Digest"]) return WADigestAuthenticationScheme;
	return WANoneAuthenticationScheme;
}



#pragma mark Byte Ranges


+ (WAByteRange)rangeFromValue:(NSValue*)value {
	WAByteRange range;
	[value getValue:&range];
	return range;
}


+ (NSValue*)valueFromRange:(WAByteRange)range {
	return [NSValue valueWithBytes:&range objCType:@encode(WAByteRange)];
}


+ (NSValue*)valueByCombiningRange:(NSValue*)value1 range:(NSValue*)value2 {
	WAByteRange combo = WAByteRangeCombine([self rangeFromValue:value1], [self rangeFromValue:value2]);
	if(WAByteRangeIsInvalid(combo)) return nil;
	return [self valueFromRange:combo];
}


+ (NSArray*)sortedRanges:(NSArray*)ranges {
	return [ranges sortedArrayUsingComparator:^NSInteger(id obj1, id obj2){
		WAByteRange range1 = [self rangeFromValue:obj1];
		WAByteRange range2 = [self rangeFromValue:obj2];
		if(range1.firstByte < range2.firstByte)
			return NSOrderedAscending;
		else if(range1.firstByte > range2.firstByte)
			return NSOrderedDescending;
		else
			return NSOrderedSame;
	}];
}


+ (NSArray*)canonicalRanges:(NSArray*)ranges {
	ranges = [self sortedRanges:ranges];
	NSMutableArray *selection = [NSMutableArray arrayWithObject:[ranges objectAtIndex:0]];
	for(NSValue *range in ranges) {
		NSValue *combo = [self valueByCombiningRange:range range:[selection lastObject]];
		if(combo) [selection replaceObjectAtIndex:[selection count]-1 withObject:combo];
		else [selection addObject:range];
	}
	return selection;
}


+ (NSArray*)absoluteArrayOfRanges:(NSArray*)array availableLength:(uint64_t)length {
	NSMutableArray *ranges = [array mutableCopy];
	for(int i=0; i<[ranges count]; i++) {
		WAByteRange range;
		[[ranges objectAtIndex:i] getValue:&range];
		range = WAByteRangeMakeAbsolute(range, length);
		if(WAByteRangeIsInvalid(range)) {
			[ranges removeObjectAtIndex:i];
			i--;
		}else{
			[ranges replaceObjectAtIndex:i withObject:[NSValue valueWithBytes:&range objCType:@encode(WAByteRange)]];
		}
	}
	return ranges;
}


- (NSArray*)canonicalByteRangesForDataLength:(uint64_t)length {
	NSArray *ranges = self.byteRanges;
	if(!ranges) return nil;
	
	ranges = [[self class] absoluteArrayOfRanges:ranges availableLength:length];
	if(![ranges count]) return nil;
	
	ranges = [[self class] canonicalRanges:ranges];
	return ranges;
}


- (void)enumerateCanonicalByteRangesForDataLength:(uint64_t)length usingBlock:(void(^)(WAByteRange range, BOOL *stop))block {
	BOOL stop = NO;
	for(NSValue *value in [self canonicalByteRangesForDataLength:length]) {
		block([[self class] rangeFromValue:value], &stop);
		if(stop) break;
	}
}


@end