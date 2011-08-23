//
//  WSRoute.h
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-09.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WARequestHandler.h"

@class WARequest, WAResponse, TFRegex;

@interface WARoute : WARequestHandler {
	NSArray *components;
	NSArray *argumentWildcardMapping;
	
	NSString *method;
	id target;
	SEL action;
}

@property(readonly) NSString *method;
@property(readonly) SEL action;
@property(readonly) id target;

+ (id)routeWithPathExpression:(NSString*)expr method:(NSString*)m target:(id)object action:(SEL)selector;
@end