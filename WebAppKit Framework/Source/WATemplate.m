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
#import "WAModuleManager.h"


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
@synthesize localization, parent;


static WALocalization *defaultLocalization;

+ (void)setDefaultLocalization:(WALocalization*)loc {
	defaultLocalization = loc;
}

+ (WALocalization*)defaultLocalization {
	return defaultLocalization;
}


+ (id)templateNamed:(NSString*)name {
	NSURL *URL = [[NSBundle mainBundle] URLForResource:name withExtension:@"wat"];
	if(!URL) [NSException raise:NSInvalidArgumentException format:@"Template named '%@' wasn't found.", name];
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
	moduleIdentifiers = [NSMutableSet set];
	return self;
}

- (void)setValue:(id)value forKey:(NSString*)key {
	[values setObject:value ?: [NSNull null] forKey:key];
}

- (void)removeValueForKey:(NSString*)key {
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


- (NSString*)evaluatedStringWithAdditionalModules:(NSSet*)addedModules values:(NSDictionary*)addedValues localization:(WALocalization*)addedLocalization {
	NSSet *effectiveModules = [moduleIdentifiers setByAddingObjectsFromSet:addedModules];
	NSString *headCode = [[WAModuleManager sharedManager] headerStringFromModuleIdentifiers:effectiveModules];
	
	NSString *code = [[self class] codeForTemplate:source];
	NSMutableString *output = [NSMutableString string];
	
	WALocalization *effectiveLocalization = addedLocalization ?: localization;
	
	NSMutableDictionary *effectiveValues = [NSMutableDictionary dictionary];
	[effectiveValues addEntriesFromDictionary:values];
	[effectiveValues addEntriesFromDictionary:addedValues];
	
	FSInterpreter *interpreter = [[FSInterpreter alloc] init];
	[interpreter setObject:headCode forIdentifier:@"HEAD"];
	for(NSString *key in effectiveValues) {
		id obj = [effectiveValues objectForKey:key];
		if(obj == [NSNull null]) obj = nil;
		[interpreter setObject:obj forIdentifier:key];
	}
		
	[interpreter setObject:output forIdentifier:@"__output"];
	[interpreter setObject:values forIdentifier:@"__values"];
	[interpreter setObject:effectiveLocalization ?: defaultLocalization forIdentifier:@"__localization"];
	
	FSInterpreterResult *result = [interpreter execute:code];
	
	if([result isOK]) {
		if(parent) {
			[effectiveValues setObject:output forKey:@"CONTENT"];
			[output setString:[parent evaluatedStringWithAdditionalModules:effectiveModules values:effectiveValues localization:effectiveLocalization]];
		}
		return output;
	}else{
		[NSException raise:NSInternalInconsistencyException format:@"An F-Script error occured while evaluating template: %@", [result errorMessage]];
		return nil;
	}
}



- (NSString*)result {	
	return [self evaluatedStringWithAdditionalModules:[NSSet set] values:[NSDictionary dictionary] localization:nil];
}


#pragma mark Modules

- (void)addModule:(NSString*)identifier {
	[moduleIdentifiers addObject:identifier];
}

- (void)removeModule:(NSString*)identifier {
	[moduleIdentifiers removeObject:identifier];
}



@end