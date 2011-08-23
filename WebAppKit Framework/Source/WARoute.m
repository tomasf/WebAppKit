//
//  WSRoute.m
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-09.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WARoute.h"
#import "WARequest.h"
#import "WAResponse.h"
#import "WAApplication.h"
#import "WATemplate.h"
#import <objc/runtime.h>

@interface WAApplication (TransactionPrivate)
- (void)setRequest:(WARequest*)req response:(WAResponse*)resp;
@end

static NSCharacterSet *wildcardComponentCharacters;


@implementation WARoute
@synthesize method, target, action;


+ (void)initialize {
	NSMutableCharacterSet *set = [NSMutableCharacterSet characterSetWithRanges:NSMakeRange('a', 26), NSMakeRange('A', 26), NSMakeRange('0', 10), NSMakeRange(0, 0)];
	[set addCharactersInString:@"-_."];
	wildcardComponentCharacters = set;
}


+ (NSUInteger)wildcardCountInExpressionComponents:(NSArray*)components {
	NSUInteger count = 0;
	for(NSString *component in components)
		if([component hasPrefix:@"*"])
			count++;	
	return count;
}


- (id)initWithPathExpression:(NSString*)expression method:(NSString*)m target:(id)object action:(SEL)selector {
	if(!(self = [super init])) return nil;
	NSParameterAssert(expression != nil);
	NSParameterAssert(m != nil);
	NSParameterAssert(object != nil);
	NSParameterAssert(selector != nil);
	
	NSMutableArray *componentStrings = [[expression componentsSeparatedByString:@"/"] mutableCopy];
	NSUInteger wildcardCount = [[self class] wildcardCountInExpressionComponents:componentStrings];
	NSMutableArray *wildcardMapping = [NSMutableArray array];
	for(int i=0; i<wildcardCount; i++) [wildcardMapping addObject:[NSNull null]];
	
	NSUInteger wildcardCounter = 0;
	for(int i=0; i<[componentStrings count]; i++) {
		NSString *component = [componentStrings objectAtIndex:i];
		if([component hasPrefix:@"*"]) {
			NSString *indexString = [component substringFromIndex:1];
			NSUInteger argumentIndex = [indexString length] ? [indexString integerValue]-1 : wildcardCounter;
			if(argumentIndex > wildcardCount-1) {
				[NSException raise:NSInvalidArgumentException format:@"Invalid argument index %d in path expression. Must be in the range {1..%d}", (int)argumentIndex+1, (int)wildcardCount];
			}
			if([wildcardMapping objectAtIndex:argumentIndex] != [NSNull null]) {
				[NSException raise:NSInvalidArgumentException format:@"Argument index %d is used more than once in path expression.", (int)argumentIndex+1];	
			}
			[wildcardMapping replaceObjectAtIndex:argumentIndex withObject:[NSNumber numberWithUnsignedInteger:wildcardCounter]];
			[componentStrings replaceObjectAtIndex:i withObject:@"*"];
			wildcardCounter++;
		}
	}
	argumentWildcardMapping = wildcardMapping;
	components = componentStrings;
	
	NSUInteger numArgs = [[NSStringFromSelector(selector) componentsSeparatedByString:@":"] count]-1;
	
	if(numArgs != wildcardCount)
		[NSException raise:NSInvalidArgumentException format:@"The number of arguments in the action selector (%@) must be equal to the number of wildcards in the path expression (%d).", NSStringFromSelector(selector), (int)wildcardCount];
	
	method = [m copy];
	action = selector;
	target = object;
	
	return self;
}


+ (id)routeWithPathExpression:(NSString*)expr method:(NSString*)m target:(id)object action:(SEL)selector {
	return [[self alloc] initWithPathExpression:expr method:m target:object action:selector];
}


- (BOOL)stringIsValidComponentValue:(NSString*)string {
	return [[string stringByTrimmingCharactersInSet:wildcardComponentCharacters] length] == 0;
}


- (BOOL)matchesPath:(NSString*)path wildcardValues:(NSArray**)outWildcards {
	NSArray *givenComponents = [path componentsSeparatedByString:@"/"];
	if([givenComponents count] != [components count]) return NO;
	NSMutableArray *wildcardValues = [NSMutableArray array];
	
	for(NSUInteger i=0; i<[components count]; i++) {
		NSString *givenComponent = [givenComponents objectAtIndex:i];
		NSString *component = [components objectAtIndex:i];
		if([component isEqual:@"*"]) {
			if(![self stringIsValidComponentValue:givenComponent])
				return NO;
			[wildcardValues addObject:givenComponent];
		}else{
			if(![givenComponent isEqual:component])
				return NO;
		}
	}
	if(outWildcards) *outWildcards = wildcardValues;
	return YES;	
}


- (BOOL)canHandleRequest:(WARequest*)request {
	return [request.method isEqual:method] && [self matchesPath:request.path wildcardValues:NULL];
}


- (void)handleRequest:(WARequest*)request response:(WAResponse*)response {
	NSArray *wildcardValues = nil;
	[self matchesPath:request.path wildcardValues:&wildcardValues];
	NSUInteger numWildcards = [wildcardValues count];
	NSString *strings[numWildcards];
	for(int i=0; i<[argumentWildcardMapping count]; i++) {
		NSUInteger componentIndex = [[argumentWildcardMapping objectAtIndex:i] unsignedIntegerValue];
		strings[i] = [wildcardValues objectAtIndex:componentIndex];
	}
		
	[target setRequest:request response:response];
	[target preprocess];
	
	Method actionMethod = class_getInstanceMethod([target class], action);
	BOOL hasReturnValue = (method_getTypeEncoding(actionMethod)[0] != 'v');
	IMP m = method_getImplementation(actionMethod);
	id value = nil;
	
	switch(numWildcards) {
		case 0: value = m(target, action);
			break;
		case 1: value = m(target, action, strings[0]);
			break;
		case 2: value = m(target, action, strings[0], strings[1]);
			break;
		case 3: value = m(target, action, strings[0], strings[1], strings[2]);
			break;
		case 4: value = m(target, action, strings[0], strings[1], strings[2], strings[3]);
			break;
		case 5: value = m(target, action, strings[0], strings[1], strings[2], strings[3], strings[4]);
			break;
		case 6: value = m(target, action, strings[0], strings[1], strings[2], strings[3], strings[4], strings[5]);
			break;
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Too many arguments."];
			break;
	}
	
	if(hasReturnValue) {
		if([value isKindOfClass:[WATemplate class]])
			[response appendString:[value result]];
		else if([value isKindOfClass:[NSData class]])
			[response appendBodyData:value];
		else
			[response appendString:[value description]];
	}
	
	[target postprocess];
	[target setRequest:nil response:nil];
	[response finish];
}


@end