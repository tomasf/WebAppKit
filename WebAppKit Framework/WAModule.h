//
//  WAModule.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-07.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

@class WARequestHandler;


@interface WAModule : NSObject {
	NSBundle *bundle;
	NSDictionary *info;
	Class bundleClass;
}

- (id)initWithBundleURL:(NSURL*)URL;

@property(readonly) NSString *identifier;
@property(readonly) NSString *publicResourceDirectory;
@property(readonly) NSString *baseRequestPath;
@property(readonly) NSArray *dependencies;
@property(readonly) NSArray *scripts;
@property(readonly) NSArray *stylesheets;
@property(readonly) WARequestHandler *resourcesRequestHandler;
@property(readonly) NSString *additionalCode;
@end