//
//  WSUtilities.h
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-18.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

extern NSString *WAGenerateUUIDString(void);
extern uint64_t WANanosecondTime();

extern NSString *WAApplicationSupportDirectory(void);

extern NSDateFormatter *WAHTTPDateFormatter(void);
extern NSString *WAExtractHeaderValueParameters(NSString *fullValue, NSDictionary **outParams);