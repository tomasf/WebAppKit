//
//  WARedirectHandler.h
//  WebAppKit
//
//  Created by Tim Andersson on 3/18/11.
//  Copyright 2011 Cocoabeans Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WARequestHandler.h"
#import "WAApplication.h"

@class TFRegex;

@interface WARedirectHandler : WARequestHandler {
	TFRegex *pathExpression;
	NSString *replacementString;
}

@property (readonly) TFRegex *pathExpression;
@property (readonly) NSString *replacementString;

- (id)initWithPathExpression:(TFRegex *)expression replacementString:(NSString *)replacement;

@end

@interface WAApplication (WARedirect)

- (WARedirectHandler *)addRedirectRuleWithPattern:(NSString *)regex replacement:(NSString *)replacement;
- (WARedirectHandler *)addRedirectRuleWithPath:(NSString *)path replacement:(NSString *)replacement;

@end
