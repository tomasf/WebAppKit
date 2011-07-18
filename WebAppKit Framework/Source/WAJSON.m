//
//  WAJSON.m
//  JSCTest
//
//  Created by Tomas Franzén on 2011-02-21.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WAJSON.h"
#import <JavaScriptCore/JavaScriptCore.h>

/*
JSON <--[JavaScriptCore]--> Javascript Objects <--[WAJSON]--> Cocoa Objects
*/

@interface NSObject (WAJSONEncodingPrivate)
- (JSValueRef)JavaScriptRepresentationWithContext:(JSContextRef)ctx;
@end


@implementation NSObject (WAJSON)

- (NSString*)JSONRepresentationWithIndentation:(NSUInteger)indentation {
	JSGlobalContextRef ctx = JSGlobalContextCreate(NULL);
	JSValueRef value = [self JavaScriptRepresentationWithContext:ctx];
	JSStringRef JSON = JSValueCreateJSONString(ctx, value, indentation, NULL);
	JSGlobalContextRelease(ctx);
	
	if(!JSON) return nil;
	return NSMakeCollectable(JSStringCopyCFString(NULL, JSON));
}

- (NSString*)JSONRepresentation {
	return [self JSONRepresentationWithIndentation:0];
}

@end


@implementation NSString (WAJSON)
- (JSValueRef)JavaScriptRepresentationWithContext:(JSContextRef)ctx {
	return JSValueMakeString(ctx, (JSStringRef)CFMakeCollectable(JSStringCreateWithCFString((CFStringRef)self)));
}
@end


@implementation NSNumber (WAJSON)
- (JSValueRef)JavaScriptRepresentationWithContext:(JSContextRef)ctx {
	if(strcmp([self objCType], @encode(BOOL)) == 0)
		return JSValueMakeBoolean(ctx, [self boolValue]);
	else
		return JSValueMakeNumber(ctx, [self doubleValue]);
}
@end


@implementation NSDictionary (WAJSON)
- (JSValueRef)JavaScriptRepresentationWithContext:(JSContextRef)ctx {
	JSObjectRef object = JSObjectMake(ctx, NULL, NULL);
	for(NSString *key in self) {
		JSStringRef keyString = (JSStringRef)CFMakeCollectable(JSStringCreateWithCFString((CFStringRef)key));
		JSValueRef value = [[self objectForKey:key] JavaScriptRepresentationWithContext:ctx];
		JSObjectSetProperty(ctx, object, keyString, value, kJSPropertyAttributeNone, NULL);
	}
	return object;
}
@end


@implementation NSArray (WAJSON)
- (JSValueRef)JavaScriptRepresentationWithContext:(JSContextRef)ctx {
	JSValueRef values[[self count]];
	
	NSUInteger index = 0;
	for(id object in self)
		values[index++] = [object JavaScriptRepresentationWithContext:ctx];
	
	return JSObjectMakeArray(ctx, [self count], values, NULL);
}
@end


@implementation NSNull (WAJSON)
- (JSValueRef)JavaScriptRepresentationWithContext:(JSContextRef)ctx {
	return JSValueMakeNull(ctx);
}
@end


#define JSSTR(x) ((JSStringRef)CFMakeCollectable(JSStringCreateWithCFString(CFSTR(x))))


@implementation WAJSONParser

+ (id)objectFromJSValue:(JSValueRef)value context:(JSGlobalContextRef)ctx {
	switch(JSValueGetType(ctx, value)) {
		case kJSTypeNull:
			return [NSNull null];
		case kJSTypeBoolean:
			return [NSNumber numberWithBool:JSValueToBoolean(ctx, value)];
		case kJSTypeNumber:
			return [NSNumber numberWithDouble:JSValueToNumber(ctx, value, NULL)];
		case kJSTypeString:
			return (id)CFMakeCollectable(JSStringCopyCFString(NULL, (JSStringRef)CFMakeCollectable(JSValueToStringCopy(ctx, value, NULL))));
		case kJSTypeObject: {
			JSObjectRef object = (JSObjectRef)value;
			JSValueRef constructor = JSEvaluateScript(ctx, JSSTR("Array"), NULL, NULL, 0, NULL);
			
			if(JSValueIsInstanceOfConstructor(ctx, value, (JSObjectRef)constructor, NULL)) {
				NSMutableArray *array = [NSMutableArray array];
				JSValueRef lengthValue = JSObjectGetProperty(ctx, object, JSSTR("length"), NULL);
				unsigned length = JSValueToNumber(ctx, lengthValue, NULL);
				
				for(unsigned i=0; i<length; i++) {					
					JSValueRef indexValue = JSObjectGetPropertyAtIndex(ctx, object, i, NULL);
					[array addObject:[self objectFromJSValue:indexValue context:ctx]];
				}
				return array;
			}else{
				NSMutableDictionary *dict = [NSMutableDictionary dictionary];
				JSPropertyNameArrayRef names = JSObjectCopyPropertyNames(ctx, object);
				size_t count = JSPropertyNameArrayGetCount(names);
				for(size_t i=0; i<count; i++) {
					JSStringRef name = JSPropertyNameArrayGetNameAtIndex(names, i);
					JSValueRef indexValue = JSObjectGetProperty(ctx, object, name, NULL);
					NSString *key = (NSString*)NSMakeCollectable(JSStringCopyCFString(NULL, name));
					id dictValue = [self objectFromJSValue:indexValue context:ctx];
					[dict setObject:dictValue forKey:key];
				}
				return dict;
			}
			
		}
		default: return NULL;
	}
}

+ (id)objectFromJSON:(NSString*)JSON {
	NSParameterAssert(JSON);
	JSGlobalContextRef ctx = JSGlobalContextCreate(NULL);
	JSStringRef source = (JSStringRef)JSStringCreateWithCFString((CFStringRef)JSON);
	
	JSValueRef value = JSValueMakeFromJSONString(ctx, source);
	CFRelease(source);
	if(!value) {
		JSGlobalContextRelease(ctx);
		return nil;
	}
	id object = [self objectFromJSValue:value context:ctx];
	
	JSGlobalContextRelease(ctx);
	return object;	
}

@end