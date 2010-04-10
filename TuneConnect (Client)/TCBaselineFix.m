//
//  TCBaselineFix.m
//  TuneConnect
//
//  Created by Matt Patenaude on 2/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCBaselineFix.h"


@implementation TCBaselineFix

- (id)init
{
	if (self = [super init])
	{
		attributes = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:-30], NSBaselineOffsetAttributeName, nil] retain];
	}
	return self;
}

+ (Class)transformedValueClass
{
	return [NSAttributedString class];
}
+ (BOOL)allowsReverseTransformation
{
	return NO;
}
- (id)transformedValue:(id)value
{
	return [[[NSAttributedString alloc] initWithString:value attributes:attributes] autorelease];
}

@end
