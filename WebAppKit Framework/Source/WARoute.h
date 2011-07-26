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
	BOOL hasTransactionParameters;
}

@property(readonly) NSString *method;
@property(readonly) TFRegex *pathExpression;
@property(readonly) SEL action;
@property(readonly) id target;

+ (id)routeWithPathExpression:(NSString*)expr method:(NSString*)m target:(id)object action:(SEL)selector;

- (id)initWithPathRegex:(TFRegex*)regex method:(NSString*)m target:(id)object action:(SEL)selector;
@end