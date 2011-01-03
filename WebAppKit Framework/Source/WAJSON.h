//
//  FTJSON.h
//  JSON
//
//  Created by Tomas Franzén on 2009-10-25.
//  Copyright 2009 Lighthead Software. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PKTokenizer;

@interface WAJSONParser : NSObject {
	PKTokenizer *tokenizer;
	NSError *error;
}

+ (id)objectFromJSON:(NSString*)JSONString error:(NSError**)outError;
+ (NSString*)JSONFromObject:(id)object;
@end

@interface NSString (JSONEncoding)
- (NSString*)JSONValue;
@end
@interface NSArray (JSONEncoding)
- (NSString*)JSONValue;
@end
@interface NSDictionary (JSONEncoding)
- (NSString*)JSONValue;
@end
@interface NSNumber (JSONEncoding)
- (NSString*)JSONValue;
@end
@interface NSNull (JSONEncoding)
- (NSString*)JSONValue;
@end