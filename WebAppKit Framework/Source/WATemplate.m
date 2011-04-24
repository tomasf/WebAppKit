//
//  WATemplate.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WATemplate.h"
#import "TFStringScanner.h"
#import "TL.h"

@interface TLExpression ()
+ (TLExpression*)parseExpression:(TFStringScanner*)scanner endToken:(NSString*)string;
+ (TFStringScanner*)newScannerForString:(NSString*)string;
@end


NSString *const WATemplateOutputKey = @"_WATemplateOutput";



@interface WAPrintStatement : TLStatement {
	TLExpression *content;
}
- (id)initWithContent:(TLExpression*)expr;
@end



@implementation WAPrintStatement

- (id)initWithContent:(TLExpression*)expr {
	self = [super init];
	content = expr;
	return self;
}

- (void)invokeInScope:(TLScope *)scope {
	id object = [content evaluateWithScope:scope];
	NSString *chunk = [object isKindOfClass:[NSString class]] ? object : [object description];
	NSMutableString *output = [scope valueForKey:WATemplateOutputKey];
	[output appendString:chunk];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"<Print %@>", content];
}

@end





static NSString *const WATemplateParseException = @"WATemplateParseException";
static NSMutableDictionary *WANamedTemplates;


@interface WATemplate()
- (TLStatement*)scanKeyword:(TFStringScanner*)scanner endToken:(NSString**)outEndToken;
- (TLStatement*)scanText:(TFStringScanner*)scanner endToken:(NSString**)outEndToken;
@end




@implementation WATemplate

+ (void)initialize {
	if(self != [WATemplate class]) return;
	WANamedTemplates = [NSMutableDictionary dictionary];
}

+ (id)templateNamed:(NSString*)name inBundle:(NSBundle*)bundle {
	NSURL *URL = [bundle URLForResource:name withExtension:@"wat"];
	if(!URL) [NSException raise:NSInvalidArgumentException format:@"Template named '%@' wasn't found.", name];
	return [[self alloc] initWithContentsOfURL:URL];
}

+ (id)templateNamed:(NSString*)name {
	WATemplate *template = [WANamedTemplates objectForKey:name];
	if(!template) {
		NSURL *URL = [[NSBundle mainBundle] URLForResource:name withExtension:@"wat"];
		if(!URL) return nil;
		template = [[self alloc] initWithContentsOfURL:URL];
		// Reload the template every time in dev mode
		if(!WAGetDevelopmentMode())
			[WANamedTemplates setObject:template forKey:name];
	}
	return [template copy];
}


- (id)initWithStatement:(TLStatement*)statement {
	self = [super init];
	body = statement;
	mapping = [NSMutableDictionary dictionary];
	return self;
}

- (id)initWithSource:(NSString*)templateString {	
	TFStringScanner *scanner = [TLExpression newScannerForString:templateString];
	TLStatement *statement = [self scanText:scanner endToken:nil];
	return [self initWithStatement:statement];
}

- (id)initWithContentsOfURL:(NSURL*)URL {
	return [self initWithSource:[NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:NULL]];
}


- (id)copyWithZone:(NSZone*)zone {
	return [[WATemplate alloc] initWithStatement:body];
}



- (void)setValue:(id)value forKey:(NSString*)key {
	[mapping setObject:value forKey:key];
}


- (void)appendString:(NSString*)string toValueForKey:(NSString*)key {
	NSString *value = [self valueForKey:key];
	if(!value) value = @"";
	if(![value isKindOfClass:[NSString class]])
		[NSException raise:NSInvalidArgumentException format:@"Can't append to key '%@' because previous value isn't a string.", key];
	
	[self setValue:[value stringByAppendingString:string] forKey:key];
}


- (id)valueForKey:(NSString*)key {
	return [mapping objectForKey:key];
}





- (NSString*)result {
	NSMutableString *output = [NSMutableString string];
	TLScope *scope = [[TLScope alloc] initWithParentScope:nil];
	[scope setValue:output forKey:WATemplateOutputKey];
	for(NSString *key in mapping)
		[scope setValue:[mapping objectForKey:key] forKey:key];
	[body invokeInScope:scope];
	return output;
}


#pragma mark Parsing

- (TLStatement*)scanText:(TFStringScanner*)scanner endToken:(NSString**)outEndToken {
	NSMutableArray *statements = [NSMutableArray array];
	
	for(;;) {
		NSString *text = [scanner scanToString:@"<%"];
		if([text length])
			[statements addObject:[[WAPrintStatement alloc] initWithContent:[[TLObject alloc] initWithObject:text]]];
		if(scanner.atEnd) break;
		
		TLStatement *statement = [self scanKeyword:scanner endToken:outEndToken];
		if(!statement) break;
		[statements addObject:statement];		
	}
	
	return [[TLCompoundStatement alloc] initWithStatements:statements];
}


- (TLStatement*)scanKeyword:(TFStringScanner*)scanner endToken:(NSString**)outEndToken {
	if(![scanner scanString:@"<%"]) return nil;
	
	NSString *token = [scanner scanToken];
	
	if([token isEqual:@"end"] || [token isEqual:@"else"] || [token isEqual:@"elseif"]) {
		if(outEndToken) *outEndToken = token;
		return nil;
	
	}else if([token isEqual:@"print"]) {
		TLExpression *content = [TLExpression parseExpression:scanner endToken:@">"];
		[scanner scanToken];
		return [[WAPrintStatement alloc] initWithContent:content];
	
	}else if([token isEqual:@"for"]) {
		NSString *variableName = [scanner scanToken];
		if(![[scanner scanToken] isEqual:@"in"])
			[NSException raise:WATemplateParseException format:@"Expected 'in' after <%%for %@", variableName];
		
		TLExpression *collection = [TLExpression parseExpression:scanner endToken:@">"];
		if(![[scanner scanToken] isEqual:@">"])
			[NSException raise:WATemplateParseException format:@"Expected > (end of keyword), but found something else"];

		NSString *endToken = nil;
		TLStatement *loopBody = [self scanText:scanner endToken:&endToken];

		if(![endToken isEqual:@"end"])
			[NSException raise:WATemplateParseException format:@"Expected <%%end, got <%%%@", endToken];
		
		if(![[scanner scanToken] isEqual:@">"])
			[NSException raise:WATemplateParseException format:@"Expected > after <%%end"];
		
		return [[TLForeachLoop alloc] initWithCollection:collection body:loopBody variableName:variableName];
		
		
	}else if([token isEqual:@"while"]) {
		TLExpression *condition = [TLExpression parseExpression:scanner endToken:@">"];
		if(![[scanner scanToken] isEqual:@">"])
			[NSException raise:WATemplateParseException format:@"Expected > (end of keyword), but found something else"];
		
		NSString *endToken = nil;
		TLStatement *loopBody = [self scanText:scanner endToken:&endToken];
		
		if(![endToken isEqual:@"end"])
			[NSException raise:WATemplateParseException format:@"Expected <%%end, got <%%%@", endToken];
		
		if(![[scanner scanToken] isEqual:@">"])
			[NSException raise:WATemplateParseException format:@"Expected > after <%%end"];
		
		return [[TLWhileLoop alloc] initWithCondition:condition body:loopBody];		
		
		
	}else if([token isEqual:@"if"]) {
		NSMutableArray *conditions = [NSMutableArray array];
		NSMutableArray *consequents = [NSMutableArray array];
		
		[conditions addObject:[TLExpression parseExpression:scanner endToken:@">"]];
		if(![[scanner scanToken] isEqual:@">"])
			[NSException raise:WATemplateParseException format:@"Expected > (end of keyword), but found something else"];
		
		NSString *endToken = nil;
		TLStatement *conditionBody = [self scanText:scanner endToken:&endToken];
		
		for(;;) {
			[consequents addObject:conditionBody];
			
			if([endToken isEqual:@"end"]) {
				if(![[scanner scanToken] isEqual:@">"])
					[NSException raise:WATemplateParseException format:@"Expected > after <%%end"];
				break;
			
			}else if([endToken isEqual:@"elseif"]) {
				[conditions addObject:[TLExpression parseExpression:scanner endToken:@">"]];
				
				if(![[scanner scanToken] isEqual:@">"])
					[NSException raise:WATemplateParseException format:@"Expected > (end of keyword), but found something else"];
				conditionBody = [self scanText:scanner endToken:&endToken];

				
			}else if([endToken isEqual:@"else"]) {
				if(![[scanner scanToken] isEqual:@">"])
					[NSException raise:WATemplateParseException format:@"Expected > (end of keyword), but found something else"];
				
				[conditions addObject:[TLObject trueValue]];
				conditionBody = [self scanText:scanner endToken:&endToken];
			}
			
		}

		return [[TLConditional alloc] initWithConditions:conditions consequents:consequents];
		
	}else if([token isEqual:@"set"]) {
		NSString *varName = [scanner scanToken];
		if(scanner.lastTokenType != TFTokenTypeIdentifier)
			[NSException raise:WATemplateParseException format:@"Expected valid variable name after <%%set, found: %@", varName];
		if(![[scanner scanToken] isEqual:@"="])
			[NSException raise:WATemplateParseException format:@"Expected = after <%%set %@", varName];
		TLExpression *value = [TLExpression parseExpression:scanner endToken:@">"];
		[scanner scanToken];
		
		return [[TLAssignment alloc] initWithIdentifier:varName value:value];
		
	}else{
		[NSException raise:WATemplateParseException format:@"Found unknown template keyword: <%%%@", [scanner peekToken]];
		return nil;
	}
}


@end