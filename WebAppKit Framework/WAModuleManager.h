//
//  WAModuleManager.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-07.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class WAModule;

@interface WAModuleManager : NSObject {
	NSMutableDictionary *allModules;
}

+ (id)sharedManager;
- (WAModule*)moduleForIdentifier:(NSString*)ID;
- (NSString*)headerStringFromModuleIdentifiers:(NSSet*)IDs;
- (NSSet*)allRequestHandlers;
@end