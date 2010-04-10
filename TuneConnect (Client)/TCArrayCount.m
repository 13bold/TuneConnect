//
//  TCArrayCount.m
//  TuneConnect
//
//  Created by Matt Patenaude on 2/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCArrayCount.h"


@implementation TCArrayCount

+ (Class)transformedValueClass
{
	return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation
{
	return NO;
}
- (id)transformedValue:(id)value
{
	if ([value count] > 0)
		return [NSNumber numberWithBool:YES];
	else
		return [NSNumber numberWithBool:NO];
}


@end
