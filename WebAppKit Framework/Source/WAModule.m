//
//  WSModule.m
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-16.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WAModule.h"
#import "WATemplate.h"

@interface WAModule ()
- (NSSet*)dependencies;
@end


@implementation WAModule

+ (id)sharedInstance {
	static NSMutableDictionary *singletons = nil;
	if(!singletons) singletons = [NSMutableDictionary dictionary];
	id instance = [singletons objectForKey:NSStringFromClass(self)];
	if(!instance)
		[singletons setObject:(instance = [[self alloc] init]) forKey:NSStringFromClass(self)];
	return instance;
}

- (void)invokeWithTemplate:(WATemplate*)t loadedModules:(NSMutableSet*)loadedModules {
	currentTemplate = t;
	[loadedModules addObject:self];
	for(WAModule *module in [self dependencies]) {
		if(![loadedModules containsObject:module])
			[module invokeWithTemplate:t loadedModules:loadedModules];
	}
	
	[self installInTemplate:t];
	currentTemplate = nil;
}


- (void)installScript:(NSString*)path inKey:(NSString*)target {
	NSString *string = [NSString stringWithFormat:@"<script type=\"application/javascript\" src=\"%@\"></script>", path];
	[currentTemplate appendString:string toValueForKey:target];
}

- (void)installStylesheet:(NSString*)path inKey:(NSString*)target {
	NSString *string = [NSString stringWithFormat:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"%@\"/>", path];
	[currentTemplate appendString:string toValueForKey:target];
}


- (NSSet*)dependencies {
	return nil;
}

- (void)installInTemplate:(WATemplate*)template {
	
}

@end
