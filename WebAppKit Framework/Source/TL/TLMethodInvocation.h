//
//  TLMethodInvocation.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-11.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TLExpression.h"

@interface TLMethodInvocation : TLExpression {
	TLExpression *target;
	SEL selector;
	NSArray *arguments;
}

- (id)initWithReceiver:(TLExpression*)expr selector:(SEL)sel arguments:(NSArray*)args;
@end
