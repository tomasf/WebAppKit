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
#import "WASession.h"

@interface WATemplate()
- (TLStatement*)scanKeyword:(TFStringScanner*)scanner endToken:(NSString**)outEndToken;
- (TLStatement*)scanText:(TFStringScanner*)scanner endToken:(NSString**)outEndToken;
- (NSString*)resultWithScope:(TLScope*)scope;
@end


@interface TLExpression ()
+ (TLExpression*)parseExpression:(TFStringScanner*)scanner endToken:(NSString*)string;
+ (TFStringScanner*)newScannerForString:(NSString*)string;
@end


NSString *const WATemplateOutputKey = @"_WATemplateOutput";
NSString *const WATemplateChildContentKey = @"_WATemplateChildContent";
NSString *const WATemplateNilValuePlaceholder = @"_WATemplateNil";
NSString *const WATemplateSessionTokenKey = @"_WATemplateSessionToken";


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
	if(!object) return;
	NSString *chunk = [object isKindOfClass:[NSString class]] ? object : [object description];
	NSMutableString *output = [scope valueForKey:WATemplateOutputKey];
	[output appendString:chunk];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"<Print %@>", content];
}

@end




@interface WASubTemplateStatement : TLStatement {
	NSString *templateName;
}
- (id)initWithTemplateName:(NSString*)name;
@end



@implementation WASubTemplateStatement

- (id)initWithTemplateName:(NSString*)name {
	self = [super init];
	templateName = [name copy];
	return self;
}

- (void)invokeInScope:(TLScope *)scope {
	WATemplate *template = [WATemplate templateNamed:templateName];
	NSString *result = [template resultWithScope:scope];
	
	NSMutableString *output = [scope valueForKey:WATemplateOutputKey];
	[output appendString:result];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"<Sub-template %@>", templateName];
}

@end



@interface WADebugStatement : TLStatement {}
@end

@implementation WADebugStatement

- (void)invokeInScope:(TLScope *)scope {
	NSLog(@"Scope: %@", [scope debugDescription]);
}

- (NSString*)description {
	return [NSString stringWithFormat:@"<Debug statement>"];
}

@end




static NSString *const WATemplateParseException = @"WATemplateParseException";
static NSMutableDictionary *WANamedTemplates;



@implementation WATemplate
@synthesize parent, session;


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


+ (id)templateNamed:(NSString*)name parent:(NSString*)parentName {
	WATemplate *template = [self templateNamed:name];
	template.parent = [self templateNamed:parentName];
	return template;
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
	[mapping setObject:value ?: WATemplateNilValuePlaceholder forKey:key];
}


- (void)appendString:(NSString*)string toValueForKey:(NSString*)key {
	NSString *value = [self valueForKey:key];
	if(!value) value = @"";
	if(![value isKindOfClass:[NSString class]])
		[NSException raise:NSInvalidArgumentException format:@"Can't append to key '%@' because previous value isn't a string.", key];
	
	[self setValue:[value stringByAppendingString:string] forKey:key];
}


- (id)valueForKey:(NSString*)key {
	id value = [mapping objectForKey:key];
	if(value == WATemplateNilValuePlaceholder) return nil;
	return value;
}

- (id)realValueForValue:(id)value {
	if(value == WATemplateNilValuePlaceholder) return nil;
	else return value;
}

- (NSString*)resultWithScope:(TLScope*)scope {
	TLScope *innerScope = [[TLScope alloc] initWithParentScope:scope];
	NSMutableString *output = [NSMutableString string];
	[innerScope declareValue:output forKey:WATemplateOutputKey];
	
	for(NSString *key in mapping)
		[innerScope setValue:[self realValueForValue:[mapping objectForKey:key]] forKey:key];
	
	if(self.session)
		[innerScope setValue:self.session.token forKey:WATemplateSessionTokenKey];
	
	[body invokeInScope:innerScope];
	return output;
}

- (NSString*)resultWithChildContent:(NSString*)content additionalMapping:(NSDictionary*)childMapping {
	TLScope *scope = [[TLScope alloc] initWithParentScope:nil];
	[scope setValue:content forKey:WATemplateChildContentKey];
	
	for(NSString *key in childMapping)
		[scope setValue:[self realValueForValue:[childMapping objectForKey:key]] forKey:key];

	NSString *output = [self resultWithScope:scope];
	if(self.parent)
		return [self.parent resultWithChildContent:output additionalMapping:mapping];
	else
		return output;
}


- (NSString*)result {
	return [self resultWithChildContent:nil additionalMapping:nil];
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
		
	}else if([token isEqual:@"debug"]) {
		if(![[scanner scanToken] isEqual:@">"])
			[NSException raise:WATemplateParseException format:@"Expected > after <%debug, but found something else."];
		return [[WADebugStatement alloc] init];
		
	
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
		
		
	}else if([token isEqual:@"content"]) {
		if(![[scanner scanToken] isEqual:@">"])
			[NSException raise:WATemplateParseException format:@"Expected > after <%content, but found something else."];
		return [[WAPrintStatement alloc] initWithContent:[[TLIdentifier alloc] initWithName:WATemplateChildContentKey]];
		
	}else if([token isEqual:@"template"]) {
		NSString *name = [[scanner scanToString:@">"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		if(![[scanner scanToken] isEqual:@">"])
			[NSException raise:WATemplateParseException format:@"Expected > after <%template %@, but found something else.", name];
		return [[WASubTemplateStatement alloc] initWithTemplateName:name];
		
	}else if([token isEqual:@"token"]) {
		if(![[scanner scanToken] isEqual:@">"])
			[NSException raise:WATemplateParseException format:@"Expected > after <%token, but found something else."];
		return [[WAPrintStatement alloc] initWithContent:[[TLIdentifier alloc] initWithName:WATemplateSessionTokenKey]];

		
	}else if([token isEqual:@"comment"]) {
		[scanner scanToString:@"%>"];
		[scanner scanForLength:2];
		return [[TLNoop alloc] init];
		
	}else{
		[NSException raise:WATemplateParseException format:@"Found unknown template keyword: <%%%@", token];
		return nil;
	}
}


@end