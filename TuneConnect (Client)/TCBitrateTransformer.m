//
//  TCBitrateTransformer.m
//  TuneConnect
//
//  Created by Matt Patenaude on 2/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCBitrateTransformer.h"


@implementation TCBitrateTransformer

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
	return [NSString stringWithFormat:@"%@ kbps", [value description]];
}

@end
