//
//  WALegacy.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2012-03-06.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WALegacy.h"

@implementation WARequest (WALegacy)

- (NSDictionary*)POSTParameters {
	NSLog(@"WARequest.POSTParameters is deprecated. Use bodyParameters instead.");
	return self.bodyParameters;
}

- (NSString *)valueForPOSTParameter:(NSString *)name {
	NSLog(@"-[WARequest valueForPOSTParameter:] is deprecated. Use valueForBodyParameter: instead.");
	return [self valueForBodyParameter:name];

}

@end
