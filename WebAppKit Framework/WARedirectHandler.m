//
//  WARedirectHandler.m
//  WebAppKit
//
//  Created by Tim Andersson on 3/18/11.
//  Copyright 2011 Scratchapp. All rights reserved.
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
	NSLog(@"%@ matches %@: %i", [pathExpression source], request.path, [pathExpression matchesString:request.path]);
	return [pathExpression matchesString:request.path];
}

- (void)handleRequest:(WARequest*)req response:(WAResponse*)resp {
	NSURL *URL = [NSURL URLWithString:[req.path stringByReplacing:[pathExpression source] with:replacementString]];
	[resp redirectToURL:URL];
	
	[resp finish];
}

@end
