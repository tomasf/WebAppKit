//
//  WALegacy.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2012-03-06.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WARequest.h"

@interface WARequest (WALegacy)
@property(readonly, nonatomic) NSDictionary *POSTParameters __attribute__((deprecated("use bodyParameters instead")));
- (NSString*)valueForPOSTParameter:(NSString*)name __attribute__((deprecated("use valueForBodyParameter: instead")));
@end
