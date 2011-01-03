//
//  WSDirectoryHandler.h
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-11.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WARequestHandler.h"

@interface WADirectoryHandler : WARequestHandler {
	NSString *directoryRoot;
	NSString *requestPathRoot;
}

- (id)initWithDirectory:(NSString*)root requestPath:(NSString*)path;
@end
