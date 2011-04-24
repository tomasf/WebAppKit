//
//  TLCompoundExpression.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TLStatement.h"

@interface TLCompoundStatement : TLStatement {
	NSArray *statements;
}

- (id)initWithStatements:(NSArray*)array;
@end