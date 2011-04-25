//
//  TLExpression.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-11.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

@class TLScope;

@interface TLExpression : NSObject {
}

@property(readonly) BOOL constant;

+ (TLExpression*)expressionByParsingString:(NSString*)string;

- (id)evaluateWithScope:(TLScope*)scope;
- (id)evaluate;
@end