//
//  TCSampleRateTransformer.m
//  TuneConnect
//
//  Created by Matt Patenaude on 2/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCSampleRateTransformer.h"


@implementation TCSampleRateTransformer

+ (Class)transformedValueClass
{
	return [NSString class];
}
+ (BOOL)allowsReverseTransformation
{
	return NO;
}
- (id)transformedValue:(id)value
{
	NSNumber *newVal = [NSNumber numberWithFloat:([value floatValue]/1000.0)];
	return [NSString stringWithFormat:@"%@ kHz", [newVal description]];
}

@end
