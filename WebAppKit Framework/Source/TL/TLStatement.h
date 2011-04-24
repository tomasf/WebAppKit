//
//  TLStatement.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-15.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

@class TLScope;

@interface TLStatement : NSObject {}
- (void)invokeInScope:(TLScope*)scope;
@end