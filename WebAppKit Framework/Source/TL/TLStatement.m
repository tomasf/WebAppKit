//
//  TLStatement.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-15.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TL.h"

@implementation TLStatement

- (void)invokeInScope:(TLScope*)scope {
	[NSException raise:NSInternalInconsistencyException format:@"%@ must override %@", [self class], NSStringFromSelector(_cmd)];
}

@end


@implementation TLNoop
- (void)invokeInScope:(TLScope*)scope {}
@end

