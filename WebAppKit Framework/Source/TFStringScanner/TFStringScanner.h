#import <Foundation/Foundation.h>

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

@property(readonly) NSString *string;
@property NSUInteger location;
@property(readonly, getter=isAtEnd) BOOL atEnd;
@property(readonly) TFTokenType lastTokenType;


+ (id)scannerWithString:(NSString*)string;
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
- (BOOL)scanToken:(NSString*)matchToken;
- (NSString*)peekToken;

@end