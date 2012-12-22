//
//  WSResponse.m
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-09.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WAResponse.h"
#import "WARequest.h"
#import "WACookie.h"
#import "GCDAsyncSocket.h"


@interface WAResponse ()
@property(strong) WARequest *request;
@property(strong) GCDAsyncSocket *socket;
@property(copy) void(^completionHandler)(BOOL keepAlive);

@property(strong) NSMutableData *body;
@property BOOL hasSentHeader;

@property(strong, readwrite) NSDictionary *headerFields;
@property(strong, readwrite) NSDictionary *cookies;
@end


@implementation WAResponse {
	NSMutableDictionary *_headerFields;
	NSMutableDictionary *_cookies;
}


- (id)initWithRequest:(WARequest*)request socket:(GCDAsyncSocket*)socket {
	if(!(self = [super init])) return nil;
	
	self.request = request;
	self.socket = socket;
	
	self.hasBody = YES;
	self.body = [NSMutableData data];
	self.bodyEncoding = NSUTF8StringEncoding;
	self.headerFields = [NSMutableDictionary dictionary];
	self.statusCode = 200;
	self.mediaType = @"text/html";
	self.cookies = [NSMutableDictionary dictionary];
	
	return self;
}


- (BOOL)isHTTP11 {
	return [self.request.HTTPVersion isEqual:(id)kCFHTTPVersion1_1];
}


- (CFHTTPMessageRef)createHeader {
	CFHTTPMessageRef message = CFHTTPMessageCreateResponse(NULL, self.statusCode, NULL, (__bridge CFStringRef)self.request.HTTPVersion);
	NSDictionary *fields = [self preparedHeaderFields];
	for(NSString *key in fields)
		CFHTTPMessageSetHeaderFieldValue(message, (__bridge CFStringRef)key, (__bridge CFStringRef)[fields objectForKey:key]);
	
	return message;
}


- (void)requireProgressiveHeaderNotSent {
	if(self.progressive && self.hasSentHeader)
		[NSException raise:@"WAResponseHeaderAlreadySentException" format:@"You can't modify or re-send the header after it has been sent."];
}


- (void)sendHeader {
	[self requireProgressiveHeaderNotSent];
	CFHTTPMessageRef message = [self createHeader];
	NSData *headerData = (__bridge_transfer NSData*)CFHTTPMessageCopySerializedMessage(message);
	CFRelease(message);
	[self.socket writeData:headerData withTimeout:-1 tag:0];
	self.hasSentHeader = YES;
}


- (void)sendHeaderIfNeeded {
	if(self.progressive && !self.hasSentHeader) [self sendHeader];
}


- (void)sendFullResponse {
	[self sendHeader];
	if([self needsBody])
		[self.socket writeData:self.body withTimeout:-1 tag:0];
}


- (void)finish {
	if(!self.completionHandler) return;
	
	if(self.progressive)
		[self sendTerminationChunk];
	else
		[self sendFullResponse];
	
	self.completionHandler(self.request.wantsPersistentConnection);
	self.completionHandler = nil;
}


- (void)sendBodyChunk:(NSData*)data {
	if([data length] == 0) return;
	[self.socket writeData:[[NSString stringWithFormat:@"%qX\r\n", (uint64_t)[data length]] dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
	[self.socket writeData:data withTimeout:-1 tag:0];
	[self.socket writeData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:1];
}


- (void)sendTerminationChunk {
	[self.socket writeData:[[NSString stringWithFormat:@"0\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
}


- (void)setProgressive:(BOOL)p {
	_progressive = p && [self isHTTP11];
}


- (BOOL)needsBody {
	return ![self.request.method isEqual:@"HEAD"];
}


- (void)appendBodyData:(NSData*)data {
	[self sendHeaderIfNeeded];
	if(self.progressive)
		[self sendBodyChunk:data];
	else
		[self.body appendData:data];
}


- (void)appendString:(NSString*)string {
	[self appendBodyData:[string dataUsingEncoding:self.bodyEncoding]];
}


- (void)appendFormat:(NSString*)format, ... {
	va_list list;
	va_start(list, format);
	NSString *string = [[NSString alloc] initWithFormat:format arguments:list];
	va_end(list);
	[self appendString:string];
}



- (NSString*)defaultUserAgent {
	static NSString *cachedValue;
	if(cachedValue) return cachedValue;
	
	NSDictionary *frameworkInfo = [[NSBundle bundleForClass:[self class]] infoDictionary];
	NSString *versionString = frameworkInfo[@"CFBundleShortVersionString"];
	NSString *frameworkName = frameworkInfo[@"CFBundleName"];
	
	cachedValue = frameworkName;
	if([versionString length]) cachedValue = [cachedValue stringByAppendingFormat:@"/%@", versionString];
		
	return cachedValue;
}


- (NSString*)charsetName {
	return (__bridge NSString*)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.bodyEncoding));
}


- (NSString*)contentType {
	return self.mediaType ? [NSString stringWithFormat:@"%@; charset=%@", self.mediaType, self.charsetName] : nil;
}


- (BOOL)needsKeepAliveHeader {
	return [self.request.HTTPVersion isEqual:(id)kCFHTTPVersion1_0] && self.request.wantsPersistentConnection; 
}


- (NSDictionary*)defaultHeaderFields {
	NSMutableDictionary *fields = [@{@"Server": [self defaultUserAgent],
									@"Date": [WAHTTPDateFormatter() stringFromDate:[NSDate date]]
	} mutableCopy];
	
	if(self.progressive)
		fields[@"Transfer-Encoding"] = @"chunked";
	
	else if(self.hasBody)
		fields[@"Content-Length"] = [NSString stringWithFormat:@"%qu", (uint64_t)self.body.length];
	
	if([self needsKeepAliveHeader])
		fields[@"Connection"] = @"Keep-Alive";
	
	if([self contentType] && self.hasBody)
		fields[@"Content-Type"] = self.contentType;
	
	return fields;
}


- (NSDictionary*)preparedHeaderFields {
	NSMutableDictionary *fields = [NSMutableDictionary dictionary];
	
	NSString *cookieString = [[self.cookies.allValues valueForKey:@"headerFieldValue"] componentsJoinedByString:@", "];
	
	if([cookieString length])
		fields[@"Set-Cookie"] = cookieString;
	
	if(self.modificationDate)
		fields[@"Last-Modified"] = [WAHTTPDateFormatter() stringFromDate:self.modificationDate];
	
	NSDictionary *defaults = [self defaultHeaderFields];
	for(NSString *key in defaults)
		if(!fields[key])
			fields[key] = defaults[key];
	
	for(id key in [fields copy])
		if([fields[key] length] == 0)
			[fields removeObjectForKey:key];
	
	if(self.allowedOrigins)
		fields[@"Access-Control-Allow-Origin"] = [self.allowedOrigins.allObjects componentsJoinedByString:@" "];
	
	[fields addEntriesFromDictionary:self.headerFields];
	return fields;
}


- (void)redirectToURL:(NSURL*)URL withStatusCode:(NSUInteger)code {
	URL = [NSURL URLWithString:[URL relativeString] relativeToURL:self.request.URL];
	self.statusCode = code;
	[self setValue:[URL absoluteString] forHeaderField:@"Location"];
}


- (void)redirectToURL:(NSURL*)URL {
	[self redirectToURL:URL withStatusCode:302];	
}


- (void)redirectToURLFormat:(NSString*)format, ... {
	va_list list;
	va_start(list, format);
	NSString *string = [[NSString alloc] initWithFormat:format arguments:list];
	va_end(list);
	NSURL *URL = [NSURL URLWithString:string];
	if(!URL)
		[NSException raise:NSInvalidArgumentException format:@"String was not a valid URL: %@", string];
	[self redirectToURL:URL];	
}


- (NSString*)valueForHeaderField:(NSString*)fieldName {
	return [self.headerFields objectForKey:fieldName];
}


- (void)setValue:(NSString*)value forHeaderField:(NSString*)fieldName {
	[self requireProgressiveHeaderNotSent];
	if(value)
		_headerFields[fieldName] = value;
	else
		[_headerFields removeObjectForKey:fieldName];
}


- (void)addCookie:(WACookie*)cookie {
	[self requireProgressiveHeaderNotSent];
	_cookies[cookie.name] = cookie;
}


- (void)removeCookieNamed:(NSString*)name {
	[self requireProgressiveHeaderNotSent];
	[_cookies removeObjectForKey:name];
}


- (void)setEntityTag:(NSString*)ETag {
	[self setValue:ETag forHeaderField:@"ETag"];
}


- (NSString*)entityTag {
	return [self valueForHeaderField:@"ETag"];
}


- (void)finishWithErrorString:(NSString*)error {
	[self.body setLength:0];
	[self appendString:error];
	[self finish];
}


- (void)requestAuthenticationForRealm:(NSString*)realm scheme:(WAAuthenticationScheme)scheme {
	self.statusCode = 401;
	NSString *response = nil;
	
	if(scheme == WABasicAuthenticationScheme) {
		response = [NSString stringWithFormat:@"Basic realm=\"%@\"", realm];		
		
	}else if(scheme == WADigestAuthenticationScheme) {
		NSString *nonce = WAGenerateUUIDString();
		NSString *opaque = [realm hexMD5DigestUsingEncoding:NSUTF8StringEncoding];
		response = [NSString stringWithFormat:@"Digest realm=\"%@\", qop=\"auth\", nonce=\"%@\", opaque=\"%@\"", realm, nonce, opaque];
	}
	
	[self setValue:response forHeaderField:@"WWW-Authenticate"];
}

@end