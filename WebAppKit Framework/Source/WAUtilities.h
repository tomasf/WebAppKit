//
//  WSUtilities.h
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-18.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

NSString *WAGenerateUUIDString(void);
uint64_t WANanosecondTime();

NSString *WAApplicationSupportDirectory(void);

NSDateFormatter *WAHTTPDateFormatter(void);
NSString *WAExtractHeaderValueParameters(NSString *fullValue, NSDictionary **outParams);

void WASetDevelopmentMode(BOOL enable);
BOOL WAGetDevelopmentMode();