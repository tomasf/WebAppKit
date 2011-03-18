//
//  WARedirectHandler.m
//  WebAppKit
//
//  Created by Tim Andersson on 3/18/11.
//  Copyright 2011 Cocoabeans Software. All rights reserved.
//

#import "WARedirectHandler.h"
#import "TFRegex.h"
#import "WARequest.h"
#import "WAResponse.h"

@implementation WARedirectHandler

@synthesize pathExpression, replacementString;

- (id)initWithPathExpression:(TFRegex *)expression replacementString:(NSString *)replacement {
	if(self = [super init]) {
		pathExpression = expression;
		replacementString = replacement;
	}
	return self;
}

- (BOOL)canHandleRequest:(WARequest *)request {
	return [pathExpression matchesString:request.path];
}

- (void)handleRequest:(WARequest*)req response:(WAResponse*)resp {
	NSURL *URL = [NSURL URLWithString:[req.path stringByReplacing:[pathExpression source] with:replacementString]];
	[resp redirectToURL:URL];
	
	[resp finish];
}

@end

@interface WAApplication (Private)
- (TFRegex *)regexForPathExpression:(NSString *)path;
@end

@implementation WAApplication (WARedirect)

- (WARedirectHandler *)addRedirectRuleWithPattern:(NSString *)regex replacement:(NSString *)replacement {
	TFRegex *r = [TFRegex regexWithPattern:regex options:0];
	WARedirectHandler *handler = [[WARedirectHandler alloc] initWithPathExpression:r replacementString:replacement];
	[self addRequestHandler:handler];
	return handler;
}

- (WARedirectHandler *)addRedirectRuleWithPath:(NSString *)path replacement:(NSString *)replacement {
	TFRegex *r = [self regexForPathExpression:path];
	WARedirectHandler *handler = [[WARedirectHandler alloc] initWithPathExpression:r replacementString:replacement];
	[self addRequestHandler:handler];
	return handler;
}

@end