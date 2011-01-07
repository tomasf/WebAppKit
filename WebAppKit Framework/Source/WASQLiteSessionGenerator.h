//
//  WASQLiteSessionManager.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WASessionGenerator.h"

@class FMDatabase;

@interface WASQLiteSessionGenerator : WASessionGenerator {
	NSString *name;
	FMDatabase *database;
}

- (id)initWithName:(NSString*)n;

@end