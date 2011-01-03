//
//  FTJSON.m
//  JSON
//
//  Created by Tomas Franzén on 2009-10-25.
//  Copyright 2009 Lighthead Software. All rights reserved.
//

#import "WAJSON.h"
#import <ParseKit/ParseKit.h>

#pragma mark Generation

@implementation NSString (JSONEncoding)
- (NSString*)JSONValue {
	self = [self stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
	self = [self stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
	self = [self stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
	return [NSString stringWithFormat:@"\"%@\"", self];
}
@end

@implementation NSArray (JSONEncoding)
- (NSString*)JSONValue {
	NSMutableArray *entries = [NSMutableArray array];
	for(id obj in self) {
		id value = [obj JSONValue];
		if(!value) return nil;
		[entries addObject:value];
	}
	return [NSString stringWithFormat:@"[%@]", [entries componentsJoinedByString:@","]];
}
@end

@implementation NSDictionary (JSONEncoding)
- (NSString*)JSONValue {
	NSMutableString *JSON = [NSMutableString stringWithString:@"{"];
	NSMutableArray *entries = [NSMutableArray array];
	for(id key in self) 
		[entries addObject:[NSString stringWithFormat:@"%@:%@", [key JSONValue], [[self objectForKey:key] JSONValue]]];
	
	[JSON appendString:[entries componentsJoinedByString:@","]];
	[JSON appendString:@"}"];
	return JSON;
}
@end

@implementation NSNumber (JSONEncoding)
- (NSString*)JSONValue {
	if(strcmp([self objCType], @encode(BOOL)) == 0)
		return [self boolValue] ? @"true" : @"false";
	return [self description];
}
@end

@implementation NSNull (JSONEncoding)
- (NSString*)JSONValue {
	return @"null";
}
@end



#pragma mark Parsing

#define FTJSONParserErrorDomain @"FTJSONParserErrorDomain"


@interface FTJSONStringState : PKTokenizerState {}
@end

// Private interfaces. PKQuoteState uses this, so it should be okay.
@interface PKToken ()
@property (nonatomic, readwrite) NSUInteger offset;
@end

@interface PKTokenizerState ()
- (void)resetWithReader:(PKReader *)r;
- (void)append:(PKUniChar)c;
- (NSString *)bufferedString;
@end


@implementation FTJSONStringState

- (PKToken *)nextTokenFromReader:(PKReader *)r startingWith:(PKUniChar)cin tokenizer:(PKTokenizer *)t {
    NSParameterAssert(r);
    [self resetWithReader:r];
    
	BOOL isEscaping = NO;
    PKUniChar c;
	
	[self append:cin];
	
    for(;;) {
        c = [r read];
        if(c == PKEOF) break;
		[self append:c];
		
		if(isEscaping)
			isEscaping = NO;
		else{
			if(c == cin) break;
			if(c == '\\') isEscaping = YES;
		}
    }
	
    PKToken *tok = [PKToken tokenWithTokenType:PKTokenTypeQuotedString stringValue:[self bufferedString] floatValue:0.0];
    tok.offset = offset;
    return tok;
}

@end




@interface WAJSONParser ()
@property(retain) NSError *error;
- (id)parseToken:(PKToken*)token;
@end


@implementation WAJSONParser
@synthesize error;


- (id)initWithJSONString:(NSString*)s {
	[super init];
	tokenizer = [[PKTokenizer tokenizerWithString:s] retain];
	
	tokenizer.numberState.allowsTrailingDot = NO;
	tokenizer.numberState.allowsOctalNotation = NO;
	tokenizer.numberState.allowsScientificNotation = YES;
	tokenizer.numberState.allowsHexadecimalNotation = NO;
	
	FTJSONStringState *qs = [[FTJSONStringState alloc] init];
	[tokenizer setTokenizerState:qs from:'"' to:'"'];
	[qs release];
	
	// Disallow:
	[tokenizer setTokenizerState:tokenizer.symbolState from:'\'' to:'\'']; // Single quotes
	[tokenizer setTokenizerState:tokenizer.symbolState from:'/' to:'/']; // Comments
	return self;
}


- (void)dealloc {
	[tokenizer release];
	[error release];
	[super dealloc];
}


- (id)setErrorDescription:(NSString*)format, ... {
	va_list vars;
	va_start(vars,format);
	NSString *description = [[[NSString alloc] initWithFormat:format arguments:vars] autorelease];
	va_end(vars);
	self.error = [NSError errorWithDomain:FTJSONParserErrorDomain code:-1 userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedFailureReasonErrorKey]];
	return nil;
}


- (NSArray*)parseArray {
	NSMutableArray *array = [NSMutableArray array];

	for(;;) {
		PKToken *token = [tokenizer nextToken];
		if([[token stringValue] isEqual:@"]"]) break;
		
		id object = [self parseToken:token];
		if(!object) return nil;
		
		[array addObject:object];
		
		token = [tokenizer nextToken];
		if([[token stringValue] isEqual:@"]"])
			break;
		if(![[token stringValue] isEqual:@","])
			return [self setErrorDescription:@"Parse error: Expected comma or ] at character %d, but found: %@", [token offset], [token stringValue] ?: @"EOF"];
	}
	
	return array;
}


- (NSDictionary*)parseObject {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];

	for(;;) {
		PKToken *token = [tokenizer nextToken];
		if([[token stringValue] isEqual:@"}"]) break;
		
		id key = [self parseToken:token];
		if(!key) return nil;
		
		token = [tokenizer nextToken];
		if(![[token stringValue] isEqual:@":"])
			return [self setErrorDescription:@"Parse error: Expected colon in object at character %d, but found: %@", [token offset], [token stringValue] ?: @"EOF"];
		
		token = [tokenizer nextToken];
		id value = [self parseToken:token];
		if(!value) return nil;
		
		[dict setObject:value forKey:key];
		
		token = [tokenizer nextToken];
		if([[token stringValue] isEqual:@"}"])
			break;
		if(![[token stringValue] isEqual:@","])
			return [self setErrorDescription:@"Parse error: Expected comma or } at character %d, but found: %@", [token offset], [token stringValue] ?: @"EOF"];
	}

	return dict;
}


- (NSString*)parseStringToken:(PKToken*)token {
	NSMutableString *newString = [NSMutableString string];
	NSString *string = [NSString stringWithString:[[token stringValue] substringWithRange:NSMakeRange(1, [[token stringValue] length]-2)]];
	NSScanner *scanner = [NSScanner scannerWithString:string];
	
	while(![scanner isAtEnd]) {
		NSString *chunk = nil;
		[scanner scanUpToString:@"\\" intoString:&chunk];
		if(chunk) [newString appendString:chunk];
		if([scanner isAtEnd]) break;
		
		unichar c = [string characterAtIndex:[scanner scanLocation]+1];
		[scanner setScanLocation:[scanner scanLocation]+2];
		
		NSString *replacement = nil;
		if(c == '"' || c == '\\' || c == '/')
			replacement = [NSString stringWithCharacters:&c length:1];
		else if(c == 'b') replacement = @"\b";
		else if(c == 'f') replacement = @"\f";
		else if(c == 'n') replacement = @"\n";
		else if(c == 'r') replacement = @"\r";
		else if(c == 't') replacement = @"\t";
		
		else if(c == 'u') {
			unsigned int value;
			unichar replacementChar;
			NSString *hexValue = [string substringWithRange:NSMakeRange([scanner scanLocation], 4)];
			NSScanner *hexScanner = [NSScanner scannerWithString:hexValue];
			if(![hexScanner scanHexInt:&value]) 
				return [self setErrorDescription:@"Parse error: Invalid Unicode character '%@'.", hexValue];
			replacementChar = value;
			replacement = [NSString stringWithCharacters:&replacementChar length:1];
			[scanner setScanLocation:[scanner scanLocation]+4];
		
		}else
			return [self setErrorDescription:@"Parse error: Invalid escape character '%C'.", c];
		
		[newString appendString:replacement];
	}
	
	return newString;
}


- (NSNumber*)parseNumberToken:(PKToken*)token {
	return [NSNumber numberWithFloat:[token floatValue]];
}


- (id)parseToken:(PKToken*)token {
	if(token == [PKToken EOFToken])
		return [self setErrorDescription:@"Parse error: Unexpected end of data."];
		
	if([token isQuotedString]) return [self parseStringToken:token];
	if([token isNumber]) return [self parseNumberToken:token];
	
	NSString *string = [token stringValue];
	
	if([string isEqual:@"["]) return [self parseArray];
	if([string isEqual:@"{"]) return [self parseObject];
	
	if([string isEqual:@"null"]) return [NSNull null];
	if([string isEqual:@"true"]) return [NSNumber numberWithBool:YES];
	if([string isEqual:@"false"]) return [NSNumber numberWithBool:NO];

	return [self setErrorDescription:@"Parse error: Undefined symbol '%@' at character %d.", [token stringValue], [token offset]];
}


- (id)parse {
	id object = [self parseToken:[tokenizer nextToken]];
	if(!object) return nil;
	PKToken *suffix = [tokenizer nextToken];
	if(suffix != [PKToken EOFToken])
		return [self setErrorDescription:@"Parse error: Expected EOF at character %d, but found crud: %@", [suffix offset], [suffix stringValue]];
	return object;
}

- (NSError*)error {
	return error;
}

+ (id)objectFromJSON:(NSString*)JSONString error:(NSError**)outError {
	WAJSONParser *parser = [[[WAJSONParser alloc] initWithJSONString:JSONString] autorelease];
	id value = [parser parse];
	if(!value && outError) *outError = [parser error];
	return value;
}

+ (NSString*)JSONFromObject:(id)object {
	return [object JSONValue];
}

@end
