//
//  TLSymbol.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TLExpression.h"


@interface TLIdentifier : TLExpression {
	NSString *name;
}

- (id)initWithName:(NSString*)symbolName;

@end
