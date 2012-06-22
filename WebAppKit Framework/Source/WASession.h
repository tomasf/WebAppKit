//
//  WASQLiteSession.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WASession.h"

@class WARequest, WAResponse, FMDatabase;

@interface WASession : NSObject {

}

@property(readonly, copy) NSString *token;

- (id)valueForKey:(NSString*)key;
- (void)setValue:(id)value forKey:(NSString*)key;
- (void)removeValueForKey:(NSString*)key;
- (NSSet*)allKeys;

- (BOOL)validateRequestTokenForParameter:(NSString*)parameterName;
- (BOOL)validateRequestToken;
@end