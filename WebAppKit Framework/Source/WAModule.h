//
//  WSModule.h
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-16.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

@class WATemplate;

@interface WAModule : NSObject {
	__weak WATemplate *currentTemplate;
}

- (void)invokeWithTemplate:(WATemplate*)t loadedModules:(NSMutableSet*)loadedModules;


+ (id)sharedInstance;

- (void)installScript:(NSString*)path inKey:(NSString*)target;
- (void)installStylesheet:(NSString*)path inKey:(NSString*)target;

- (void)installInTemplate:(WATemplate*)template;
@end