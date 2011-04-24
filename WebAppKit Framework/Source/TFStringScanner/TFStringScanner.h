//
//  TFStringScanner.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	TFTokenTypeIdentifier,
	TFTokenTypeNumeric,
	TFTokenTypeSymbol,
} TFTokenType;


@interface TFStringScanner : NSObject {
	NSString *content;
	NSUInteger location;
	NSMutableArray *multicharSymbols;
	TFTokenType lastTokenType;
}

@property NSUInteger location;
@property(readonly) BOOL atEnd;
@property(readonly) TFTokenType lastTokenType;

- (id)initWithString:(NSString*)string;

- (void)addMulticharacterSymbol:(NSString*)symbol;
- (void)addMulticharacterSymbols:(NSString*)symbol, ...;
- (void)removeMulticharacterSymbol:(NSString*)symbol;

- (unichar)scanCharacter;
- (NSString*)scanForLength:(NSUInteger)length;

- (BOOL)scanString:(NSString*)substring;
- (NSString*)scanToString:(NSString*)substring;
- (BOOL)scanWhitespace;

- (NSString*)scanToken;
- (NSString*)peekToken;

@end