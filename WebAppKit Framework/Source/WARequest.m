//
//  WSRequest.m
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-08.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WARequest.h"
#import "AsyncSocket.h"
#import "WACookie.h"

@interface WARequest () <AsyncSocketDelegate>
@end


@implementation WARequest
@synthesize method, path, headerFields, queryParameters, cookies, HTTPVersion, clientAddress;


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
			NSLog(@"Warning: FTRequest failed to decode query parameter string. Try setting inputEncoding to match the query parameter contents.");
			continue;
		}
		
		[params setObject:value forKey:name];
		if(![s scanString:@"&" intoString:NULL]) break;
	}
	return params;
}




- (id)initWithHTTPMessage:(CFHTTPMessageRef)message {
	self = [super init];
	method = NSMakeCollectable(CFHTTPMessageCopyRequestMethod(message));
	
	HTTPVersion = NSMakeCollectable(CFHTTPMessageCopyVersion(message));
	NSURL *requestURL = NSMakeCollectable(CFHTTPMessageCopyRequestURL(message));
	path = [[requestURL path] copy];
	queryParameters = [[[self class] dictionaryFromQueryParameters:[requestURL query] encoding:NSUTF8StringEncoding] copy];
	
	headerFields = NSMakeCollectable(CFHTTPMessageCopyAllHeaderFields(message));
	NSString *cookieString = [headerFields objectForKey:@"Cookie"];
	if(cookieString) {
		NSSet *cookieSet = [WACookie cookiesFromHeaderValue:cookieString];
		NSMutableDictionary *cookieDict = [NSMutableDictionary dictionary];
		for(WACookie *cookie in cookieSet)
			[cookieDict setObject:cookie forKey:cookie.name];
		cookies = [cookieDict copy];
	}
	
	return self;
}

- (id)initWithHeaderData:(NSData*)data {
	CFHTTPMessageRef message = (CFHTTPMessageRef)CFMakeCollectable(CFHTTPMessageCreateEmpty(NULL, true));
	CFHTTPMessageAppendBytes(message, [data bytes], [data length]);
	if(!CFHTTPMessageIsHeaderComplete(message))
		return nil;
	return [self initWithHTTPMessage:message];
}


- (NSString*)description {
	return [NSString stringWithFormat:@"<%@ %p: %@ %@>", [self class], self, method, path];
}


- (NSString*)valueForQueryParameter:(NSString*)name {
	return [queryParameters objectForKey:name];
}


- (NSString*)valueForHeaderField:(NSString*)fieldName {
	return [headerFields objectForKey:fieldName];
}


- (NSString*)valueForPOSTParameter:(NSString*)name {
	return [POSTParameters objectForKey:name];
}


- (WACookie*)cookieForName:(NSString*)name {
	return [cookies objectForKey:name];
}


- (NSString*)host {
	NSString *host = [self valueForHeaderField:@"Host"];
	if(host) return host;
	return @"localhost";
}



- (NSURL*)URL {
	NSString *scheme = NO ? @"https" : @"http";
	return [[[NSURL alloc] initWithScheme:scheme host:self.host path:self.path] autorelease];
}


- (void)readBodyFromSocket:(AsyncSocket*)socket completionHandler:(void(^)(BOOL validity))handler {
	clientAddress = [[socket connectedHost] copy];
	BOOL hasBody = [self valueForHeaderField:@"Content-Length"] || [self valueForHeaderField:@"Transfer-Encoding"];
	
	if(!hasBody) {
		handler(YES);
		return;
	}
	
	uint64_t contentLength = [[self valueForHeaderField:@"Content-Length"] longLongValue];
	
	[socket setDelegate:self];
	[socket readDataToLength:contentLength withTimeout:-1 tag:0];
	
	completionHandler = [handler copy];
}


- (void)handleBodyData:(NSData*)data {
	NSString *type = [self valueForHeaderField:@"Content-Type"];
	if([type hasPrefix:@"application/x-www-form-urlencoded"]) { // jesus. fix
		NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		POSTParameters = [[[self class] dictionaryFromQueryParameters:string encoding:NSUTF8StringEncoding] copy];
	}
}


- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {
	[self handleBodyData:data];
	completionHandler(YES);
	completionHandler = nil;
}


- (NSDate*)conditionalModificationDate {
	NSString *field = [self valueForHeaderField:@"If-Modified-Since"];
	if(!field) return nil;
	return [WAHTTPDateFormatter() dateFromString:field];
}


- (BOOL)wantsPersistentConnection {
	return [self.HTTPVersion isEqual:(id)kCFHTTPVersion1_1] && ![[self valueForHeaderField:@"Connection"] isEqual:@"close"];
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
			
			
		default:
			return NO;
	}
}



- (WAAuthenticationScheme)authenticationScheme {
	NSString *auth = [self valueForHeaderField:@"Authorization"];
	if(!auth) return WANoneAuthenticationScheme;
	
	if([auth hasPrefix:@"Basic"]) return WABasicAuthenticationScheme;
	if([auth hasPrefix:@"Digest"]) return WADigestAuthenticationScheme;
	return WANoneAuthenticationScheme;
}



@end