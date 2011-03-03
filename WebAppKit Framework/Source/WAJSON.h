//
//  WAJSON.h
//  JSCTest
//
//  Created by Tomas Franzén on 2011-02-21.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>

@interface NSObject (WAJSONEncoding)
- (NSString*)JSONRepresentation;
- (NSString*)JSONRepresentationWithIndentation:(NSUInteger)indentation;
@end



@interface WAJSONParser : NSObject {

}
+ (id)objectFromJSON:(NSString*)JSON;
@end