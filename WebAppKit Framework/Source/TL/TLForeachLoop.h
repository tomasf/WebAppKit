//
//  TLForeachLoop.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TLStatement.h"
@class TLExpression;


@interface TLForeachLoop : TLStatement {
	TLExpression *collection;
	NSString *variableName;
	TLStatement *body;
}

- (id)initWithCollection:(TLExpression*)object body:(TLStatement*)contents variableName:(NSString*)var;
@end
