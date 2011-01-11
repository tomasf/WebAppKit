//
//  WAHTTPSupport.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-10.
//  Copyright 2011 Lighthead Software. All rights reserved.
//
#import "WAHTTPSupport.h"

WAByteRange WAByteRangeFromRangeSpec(NSString *spec) {
	NSArray *parts = [spec componentsSeparatedByString:@"-"];
	if([parts count] != 2) return WAByteRangeInvalid;
	
	WAByteRange range = WAByteRangeInvalid;
	NSString *firstByteString = [parts objectAtIndex:0], *lastByteString = [parts objectAtIndex:1];
	
	if([firstByteString length])
		range.firstByte = [firstByteString longLongValue];
	if([lastByteString length])
		range.lastByte = [lastByteString longLongValue];
	
	if([firstByteString length] && [lastByteString length] && range.lastByte < range.firstByte)
		return WAByteRangeInvalid;
	
	return range;
}


BOOL WAByteRangeIsInvalid(WAByteRange range) {
	return range.firstByte == WABytePositionUndefined && range.lastByte == WABytePositionUndefined;
}


WAByteRange WAByteRangeMakeAbsolute(WAByteRange range, uint64_t availableLength) {
	if(WAByteRangeIsInvalid(range)) return range;
	if(range.firstByte == WABytePositionUndefined) {
		if(range.lastByte == 0) return WAByteRangeInvalid;
		range.firstByte = MAX(availableLength-range.lastByte, 0);
		range.lastByte = availableLength-1;
	}else if(range.lastByte == WABytePositionUndefined) {
		if(range.firstByte >= availableLength) return WAByteRangeInvalid;
		range.lastByte = availableLength-1;
	}
	range.firstByte = MIN(range.firstByte,availableLength-1);
	range.lastByte = MIN(range.lastByte,availableLength-1);
	return range;
}

WAByteRange WAByteRangeMake(uint64_t first, uint64_t last) {
	return (WAByteRange){first, last};
}


BOOL WAByteRangeContainsByte(WAByteRange concreteRange, uint64_t bytePos) {
	return bytePos >= concreteRange.firstByte && bytePos <= concreteRange.lastByte;
}

BOOL WAByteRangesOverlap(WAByteRange range1, WAByteRange range2) {
	return WAByteRangeContainsByte(range1, range2.firstByte) || WAByteRangeContainsByte(range1, range2.lastByte) || WAByteRangeContainsByte(range2, range1.firstByte) || WAByteRangeContainsByte(range2, range1.lastByte);
}


WAByteRange WAByteRangeCombine(WAByteRange range1, WAByteRange range2) {
	if(WAByteRangesOverlap(range1, range2) || range1.lastByte == range2.firstByte-1 || range2.lastByte == range1.firstByte-1)
		return WAByteRangeMake(MIN(range1.firstByte, range2.firstByte), MAX(range1.lastByte, range2.lastByte));
	else
		return WAByteRangeInvalid;
}



