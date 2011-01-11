//
//  WAHTTPSupport.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-10.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

typedef enum {
	WANoneAuthenticationScheme,
	WABasicAuthenticationScheme,
	WADigestAuthenticationScheme,
} WAAuthenticationScheme;


typedef struct {
	uint64_t firstByte;
	uint64_t lastByte;
} WAByteRange;


enum {WABytePositionUndefined = UINT64_MAX};
static const WAByteRange WAByteRangeInvalid = {WABytePositionUndefined, WABytePositionUndefined};

extern WAByteRange WAByteRangeMake(uint64_t first, uint64_t last);
extern BOOL WAByteRangeIsInvalid(WAByteRange range);
extern WAByteRange WAByteRangeFromRangeSpec(NSString *spec);
extern WAByteRange WAByteRangeMakeAbsolute(WAByteRange range, uint64_t availableLength);
extern WAByteRange WAByteRangeCombine(WAByteRange range1, WAByteRange range2);