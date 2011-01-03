//
//  WSCometHandler.m
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-23.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WACometHandler.h"

@implementation WACometHandler

- (id)initWithStreamClass:(Class)sClass path:(NSString*)requestPath {
	self = [super init];
	streamClass = sClass;
	path = [requestPath copy];
	return self;
}

- (BOOL)canHandleRequest:(WARequest*)req {
	return [[req path] isEqual:path];
}

- (WARequestHandler*)handlerForRequest:(WARequest*)req {
	return [[streamClass alloc] init];
}

@end