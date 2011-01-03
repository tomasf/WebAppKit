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
	NSString *method;
	TFRegex *pathExpression;
	id target;
	SEL action;
}

@property(readonly) NSString *method;
@property(readonly) TFRegex *pathExpression;
@property(readonly) SEL action;
@property(readonly) id target;

- (id)initWithPathExpression:(TFRegex*)regex method:(NSString*)m target:(id)object action:(SEL)selector;
- (BOOL)canHandleRequest:(WARequest*)request;
@end