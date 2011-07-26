//
//  WARouteLion.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-07-26.
//  Copyright 2011 Lighthead Software. All rights reserved.
//
#if LION
#import "WARoute.h"
#import "WARequest.h"
#import "WAApplication.h"
#import "WATemplate.h"
#import <objc/runtime.h>

@interface WAApplication (TransactionPrivate)
- (void)setRequest:(WARequest*)req response:(WAResponse*)resp;
@end



@implementation WARoute
@synthesize method, target, action;


+ (NSRegularExpression*)regexForPathExpression:(NSString*)path {
	NSMutableArray *newComponents = [NSMutableArray array];
	for(NSString *component in [path pathComponents]) {
		if([component isEqual:@"*"])
			[newComponents addObject:@"([[:alnum:]_-]+)"];
		else
			[newComponents addObject:[NSRegularExpression escapedTemplateForString:component]];
	}
	
	NSString *regexString = [NSString stringWithFormat:@"^%@$", [NSString pathWithComponents:newComponents]];
	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:&error];
	if(!regex)
		[NSException raise:NSGenericException format:@"WARoute failed to compile regular expression for path expression.\nPath: %@\nRegex: %@\nError: %@", path, regexString, error];	
	
	return regex;
}


+ (id)routeWithPathExpression:(NSString*)expr method:(NSString*)m target:(id)object action:(SEL)selector {
	NSParameterAssert(expr != nil);
	NSRegularExpression *regex = [self regexForPathExpression:expr];
	return [[self alloc] initWithPathRegex:regex method:m target:object action:selector];
}


- (id)initWithPathRegex:(id)regex method:(NSString*)m target:(id)object action:(SEL)selector {
	if(!(self = [super init])) return nil;
	NSParameterAssert(regex != nil);
	NSParameterAssert(m != nil);
	NSParameterAssert(object != nil);
	NSParameterAssert(selector != nil);
	pathExpression = regex;
	
	NSUInteger numSubs = [pathExpression numberOfCaptureGroups];
	NSUInteger numArgs = WAGetParameterCountForSelector(selector);
	
	if(numArgs != numSubs)
		[NSException raise:NSInvalidArgumentException format:@"The number of arguments in the action selector (%@) must be equal to the number of sub-expressions in the regular expression (%d).", NSStringFromSelector(selector), (int)numSubs];
	if(numArgs > 6)
		[NSException raise:NSInvalidArgumentException format:@"Routes support a maximum of 6 parameters."];
	
	method = [m copy];
	action = selector;
	target = object;
	
	return self;
}


- (BOOL)canHandleRequest:(WARequest*)request {
	NSString *path = request.path;
	return [request.method isEqual:method] && [pathExpression firstMatchInString:request.path options:0 range:NSMakeRange(0, [path length])];
}


- (void)handleRequest:(WARequest*)request response:(WAResponse*)response {
	NSUInteger subs = [pathExpression numberOfCaptureGroups];
	NSString *strings[subs];
	NSString *path = request.path;
	NSTextCheckingResult *result = [pathExpression firstMatchInString:path options:0 range:NSMakeRange(0, [path length])];
	for(int i=0; i<subs; i++)
		strings[i] = [path substringWithRange:[result rangeAtIndex:i+1]];
	
	[target setRequest:request response:response];
	[target preprocess];
	
	Method actionMethod = class_getInstanceMethod([target class], action);
	BOOL hasReturnValue = (method_getTypeEncoding(actionMethod)[0] != 'v');
	IMP m = method_getImplementation(actionMethod);
	id value = nil;
	
	switch(subs) {
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
	}
	
	
	if(hasReturnValue) {
		if([value isKindOfClass:[WATemplate class]])
			[response appendString:[value result]];
		else if([value isKindOfClass:[NSData class]])
			[response appendBodyData:value];
		else if([value isKindOfClass:[NSString class]])
			[response appendString:value];
		else
			[response appendString:[value description]];
	}
	
	[target postprocess];
	[target setRequest:nil response:nil];
	[response finish];
}


@end


#endif // LION