//
//  WSCometHandler.h
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-23.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WARequestHandler.h"

// This class is experimental

@interface WACometHandler : WARequestHandler {
	NSString *path;
	Class streamClass;
}

- (id)initWithStreamClass:(Class)sClass path:(NSString*)requestPath;

@end
