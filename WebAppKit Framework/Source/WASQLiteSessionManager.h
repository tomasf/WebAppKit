//
//  WASQLiteSessionManager.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WASessionManager.h"

@class FMDatabase;

@interface WASQLiteSessionManager : WASessionManager {
	NSString *name;
	FMDatabase *database;
}

- (id)initWithName:(NSString*)n;

@end