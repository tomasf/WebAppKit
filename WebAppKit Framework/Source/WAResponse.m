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
#import "AsyncSocket.h"


@interface WAResponse ()
- (NSDictionary*)preparedHeaderFields;
- (BOOL)needsBody;
- (void)sendBodyChunk:(NSData*)data;
- (void)sendTerminationChunk;
@end


@implementation WAResponse
@synthesize bodyEncoding, statusCode, mediaType, modificationDate, progressive;


- (id)initWithRequest:(WARequest*)req socket:(AsyncSocket*)sock completionHandler:(void(^)(BOOL keepAlive))handler {
	self = [super init];
	
	request = req;
	socket = sock;
	completionHandler = [handler copy];
	
	body = [NSMutableData data];
	bodyEncoding = NSUTF8StringEncoding;
	headerFields = [NSMutableDictionary dictionary];
	statusCode = 200;
	mediaType = @"text/html";
	cookies = [NSMutableDictionary dictionary];
	return self;
}


- (BOOL)isHTTP11 {
	return [request.HTTPVersion isEqual:(id)kCFHTTPVersion1_1];
}


- (CFHTTPMessageRef)header {
	CFHTTPMessageRef message = CFHTTPMessageCreateResponse(NULL, statusCode, NULL, (CFStringRef)request.HTTPVersion);
	NSDictionary *fields = [self preparedHeaderFields];
	for(NSString *key in fields)
		CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef)key, (CFStringRef)[fields objectForKey:key]);
	NSMakeCollectable(message);
	return message;
}


- (void)requireProgressiveHeaderNotSent {
	if(progressive && hasSentHeader)
		[NSException raise:@"WSResponseHeaderAlreadySentException" format:@"You can't modify the header after it has been sent."];
}


- (void)sendHeader {
	[self requireProgressiveHeaderNotSent];
	NSData *headerData = NSMakeCollectable(CFHTTPMessageCopySerializedMessage([self header]));
	[socket writeData:headerData withTimeout:-1 tag:0];
	hasSentHeader = YES;
}


- (void)sendHeaderIfNeeded {
	if(progressive && !hasSentHeader) [self sendHeader];
}


- (void)sendFullResponse {
	[self sendHeader];
	if([self needsBody])
		[socket writeData:body withTimeout:-1 tag:0];
}


- (void)finish {
	if(!completionHandler) return;
	
	if(progressive)
		[self sendTerminationChunk];
	else
		[self sendFullResponse];
	
	completionHandler(request.wantsPersistentConnection);
	completionHandler = nil;
}


- (void)sendBodyChunk:(NSData*)data {
	if([data length] == 0) return;
	[socket writeData:[[NSString stringWithFormat:@"%qX\r\n", (uint64_t)[data length]] dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
	[socket writeData:data withTimeout:-1 tag:0];
	[socket writeData:[AsyncSocket CRLFData] withTimeout:-1 tag:0];
}

- (void)sendTerminationChunk {
	[socket writeData:[[NSString stringWithFormat:@"0\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
}

- (void)setProgressive:(BOOL)p {
	progressive = p && [self isHTTP11];
}


- (BOOL)needsBody {
	return ![request.method isEqual:@"HEAD"];
}


- (void)appendBodyData:(NSData*)data {
	[self sendHeaderIfNeeded];
	if(progressive)
		[self sendBodyChunk:data];
	else
		[body appendData:data];
}


- (void)appendString:(NSString*)string {
	[self appendBodyData:[string dataUsingEncoding:bodyEncoding]];
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
	NSString *versionString = [frameworkInfo objectForKey:@"CFBundleShortVersionString"];
	NSString *frameworkName = [frameworkInfo objectForKey:@"CFBundleName"];
	
	cachedValue = frameworkName;
	if([versionString length]) cachedValue = [cachedValue stringByAppendingFormat:@"/%@", versionString];
		
	return cachedValue;
}


- (NSString*)charsetName {
	return (NSString*)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(bodyEncoding));
}

- (NSString*)contentType {
	return mediaType ? [NSString stringWithFormat:@"%@; charset=%@", mediaType, [self charsetName]] : nil;
}


- (NSDictionary*)defaultHeaderFields {
	NSMutableDictionary *fields = $mdict(@"Server", [self defaultUserAgent],
										 @"Date", [WAHTTPDateFormatter() stringFromDate:[NSDate date]],
										 @"Content-Type", [self contentType]
	);
	
	if(progressive)
		[fields setObject:@"chunked" forKey:@"Transfer-Encoding"];
	else
		[fields setObject:[NSString stringWithFormat:@"%qu", (uint64_t)[body length]] forKey:@"Content-Length"];
	
	return fields;
}


- (NSDictionary*)preparedHeaderFields {
	NSMutableDictionary *fields = [headerFields mutableCopy];
	
	NSString *cookieString = [[[cookies allValues] valueForKey:@"headerFieldValue"] componentsJoinedByString:@","];
	if([cookieString length])
		[fields setObject:cookieString forKey:@"Set-Cookie"];	
	
	if(modificationDate)
		[fields setObject:[WAHTTPDateFormatter() stringFromDate:modificationDate] forKey:@"Last-Modified"];
	
	NSDictionary *defaults = [self defaultHeaderFields];
	for(NSString *key in defaults)
		if(![fields objectForKey:key])
			[fields setObject:[defaults objectForKey:key] forKey:key];
	
	for(id key in [fields copy])
		if([[fields objectForKey:key] length] == 0)
			[fields removeObjectForKey:key];
	
	return fields;
}


- (void)redirectToURL:(NSURL*)URL withStatusCode:(NSUInteger)code {
	URL = [NSURL URLWithString:[URL relativeString] relativeToURL:request.URL];
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
	return [headerFields objectForKey:fieldName];
}

- (void)setValue:(NSString*)value forHeaderField:(NSString*)fieldName {
	[self requireProgressiveHeaderNotSent];
	if(value)
		[headerFields setObject:value forKey:fieldName];
	else
		[headerFields removeObjectForKey:fieldName];
}


- (void)addCookie:(WACookie*)cookie {
	[self requireProgressiveHeaderNotSent];
	[cookies setObject:cookie forKey:cookie.name];
}

- (void)removeCookieNamed:(NSString*)name {
	[self requireProgressiveHeaderNotSent];
	[cookies removeObjectForKey:name];
}

- (void)setEntityTag:(NSString*)ETag {
	[self setValue:ETag forHeaderField:@"ETag"];
}

- (NSString*)entityTag {
	return [self valueForHeaderField:@"ETag"];
}

- (void)finishWithErrorString:(NSString*)error {
	[body setLength:0];
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