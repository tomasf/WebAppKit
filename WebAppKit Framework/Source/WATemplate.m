//
//  WSTemplate.m
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-16.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WATemplate.h"
#import <FScript/FScript.h>
#import "WAModule.h"
#import "WALocalization.h"



@interface NSScanner (WSExtras)
- (NSString*)scanBalancedExpressionUpToCharacter:(unichar)target;
- (NSString*)scanRest;
@end


@implementation NSString (WSTemplateExtras)

+ (NSString*)templateStringForObject:(id)obj {
	return [NSString stringWithFormat:@"%@", obj];
}

@end


@implementation NSObject (WSTemplateExtras)

- (void)iterateWithFSBlock:(FSBlock *)block {
	if([block argumentCount] != 1)
		[NSException raise:NSInvalidArgumentException format:@"Iteration blocks must take exactly one argument."];
	
	if(![self conformsToProtocol:@protocol(NSFastEnumeration)])
		NSLog(@"Warning: %@ does not conform to NSFastEnumeration.");
	
	for(id obj in (id<NSFastEnumeration>)self)
		[block value:obj];
}

@end





@implementation NSScanner (WSExtras)


- (NSString*)scanBalancedExpressionUpToCharacter:(unichar)target {
	NSInteger level = 0;
	NSString *string = [self string];
	NSUInteger startPos = [self scanLocation];
	BOOL inString = NO;
	
	for(int i=startPos; i<[string length]; i++) {
		unichar c = [string characterAtIndex:i];
		if(c == '\'') {
			inString = !inString;
			
		}else if(inString && c == '\\') {
			i++; // skip next char
		}else if(!inString && c == target && level == 0) {
			[self setScanLocation:i];
			return [string substringWithRange:NSMakeRange(startPos, i-startPos)];
		} else if(!inString && c == '(')
			level++;
		else if(!inString && c == ')')
			level--;
		if(level < 0)
			return nil;
	}
	return nil;
}

- (NSString*)scanRest {
	NSString *rest = [[self string] substringFromIndex:[self scanLocation]];
	[self setScanLocation:[[self string] length]];
	return rest;
}

@end




@implementation WATemplate
@synthesize localization;


static WALocalization *defaultLocalization;

+ (void)setDefaultLocalization:(WALocalization*)loc {
	defaultLocalization = loc;
}

+ (WALocalization*)defaultLocalization {
	return defaultLocalization;
}


+ (id)templateNamed:(NSString*)name {
	NSURL *URL = [[NSBundle mainBundle] URLForResource:name withExtension:@"wat"];
	if(!URL) return nil;
	return [[self alloc] initWithContentsOfURL:URL];
}

- (id)initWithContentsOfURL:(NSURL*)URL {
	return [self initWithSource:[NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:NULL]];
}

- (id)initWithSource:(NSString*)templateString {
	if(!templateString) return nil;
	self = [super init];
	source = [templateString copy];
	values = [NSMutableDictionary dictionary];
	modules = [NSMutableSet set];
	return self;
}

- (void)setValue:(id)value forKey:(NSString*)key {
	if(value)
		[values setObject:value forKey:key];
	else
		[values removeObjectForKey:key];
}

- (id)valueForKey:(NSString*)key {
	return [values objectForKey:key];
}

- (void)appendString:(NSString*)string toValueForKey:(NSString*)key {
	NSString *value = [self valueForKey:key];
	if(!value) value = @"";
	if(![value isKindOfClass:[NSString class]])
		[NSException raise:NSInvalidArgumentException format:@"Can't append to key '%@' because previous value isn't a string.", key];
	
	[self setValue:[value stringByAppendingString:string] forKey:key];
}



+ (NSString*)loopCodeForBody:(NSString*)body {
	NSString *variable = nil, *collection = nil;
	NSScanner *scanner = [NSScanner scannerWithString:body];
	if(![scanner scanUpToString:@" " intoString:&variable]) return nil;
	if(![scanner scanString:@"in" intoString:NULL]) return nil;
	collection = [scanner scanRest];
	if(![collection length]) return nil;
	return [NSString stringWithFormat:@"(%@) iterateWithFSBlock:[:%@|\n", collection, variable];
}

+ (NSString*)stringLiteralExpressionForString:(NSString*)string {
	return [NSString stringWithFormat:@"'%@'", [string stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]];
}

+ (NSString*)codeForTemplate:(NSString*)template {
	NSMutableString *output = [NSMutableString string];
	NSScanner *scanner = [NSScanner scannerWithString:template];
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	for(;;) {
		NSString *text = nil;
		BOOL didScan = [scanner scanUpToString:@"<%" intoString:&text];
		if(didScan)
			[output appendFormat:@"__output appendString:%@.\n", [self stringLiteralExpressionForString:text]];
		
		if([scanner isAtEnd]) break;
		[scanner scanString:@"<%" intoString:NULL];
		NSString *keyword = nil;
		[scanner scanCharactersFromSet:[NSCharacterSet lowercaseLetterCharacterSet] intoString:&keyword];
		
		NSString *body = [scanner scanBalancedExpressionUpToCharacter:'>'];
		[scanner scanString:@">" intoString:NULL];
		NSString *trimmedBody = [body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if([keyword isEqual:@"print"]) {
			[output appendFormat:@"__output appendString:(NSString templateStringForObject:(%@)).\n", body];
		}else if([keyword isEqual:@"placeholder"]) {
			
			[output appendFormat:@"(__values at:'%@')==nil ifFalse:[__output appendString:(NSString templateStringForObject:(__values at:'%@')).].\n", trimmedBody, trimmedBody];
		}else if([keyword isEqual:@"if"]) {
			[output appendFormat:@"(%@) ifTrue:[", body];
		}else if([keyword isEqual:@"for"]) {
			[output appendString:[self loopCodeForBody:body]];
		}else if([keyword isEqual:@"do"]) {
			[output appendString:body];
		}else if([keyword isEqual:@"end"]) {
			[output appendFormat:@"]."];
			
		}else if([body hasPrefix:@":"]) {
			[output appendFormat:@"__output appendString:(__localization stringForKeyPath:'%@').\n", [body substringFromIndex:1]];
			
		}else if([keyword isEqual:@"template"]) {
			WATemplate *innerTemplate = [WATemplate templateNamed:trimmedBody];
			[output appendFormat:@"__output appendString:%@.\n", [self stringLiteralExpressionForString:innerTemplate.result]];
		}
		
	}
	return [output length] ? output : @"1";	
}


- (NSString*)evaluatedString {
	NSString *code = [[self class] codeForTemplate:source];
	NSMutableString *output = [NSMutableString string];
	
	FSInterpreter *interpreter = [[FSInterpreter alloc] init];
	for(NSString *key in values)
		[interpreter setObject:[values objectForKey:key] forIdentifier:key];
	[interpreter setObject:output forIdentifier:@"__output"];
	[interpreter setObject:values forIdentifier:@"__values"];
	[interpreter setObject:localization ?: defaultLocalization forIdentifier:@"__localization"];
	
	FSInterpreterResult *result = [interpreter execute:code];
	if(![result isOK]) NSLog(@"%@", [result errorMessage]);
	
	return [result isOK] ? output : nil;
}



- (NSString*)result {
	NSMutableSet *loadedModules = [NSMutableSet set];
	for(WAModule *module in modules)
		if(![loadedModules containsObject:module])
			[module invokeWithTemplate:self loadedModules:loadedModules];
	
	return [self evaluatedString];
}

- (void)addModule:(WAModule*)module {
	[modules addObject:module];
}


@end
