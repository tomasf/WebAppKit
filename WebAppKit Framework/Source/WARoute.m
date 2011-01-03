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
#import "TFRegex.h"
#import "WAApplication.h"
#import "WATemplate.h"
#import <objc/runtime.h>

@implementation WARoute
@synthesize method, pathExpression, target, action;


- (id)initWithPathExpression:(TFRegex*)regex method:(NSString*)m target:(id)object action:(SEL)selector {
	self = [super init];
	pathExpression = regex;
	
	NSUInteger numSubs = pathExpression.subexpressionCount;
	NSUInteger numArgs = [[NSStringFromSelector(selector) componentsSeparatedByString:@":"] count]-1;
	
	if(numArgs != numSubs+2)
		[NSException raise:NSInvalidArgumentException format:@"The number of arguments in the action selector must be equal to the number of sub-expressions in the regular expression, plus two for the request and response. Number of sub-expressions: %d, selector: %@", (int)numSubs, NSStringFromSelector(selector)];
	
	method = [m copy];
	action = selector;
	target = object;
	
	return self;
}

- (BOOL)canHandleRequest:(WARequest*)request {
	return [request.method isEqual:method] && [pathExpression matchesString:request.path];
}

- (void)handleRequest:(WARequest*)request response:(WAResponse*)response {
	NSUInteger subs = pathExpression.subexpressionCount;
	NSString *strings[subs];
	NSArray *matches = [[pathExpression subExpressionsInMatchesOfString:request.path] objectAtIndex:0];
	[matches getObjects:strings range:NSMakeRange(1, subs)];
	IMP m = [target methodForSelector:action];
	
	[target preprocessRequest:request response:response];
	Method meth = class_getInstanceMethod([target class], action);
	BOOL hasReturnValue = (method_getTypeEncoding(meth)[0] != 'v');
	id value = nil;
	
	switch(subs) {
		case 0: 
			value = m(target, action, request, response);
			break;
		case 1:
			value = m(target, action, request, response, strings[0]);
			break;
		case 2:
			value = m(target, action, request, response, strings[0], strings[1]);
			break;
		case 3:
			value = m(target, action, request, response, strings[0], strings[1], strings[2]);
			break;
		case 4:
			value = m(target, action, request, response, strings[0], strings[1], strings[2], strings[3]);
			break;
		case 5:
			value = m(target, action, request, response, strings[0], strings[1], strings[2], strings[3], strings[4]);
			break;
		case 6:
			value = m(target, action, request, response, strings[0], strings[1], strings[2], strings[3], strings[4], strings[5]);
			break;
		default:
			// really?
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
	
	[target postprocessRequest:request response:response];
	[response finish];
}


@end